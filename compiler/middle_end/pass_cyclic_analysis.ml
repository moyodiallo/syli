(** Cyclic analysis over Core AST type declarations.

    Builds a graph whose nodes are type definitions, record bodies and variant
    constructors, then classifies every node as:

    - [Cyclic_n_Trackable]: a cyclic component containing at least one mutable
      edge (so a cycle can actually be built at runtime);
    - [Acyclic_n_Trackable] (scannable): an acyclic node that refers, directly
      or indirectly, to a cyclic node;
    - [Acyclic]: everything else.

    Names absent from the analysed set (e.g. a type that was never materialized)
    resolve to [Unknown_cyclic_prop].

    Example. The declarations

        type point   = { x : i64; y : i64 }
        type color   = Red | Green
        type node    = Leaf | Inner of { mutable next : node }
        type wrapper = { w : node }

    become the nodes (one per type definition, plus one per record body and one
    per variant constructor; aliases produce no node, they are resolved). An
    array type also gets its own node, keyed by its materialized name
    ([array:box], [array:i64], [array:array:box]) and pointing at its element's
    node:

        point      point#record
        color      color#0 (Red)     color#1 (Green)
        node       node#0 (Leaf)     node#1 (Inner)
        wrapper    wrapper#record

    with edges (references always point at the referenced type's type node; a
    field marked `mutable` makes its edge mutable):

        point          -> point#record
        color          -> color#0 ; color -> color#1
        node           -> node#0  ; node  -> node#1
        wrapper        -> wrapper#record
        node#1         -> node                    (field [next], MUTABLE)
        wrapper#record -> node                    (field [w], immutable)

    A field [f : array<box>] yields [<owner> -> array:box -> box], where the
    edge to [array:box] takes the field's mutability and the edge
    [array:box -> box] is structural (immutable). Nested arrays chain one node
    per level: [array<array<box>>] gives [array:array:box -> array:box -> box].

    [node] and [node#1] form the only cyclic component and it holds a mutable
    edge, so both are [Cyclic_n_Trackable]. [wrapper] and [wrapper#record] reach
    that component, so both are [Acyclic_n_Trackable] (scannable). All the rest
    ([point], [point#record], [color], [color#0], [color#1], [node#0]) are
    [Acyclic].

    Only the declarations are inspected; expressions and use sites are never
    traversed. The input is expected to be a fully concrete (materialized)
    declaration set: every generic instantiation must already have been
    collected, substituted and inserted by a pre-traversal, so no type variable
    reaches this analysis. *)

open Syli_common
module C = Syli_core.Core_ast
module I = Syli_ir.Cir
module G = Helpers.Cyclic_components.Make (String)

type t = I.cyclic_prop StringMap.t

let type_node (name : string) : string = name
let record_node (name : string) : string = name ^ "#record"

let ctor_node (name : string) (tag : int) : string =
  Printf.sprintf "%s#%d" name tag

(** Node for an array type, keyed like a materialized type ([array:box],
    [array:i64], [array:array:box]). *)
let array_node (elem : C.ty) : string =
  Type_lowering.type_key { C.ty_desc = C.CTy_Array elem }

let lookup (props : t) (node : string) : I.cyclic_prop =
  match StringMap.find_opt node props with
  | Some p -> p
  | None -> I.Unknown_cyclic_prop

let type_prop (props : t) (name : string) : I.cyclic_prop =
  lookup props (type_node name)

let record_prop (props : t) (name : string) : I.cyclic_prop =
  lookup props (record_node name)

let ctor_prop (props : t) (name : string) (tag : int) : I.cyclic_prop =
  lookup props (ctor_node name tag)

let array_prop (props : t) (elem : C.ty) : I.cyclic_prop =
  lookup props (array_node elem)

(** Payload fields of a constructor as (type, mutability) pairs. *)
let ctor_fields (arg : C.constructor_arg option) : (C.ty * C.mut_flag) list =
  match arg with
  | None -> []
  | Some (C.Constr_ty { ty_desc = C.CTy_Tuple tys; _ }) ->
      List.map (fun t -> (t, C.CImmutable)) tys
  | Some (C.Constr_record fields) ->
      List.map (fun (f : C.record_field_ty) -> (f.field_ty, f.field_mut)) fields
  | Some (C.Constr_ty t) -> [ (t, C.CImmutable) ]

type ctx = { graph : G.t; mutable_edges : (string * string) list }
(** State accumulated while walking the declarations. *)

let empty_ctx = { graph = G.empty; mutable_edges = [] }
let add_node n ctx = { ctx with graph = G.add_node n ctx.graph }

let add_edge ~(src : string) ~(target : string) ~(mutable_ : bool) ctx =
  let ctx = add_node src ctx |> add_node target in
  let graph = G.add_edge ~src ~target ctx.graph in
  let mutable_edges =
    if mutable_ then (src, target) :: ctx.mutable_edges else ctx.mutable_edges
  in
  { graph; mutable_edges }

(** Add edges from [src] to every node referenced by [t]. Aliases are resolved
    transparently. Array types get their own node (e.g. [array:box]); the edge
    to the array node inherits [mutable_] from the enclosing field, while the
    array node's own edge to its element is structural (immutable). *)
let rec add_refs (type_defs : C.ty_decl StringMap.t) (visited : StringSet.t)
    ~(src : string) ~(mutable_ : bool) (t : C.ty) (ctx : ctx) : ctx =
  match t.ty_desc with
  | C.CTy_Var _ | C.CTy_Constant _ | C.CTy_Arrow _ -> ctx
  | C.CTy_Tuple ts ->
      List.fold_left
        (fun ctx t -> add_refs type_defs visited ~src ~mutable_ t ctx)
        ctx ts
  | C.CTy_Array elem ->
      let arr = array_node elem in
      let ctx = add_edge ~src ~target:arr ~mutable_ ctx in
      add_refs type_defs visited ~src:arr ~mutable_:false elem ctx
  | C.CTy_Defined { name; args } -> (
      let key = Type_lowering.materialized_name name.name args in
      if StringSet.mem key visited then ctx
      else
        match StringMap.find_opt key type_defs with
        | Some { def = C.CTydef_Alias inner; _ } ->
            add_refs type_defs
              (StringSet.add key visited)
              ~src ~mutable_ inner ctx
        | _ -> add_edge ~src ~target:(type_node key) ~mutable_ ctx)

(** Add the edges of one record body or constructor body. *)
let add_body_edges (type_defs : C.ty_decl StringMap.t) ~(src : string)
    (fields : (C.ty * C.mut_flag) list) (ctx : ctx) : ctx =
  List.fold_left
    (fun ctx (t, mut) ->
      add_refs type_defs StringSet.empty ~src ~mutable_:(mut = C.CMutable) t ctx)
    ctx fields

let add_decl (type_defs : C.ty_decl StringMap.t) (name : string)
    (decl : C.ty_decl) (ctx : ctx) : ctx =
  let tname = type_node name in
  let ctx = add_node tname ctx in
  match decl.def with
  | C.CTydef_Record fields ->
      let rname = record_node name in
      let ctx = add_node rname ctx in
      let ctx = add_edge ~src:tname ~target:rname ~mutable_:false ctx in
      add_body_edges type_defs ~src:rname
        (List.map
           (fun (f : C.record_field_ty) -> (f.field_ty, f.field_mut))
           fields)
        ctx
  | C.CTydef_Variant ctors ->
      List.fold_left
        (fun ctx (c : C.constructor_decl) ->
          let cname = ctor_node name c.tag in
          let ctx = add_node cname ctx in
          let ctx = add_edge ~src:tname ~target:cname ~mutable_:false ctx in
          add_body_edges type_defs ~src:cname (ctor_fields c.arg) ctx)
        ctx ctors
  | C.CTydef_Alias _ -> ctx
  | C.CTydef_Abstract -> ctx

let build_ctx (type_defs : C.ty_decl StringMap.t) : ctx =
  StringMap.fold (add_decl type_defs) type_defs empty_ctx

let classify (ctx : ctx) : t =
  (* A cyclic component is a true cycle iff it contains a mutable edge: inside a
     strongly connected component every edge lies on a cycle. *)
  let cyclic_nodes =
    G.cyclic_components ctx.graph
    |> List.fold_left
         (fun acc comp ->
           let comp_set = StringSet.of_list comp in
           let has_mut =
             List.exists
               (fun (u, v) ->
                 StringSet.mem u comp_set && StringSet.mem v comp_set)
               ctx.mutable_edges
           in
           if has_mut then
             List.fold_left (fun acc n -> StringSet.add n acc) acc comp
           else acc)
         StringSet.empty
  in
  let reachable_from (seeds : StringSet.t) : StringSet.t =
    let rev = G.reverse ctx.graph in
    let visited = ref StringSet.empty in
    let queue = Queue.create () in
    StringSet.iter (fun s -> Queue.push s queue) seeds;
    while not (Queue.is_empty queue) do
      let n = Queue.pop queue in
      if not (StringSet.mem n !visited) then (
        visited := StringSet.add n !visited;
        G.NodeSet.iter
          (fun p -> if not (StringSet.mem p !visited) then Queue.push p queue)
          (G.successors n rev))
    done;
    !visited
  in
  let reaches_cyclic = reachable_from cyclic_nodes in
  let nodes = ref StringSet.empty in
  G.iter_nodes (fun n -> nodes := StringSet.add n !nodes) ctx.graph;
  StringSet.fold
    (fun n acc ->
      let prop =
        if StringSet.mem n cyclic_nodes then I.Cyclic_n_Trackable
        else if StringSet.mem n reaches_cyclic then I.Acyclic_n_Trackable
        else I.Acyclic
      in
      StringMap.add n prop acc)
    !nodes StringMap.empty

(* TODO: parametric types. [analyze] currently assumes an already-concrete
   declaration set. A materialization pre-traversal still has to be added: walk
   the program's types (declaration bodies and expression annotations), collect
   every [CTy_Defined { name; args }] with non-empty [args], substitute [args]
   for the declaration's params to build a concrete [ty_decl] named
   [Type_lowering.materialized_name name args], insert it into the set, and
   iterate to a fixpoint for nested instantiations.

   Example. Given

       type box<a>  = { value : a }
       type holder = { h : box<i64> }

   the pre-traversal sees [box<i64>] in [holder]'s field, substitutes
   [a := i64] into [box]'s body and inserts

       type box:i64 = { value : i64 }

   so [analyze] only ever sees the concrete [box:i64] (here [Acyclic]) and
   [holder] (edge to [box:i64], also [Acyclic]).

   Until then, [args] is always empty (type application is not parseable or
   inferred yet), so only concrete declarations reach this analysis. *)
let analyze (type_defs : C.ty_decl StringMap.t) : t =
  classify (build_ctx type_defs)
