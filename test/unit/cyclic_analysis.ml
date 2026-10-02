(** Unit tests for the cyclic analysis pass and the anonymous-aggregate rule.

    Each program is parsed, typed and lowered to Core; the type-declaration map
    is then fed to [Pass_cyclic_analysis.analyze]. A second section lowers to
    CIR and prints the property carried by every [object_create] destination. *)

module C = Syli_core.Core_ast
module I = Syli_ir.Cir
module CA = Middle_end.Pass_cyclic_analysis
module LCC = Middle_end.Lower_core_to_cir
module PT = Middle_end.Pipeline_types
module SM = Syli_common.StringMap

let pp_prop : I.cyclic_prop -> string = function
  | I.Cyclic_n_Trackable -> "cyclic"
  | I.Acyclic_n_Trackable -> "acyclic_n_trackable"
  | I.Acyclic -> "acyclic"
  | I.Unknown_cyclic_prop -> "unknown_cyclic"

(** Strip the generated module prefix (e.g. [syliCyc_test1234.list] -> [list]).
*)
let unqualify name =
  match String.rindex_opt name '.' with
  | Some i -> String.sub name (i + 1) (String.length name - i - 1)
  | None -> name

(** Short display name for the element types used in the array tests. *)
let rec label_of_ty (t : C.ty) : string =
  match t.ty_desc with
  | C.CTy_Array e -> Printf.sprintf "array<%s>" (label_of_ty e)
  | C.CTy_Defined { name; _ } -> unqualify name.name
  | C.CTy_Constant C.CTy_Int64 -> "i64"
  | _ -> "?"

let lower_source src =
  let f = Filename.temp_file "cyc_test" ".sy" in
  let oc = open_out f in
  output_string oc (String.trim src);
  close_out oc;
  let ast = Syli_parsing.Utils.parse_file f in
  let _, typed = Syli_typing.Infer.infer_program ast in
  Sys.remove f;
  Middle_end.Lower_ast_to_core.lower typed

let type_defs_of (core : C.program_core) : C.ty_decl SM.t =
  List.fold_left
    (fun m (item : C.structure_item) ->
      match item.structure_item_desc with
      | C.CStr_Type td -> SM.add td.name.name td m
      | _ -> m)
    SM.empty core.structure_items

let print_analysis label src =
  let core = lower_source src in
  let props = CA.analyze (type_defs_of core) in
  Printf.printf "--- %s\n" label;
  SM.iter
    (fun name (td : C.ty_decl) ->
      let line =
        ref
          (Printf.sprintf "  %s: %s" (unqualify name)
             (pp_prop (CA.type_prop props name)))
      in
      (match td.def with
      | C.CTydef_Record _ ->
          line :=
            !line
            ^ Printf.sprintf " record=%s" (pp_prop (CA.record_prop props name))
      | C.CTydef_Variant ctors ->
          let cs =
            List.map
              (fun (c : C.constructor_decl) ->
                Printf.sprintf "%d=%s" c.tag
                  (pp_prop (CA.ctor_prop props name c.tag)))
              ctors
          in
          line := !line ^ " ctors=[" ^ String.concat "; " cs ^ "]"
      | _ -> ());
      print_endline !line)
    (type_defs_of core)

(** Every array type syntactically nested in [t], as its element type. *)
let rec array_elems (t : C.ty) : C.ty list =
  match t.ty_desc with
  | C.CTy_Array e -> e :: array_elems e
  | C.CTy_Tuple ts -> List.concat_map array_elems ts
  | _ -> []

let print_arrays label src =
  let core = lower_source src in
  let props = CA.analyze (type_defs_of core) in
  Printf.printf "--- %s\n" label;
  SM.iter
    (fun _ (td : C.ty_decl) ->
      let field_tys =
        match td.def with
        | C.CTydef_Record fs ->
            List.map (fun (f : C.record_field_ty) -> f.field_ty) fs
        | C.CTydef_Variant cs ->
            List.concat_map
              (fun (c : C.constructor_decl) ->
                match c.arg with
                | None -> []
                | Some (C.Constr_ty t) -> [ t ]
                | Some (C.Constr_record fs) ->
                    List.map (fun (f : C.record_field_ty) -> f.field_ty) fs)
              cs
        | _ -> []
      in
      List.iter
        (fun t ->
          List.iter
            (fun elem ->
              Printf.printf "  array<%s>: %s\n" (label_of_ty elem)
                (pp_prop (CA.array_prop props elem)))
            (array_elems t))
        field_tys)
    (type_defs_of core)

let print_objects label src =
  let core = lower_source src in
  let ctx = LCC.lower { PT.program = core } in
  Printf.printf "--- %s\n" label;
  List.iter
    (fun (fn : I.function_cir) ->
      List.iter
        (fun (b : I.block) ->
          List.iter
            (fun (stmt : I.statement) ->
              match stmt.I.node with
              | I.CR_Object_create { dst; _ } -> (
                  match dst.I.ty.I.ir_type with
                  | I.CR_Obj { named; cyclic_prop; _ } ->
                      let shape =
                        match named with
                        | Some n -> unqualify n
                        | None -> "anon"
                      in
                      Printf.printf "  object %s: %s\n" shape
                        (pp_prop cyclic_prop)
                  | _ -> ())
              | _ -> ())
            b.I.statements)
        fn.I.blocks)
    ctx.module_cir.functions

let () =
  print_analysis "immutable list"
    {|
type list = Nil | Cons of (i64, list)
let x = 0
|};
  print_analysis "mutable recursive variant"
    {|
type node = Leaf | Inner of { mutable next: node }
let x = 0
|};
  print_analysis "immutable recursive variant"
    {|
type node = Leaf | Inner of { next: node }
let x = 0
|};
  print_analysis "wrapper points to a cyclic node"
    {|
type node = Leaf | Inner of { mutable next: node }
type wrapper = { w: node }
let x = 0
|};
  print_analysis "constant-only record"
    {|
type point = { x: i64; y: i64 }
let x = 0
|};
  print_objects "anonymous aggregates"
    {|
type point = { x: i64; y: i64 }
type node = Leaf | Inner of { mutable next: node }
let main () =
  let p = (1, 2)
  let n = Inner { next = Leaf }
  let q = (n, n)
  0
|};
  print_arrays "array nodes"
    {|
type box = Leaf | Inner of { mutable next: box }
type t = M of i64 array | T of box array
let x = 0
|};
  print_arrays "nested array nodes"
    {|
type box = Leaf | Inner of { mutable next: box }
type t = N of box array array
let x = 0
|}
