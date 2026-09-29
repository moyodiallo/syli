open Syli_core.Core_ast
open Syli_ir.Cir
module C = Syli_core.Core_ast
module I = Syli_ir.Cir
open Syli_common
module CA = Syli_core.Closure_analysis
module PM = Pattern_matching

exception Lowering_error of string

(* ================================================================== *)
(*  Lowering context                                                  *)
(* ================================================================== *)

type env = I.var StringMap.t

type ctx = {
  locals : I.var list;
  current_stmts : I.statement list;
  blocks : I.block list;
  lifted_fns : I.function_cir list;
  env : env;
  toplevel_functions : int StringMap.t;
  analysis : CA.core_closure_analysis;
  type_defs : C.ty_decl StringMap.t;
  tmp_counter : int ref;
  block_counter : int ref;
  pending_merge_id : int option;
  ffi_external_functions : I.ffi_external_function list;
  primitive_fns : I.function_cir list;
  occ_scrut_var : I.var;
      (** the materialised root of the match currently being lowered; only
          meaningful inside [lower_tree], set by [lower_match] *)
  occ_payloads : C.constructor_arg IntMap.t;
      (** constructor argument per payload occurrence id *)
  occ_materialized : I.var IntMap.t;
      (** occurrence id -> the variable holding its value *)
  occ_types : C.ty IntMap.t;  (** occurrence id -> its core type *)
}

let empty_analysis : CA.core_closure_analysis =
  { CA.closure_infos = Hashtbl.create 0 }

let dummy_scrut_var : I.var =
  {
    I.id = 0;
    I.name = "__no_scrutinee";
    I.ty = { I.id = 0; I.ir_type = I.CR_Void };
  }

let empty_ctx =
  {
    locals = [];
    current_stmts = [];
    blocks = [];
    lifted_fns = [];
    env = StringMap.empty;
    toplevel_functions = StringMap.empty;
    analysis = empty_analysis;
    type_defs = StringMap.empty;
    tmp_counter = ref 0;
    block_counter = ref 0;
    pending_merge_id = None;
    ffi_external_functions = [];
    primitive_fns = [];
    occ_scrut_var = dummy_scrut_var;
    occ_payloads = IntMap.empty;
    occ_materialized = IntMap.empty;
    occ_types = IntMap.empty;
  }

let fresh_id = Syli_ir.Cir.fresh_id

let fresh_var_with_name (ctx : ctx) (name : string) (ty : I.ty) : ctx * I.var =
  let v : I.var = { I.id = fresh_id (); I.name; I.ty } in
  ({ ctx with locals = v :: ctx.locals }, v)

let fresh_var (ctx : ctx) (ty : I.ty) : ctx * I.var =
  let idx = !(ctx.tmp_counter) in
  ctx.tmp_counter := idx + 1;
  let v : I.var =
    { I.id = fresh_id (); I.name = "Sy_cir_var_" ^ string_of_int idx; I.ty }
  in
  ({ ctx with locals = v :: ctx.locals }, v)

let env_add_var ctx (var : var) =
  { ctx with env = StringMap.add var.I.name var ctx.env }

let env_mem_var ctx (id : C.ident) = StringMap.mem id.name ctx.env
let env_find_var_opt ctx (id : C.ident) = StringMap.find_opt id.name ctx.env

let emit (ctx : ctx) (node : I.statement_node) (ty : I.ty) : ctx * I.statement =
  let id = fresh_id () in
  let s = { I.id; node; ty } in
  ({ ctx with current_stmts = s :: ctx.current_stmts }, s)

let finish_block (ctx : ctx) (term_node : I.terminator_node) : ctx =
  let block_id =
    match ctx.pending_merge_id with Some id -> id | None -> fresh_id ()
  in
  let block : I.block =
    {
      I.id = block_id;
      I.label_id = !(ctx.block_counter);
      statements = List.rev ctx.current_stmts;
      terminator = { I.id = fresh_id (); node = term_node };
      pred_blocks = [];
      succ_blocks = [];
    }
  in
  incr ctx.block_counter;
  {
    ctx with
    pending_merge_id = None;
    blocks = block :: ctx.blocks;
    current_stmts = [];
  }

let finish_block_with_id (ctx : ctx) (id : I.id) (term_node : I.terminator_node)
    : ctx =
  let block : I.block =
    {
      I.id;
      I.label_id = !(ctx.block_counter);
      statements = List.rev ctx.current_stmts;
      terminator = { I.id = fresh_id (); node = term_node };
      pred_blocks = [];
      succ_blocks = [];
    }
  in
  incr ctx.block_counter;
  { ctx with blocks = block :: ctx.blocks; current_stmts = [] }

let assign_cast_var new_v src_v to_ty =
  I.CR_Assign
    {
      dst = new_v;
      rvalue =
        {
          I.id = fresh_id ();
          node = I.CR_Cast { src = I.CR_OVar src_v; to_ty };
          ty = to_ty;
        };
    }

(* =================================================== *)
(*  Type / operator helpers                            *)
(* =================================================== *)

let mk_ir_ty = Type_lowering.mk_ir_ty

let rec arg_type_compatible (a : I.ir_type) (b : I.ir_type) : bool =
  match (a, b) with
  | CR_Bool, CR_Bool -> true
  | CR_I64, CR_I64 -> true
  | CR_I32, CR_I32 -> true
  | CR_I16, CR_I16 -> true
  | CR_I8, CR_I8 -> true
  | CR_U64, CR_U64 -> true
  | CR_U32, CR_U32 -> true
  | CR_U16, CR_U16 -> true
  | CR_U8, CR_U8 -> true
  | CR_F32, CR_F32 -> true
  | CR_F64, CR_F64 -> true
  | CR_FnPtr, CR_FnPtr -> true
  | CR_Void, CR_Void -> true
  | CR_GenericTyp { type_var = tv1 }, CR_GenericTyp { type_var = tv2 } ->
      tv1 = tv2
  | CR_Obj a, CR_Obj b ->
      a.named = b.named && obj_kind_compatible a.obj_kind b.obj_kind
  | CR_String, CR_String -> true
  | CR_Obj_Ptr, CR_Obj_Ptr -> true
  | CR_Arrow (args1, ret1), CR_Arrow (args2, ret2) ->
      List.for_all2 arg_ty_compatible args1 args2 && arg_ty_compatible ret1 ret2
  | _, _ -> false

and obj_kind_compatible (a : I.obj_kind) (b : I.obj_kind) : bool =
  match (a, b) with
  | I.CR_Record_kind { fields = fa }, I.CR_Record_kind { fields = fb } ->
      List.length fa = List.length fb
      && List.for_all2
           (fun fa fb ->
             fa.field_idx = fb.field_idx
             && fa.field_mut = fb.field_mut
             && arg_ty_compatible fa.field_ty fb.field_ty)
           fa fb
  | I.CR_Array_kind { element_ty = ea }, I.CR_Array_kind { element_ty = eb } ->
      arg_ty_compatible ea eb
  | I.CR_Variant_kind _, I.CR_Variant_kind _ -> true
  | _, _ -> false

and arg_ty_compatible (a : I.ty) (b : I.ty) : bool =
  arg_type_compatible a.I.ir_type b.I.ir_type

let ir_const_of_core = function
  | CConst_Unit -> I.CR_Null
  | CConst_IntLit s -> I.CR_IntLit s
  | CConst_FloatLit s -> I.CR_FloatLit s
  | CConst_BoolLit s -> I.CR_BoolLit s
  | CConst_StringLit s -> I.CR_StringLit s
  | CConst_CharLit s -> I.CR_CharLit s

let void_ir_ty : I.ty = { I.id = 0; I.ir_type = I.CR_Void }
let void_null = I.CR_OConstant (I.CR_Null, void_ir_ty)

let make_return (return_ty : I.ty) (result : I.operand option) :
    I.terminator_node =
  match (return_ty.I.ir_type, result) with
  | I.CR_Void, _ -> I.CR_Return None
  | _, Some operand -> I.CR_Return (Some operand)
  | _, None -> invalid_arg "non-void return requires an operand"

let arg_ty_of_operand = function
  | I.CR_OConstant (_, ty) -> ty
  | I.CR_OVar v -> v.I.ty

let get_args_ty = Type_lowering.get_args_ty
let get_return_ty = Type_lowering.get_return_ty

let is_unit_cty (t : C.ty) : bool =
  match t.ty_desc with C.CTy_Constant C.CTy_Unit -> true | _ -> false

let rec take n xs =
  if n <= 0 then []
  else match xs with x :: rest -> x :: take (n - 1) rest | [] -> []

let unit_slot_ir_ty () : I.ty = { I.id = fresh_id (); I.ir_type = I.CR_I64 }

(* IR type of one function-parameter slot given its Core type. *)
let slot_ir_ty (type_defs : C.ty_decl StringMap.t) (t : C.ty) : I.ty =
  if is_unit_cty t then unit_slot_ir_ty () else mk_ir_ty type_defs t

(* IR types for a *full* Core parameter list: every parameter — including a
   `unit` — occupies one slot. *)
let full_param_ir_tys (type_defs : C.ty_decl StringMap.t) (ctys : C.ty list) :
    I.ty list =
  List.map (slot_ir_ty type_defs) ctys

(* Indices (into a Core parameter list) of `unit` params. Uniform: these are
   carried as [i64] slots in the IR and dropped only at LLVM emission. *)
let unit_indices_of_ctys (ctys : C.ty list) : int list =
  ctys
  |> List.mapi (fun i t -> (i, t))
  |> List.filter_map (fun (i, t) -> if is_unit_cty t then Some i else None)

let collect_toplevel_functions (prog : C.program_core) : int StringMap.t =
  List.fold_left
    (fun acc (item : C.structure_item) ->
      match item.structure_item_desc with
      | CStr_Let { name; value; _ } -> (
          match value.node with
          | CExp_Lambda lam ->
              StringMap.add name.name (List.length lam.params) acc
          | _ -> acc)
      | CStr_External { fname; ty; external_fn; _ } ->
          StringMap.add fname.name (List.length (get_args_ty ty)) acc
      | _ -> acc)
    StringMap.empty prog.C.structure_items

(* ================================================================== *)
(*  Pattern-matching lowering helpers                                 *)
(* ================================================================== *)

let i64_ir_ty () : I.ty = { I.id = fresh_id (); I.ir_type = I.CR_I64 }
let immediate_tag = 3L

(** Encoding of a constant constructor as an immediate: the tag sits above the
    two ownership bits and the reserved tag [11] marks it. A real object pointer
    is 8-byte aligned and only carries [00]/[01]/[10], so [11] can never be a
    real pointer *)
let constant_ctor_value (tag : int) : int64 =
  Int64.logor (Int64.shift_left (Int64.of_int tag) 2) immediate_tag

let cir_mut_flag = function CMutable -> I.Mutable | CImmutable -> I.Immutable

(** CIR object type of a variant constructor. The payload is flattened into the
    object's fields:
    - tuple payload [C of (t0, t1)]               -> fields [0:t0, 1:t1];
    - inline record payload [C of { a:t0; b:t1 }] -> fields [0:t0, 1:t1];
    - any other payload [C of t]                  -> a single field [0:t].

    For example

        type point = { x : f64; y : f64 }
        type shape =
          | Circle of (f64, f64)
          | Rect of { w : f64; h : f64 }
          | Dot of point

    yields [Circle] and [Rect] with two [f64] fields each, and [Dot] with a
    single field holding a [point] reference. The constructor tag is not a
    field; it lives in the object header ([tag_variant = Some tag]). *)
let variant_constructor_ty (type_defs : C.ty_decl StringMap.t)
    (variant_name : string) (tag : int) (arg : C.constructor_arg) : I.ty =
  let fields =
    match arg with
    | Constr_ty { ty_desc = CTy_Tuple tys; _ } ->
        List.mapi
          (fun i t ->
            {
              I.field_idx = i;
              field_ty = mk_ir_ty type_defs t;
              field_mut = I.Immutable;
            })
          tys
    | Constr_record decl_fields ->
        List.map
          (fun (f : C.record_field_ty) ->
            {
              I.field_idx = f.field_idx;
              field_ty = mk_ir_ty type_defs f.field_ty;
              field_mut = cir_mut_flag f.field_mut;
            })
          decl_fields
    | Constr_ty t ->
        [
          {
            I.field_idx = 0;
            field_ty = mk_ir_ty type_defs t;
            field_mut = I.Immutable;
          };
        ]
  in
  {
    I.id = fresh_id ();
    ir_type =
      I.CR_Obj
        {
          named = Some variant_name;
          obj_kind = I.CR_Variant_kind { constructors = [ { I.tag; fields } ] };
          tag_variant = Some tag;
          cyclic_prop = I.Unknown_cyclic_prop;
        };
  }

(** Turn an operand into a variable, emitting a move when needed. *)
let operand_as_var (ctx : ctx) (op : I.operand) (ty : I.ty) : ctx * I.var =
  match op with
  | I.CR_OVar v -> (ctx, v)
  | _ ->
      let ctx, v = fresh_var ctx ty in
      let rv : I.rvalue =
        { I.id = fresh_id (); node = I.CR_Move { src = op }; ty }
      in
      let ctx, _ = emit ctx (I.CR_Assign { dst = v; rvalue = rv }) ty in
      (ctx, v)

let record_field_ty_of_idx (fields : C.record_field_ty list) (idx : int) : C.ty
    =
  match
    List.find_opt (fun (f : C.record_field_ty) -> f.field_idx = idx) fields
  with
  | Some f -> f.field_ty
  | None ->
      raise
        (Lowering_error (Printf.sprintf "pattern: record has no field %d" idx))

let nth_tuple_ty (tys : C.ty list) (i : int) : C.ty =
  match List.nth_opt tys i with
  | Some t -> t
  | None ->
      raise
        (Lowering_error (Printf.sprintf "pattern: tuple has no element %d" i))

(** Resolve a type alias to its underlying type. *)
let rec resolve_alias (type_defs : C.ty_decl StringMap.t) (t : C.ty) : C.ty =
  match t.ty_desc with
  | CTy_Defined { name; _ } -> (
      match StringMap.find_opt name.name type_defs with
      | Some { def = CTydef_Alias inner; _ } -> resolve_alias type_defs inner
      | _ -> t)
  | _ -> t

(** Constructor payload descriptor attached to an [Occ_Payload] occurrence. *)
let payload_arg_of_occ (ctx : ctx) (occ : PM.occurrence) :
    C.constructor_arg option =
  IntMap.find_opt occ.PM.id ctx.occ_payloads

(** An anonymous product payload (tuple or record) is flattened into the
    constructor block, so its occurrence denotes the block itself. *)
let is_inlined_payload_arg = function
  | C.Constr_record _ | C.Constr_ty { ty_desc = CTy_Tuple _; _ } -> true
  | _ -> false

let is_inlined_payload_occ (ctx : ctx) (occ : PM.occurrence) : bool =
  match payload_arg_of_occ ctx occ with
  | Some arg -> is_inlined_payload_arg arg
  | None -> false

(** Core type of the value denoted by an occurrence, memoised per occurrence id.
*)
let rec occurrence_ty (ctx : ctx) (occ : PM.occurrence) : ctx * C.ty =
  match IntMap.find_opt occ.PM.id ctx.occ_types with
  | Some t -> (ctx, t)
  | None ->
      let ctx, t =
        match occ.PM.desc with
        | PM.Occ_Scrutinee e -> (ctx, e.ty)
        | PM.Occ_Tuple (parent, i) -> (
            let ctx, parent_ty = occurrence_ty ctx parent in
            match (resolve_alias ctx.type_defs parent_ty).ty_desc with
            | CTy_Tuple tys -> (ctx, nth_tuple_ty tys i)
            | _ ->
                raise
                  (Lowering_error "pattern: tuple projection on a non-tuple"))
        | PM.Occ_Payload _ -> (
            match payload_arg_of_occ ctx occ with
            | Some (Constr_ty { ty_desc = CTy_Tuple tys; _ }) ->
                (ctx, { ty_desc = CTy_Tuple tys })
            | Some (Constr_record fields) ->
                ( ctx,
                  {
                    ty_desc =
                      CTy_Tuple
                        (List.map
                           (fun (f : C.record_field_ty) -> f.field_ty)
                           fields);
                  } )
            | Some (Constr_ty t) -> (ctx, t)
            | None ->
                raise (Lowering_error "pattern: untyped payload occurrence"))
        | PM.Occ_Field (({ PM.desc = PM.Occ_Payload _; _ } as parent), idx) -> (
            match payload_arg_of_occ ctx parent with
            | Some (Constr_record fields) ->
                (ctx, record_field_ty_of_idx fields idx)
            | Some (Constr_ty t) -> (
                match (resolve_alias ctx.type_defs t).ty_desc with
                | CTy_Defined { name; _ } -> (
                    match StringMap.find_opt name.name ctx.type_defs with
                    | Some { def = CTydef_Record fields; _ } ->
                        (ctx, record_field_ty_of_idx fields idx)
                    | _ ->
                        raise
                          (Lowering_error
                             "pattern: field access on a non-record type"))
                | _ ->
                    raise
                      (Lowering_error
                         "pattern: field access on a non-record type"))
            | None ->
                raise (Lowering_error "pattern: untyped payload occurrence"))
        | PM.Occ_Field (parent, idx) -> (
            let ctx, parent_ty = occurrence_ty ctx parent in
            match (resolve_alias ctx.type_defs parent_ty).ty_desc with
            | CTy_Defined { name; _ } -> (
                match StringMap.find_opt name.name ctx.type_defs with
                | Some { def = CTydef_Record fields; _ } ->
                    (ctx, record_field_ty_of_idx fields idx)
                | _ ->
                    raise
                      (Lowering_error
                         "pattern: field access on a non-record type"))
            | CTy_Tuple tys -> (ctx, nth_tuple_ty tys idx)
            | _ ->
                raise
                  (Lowering_error "pattern: field access on a non-record type"))
      in
      let ctx = { ctx with occ_types = IntMap.add occ.PM.id t ctx.occ_types } in
      (ctx, t)

let emit_object_get (ctx : ctx) (obj : I.var) (idx : int) (value_ty : I.ty) :
    ctx * I.var =
  let ctx, dst = fresh_var ctx value_ty in
  let idx_op : I.operand =
    I.CR_OConstant (I.CR_IntLit (string_of_int idx), i64_ir_ty ())
  in
  let rv : I.rvalue =
    {
      I.id = fresh_id ();
      node =
        I.CR_Object_get { obj = I.CR_OVar obj; field_idx = idx_op; value_ty };
      ty = value_ty;
    }
  in
  let ctx, _ = emit ctx (I.CR_Assign { dst; rvalue = rv }) value_ty in
  (ctx, dst)

(** Materialise an occurrence into a variable, memoised per occurrence id.
    [Occ_Scrutinee] reuses the scrutinee variable; projections emit an object
    read. *)
let rec materialize_occ (ctx : ctx) (occ : PM.occurrence) : ctx * I.var =
  match IntMap.find_opt occ.PM.id ctx.occ_materialized with
  | Some v -> (ctx, v)
  | None ->
      let ctx, v =
        match occ.PM.desc with
        | PM.Occ_Scrutinee _ -> (ctx, ctx.occ_scrut_var)
        | PM.Occ_Payload parent ->
            if is_inlined_payload_occ ctx occ then
              (* Flattened payload: the occurrence denotes the constructor
                 block. *)
              materialize_occ ctx parent
            else
              let ctx, parent_var = materialize_occ ctx parent in
              let ctx, occ_ty = occurrence_ty ctx occ in
              let value_ty = mk_ir_ty ctx.type_defs occ_ty in
              emit_object_get ctx parent_var 0 value_ty
        | PM.Occ_Field (parent, idx) | PM.Occ_Tuple (parent, idx) ->
            let ctx, parent_var = materialize_occ ctx parent in
            let ctx, occ_ty = occurrence_ty ctx occ in
            let value_ty = mk_ir_ty ctx.type_defs occ_ty in
            emit_object_get ctx parent_var idx value_ty
      in
      let ctx =
        {
          ctx with
          occ_materialized = IntMap.add occ.PM.id v ctx.occ_materialized;
        }
      in
      (ctx, v)

(** Bind each pattern variable to the occurrence it matched. Unit-typed binders
    are dropped: they carry no runtime value and the body never reads them. *)
let bind_occs (ctx : ctx) (binds : PM.action_binds) : ctx =
  List.fold_left
    (fun ctx ((id : C.ident), occ) ->
      let ctx, occ_ty = occurrence_ty ctx occ in
      if is_unit_cty occ_ty then ctx
      else
        let ctx, v = materialize_occ ctx occ in
        { ctx with env = StringMap.add id.name v ctx.env })
    ctx binds

(** Payload argument of the constructor with [tag] in the variant type of [occ],
    if the constructor carries one. *)
let constructor_arg_of_occ (ctx : ctx) (occ : PM.occurrence) (tag : int) :
    ctx * C.constructor_arg option =
  let ctx, occ_ty = occurrence_ty ctx occ in
  match occ_ty.ty_desc with
  | CTy_Defined { name; _ } -> (
      match StringMap.find_opt name.name ctx.type_defs with
      | Some { def = CTydef_Variant ctors; _ } -> (
          match
            List.find_opt (fun (c : C.constructor_decl) -> c.tag = tag) ctors
          with
          | Some c -> (ctx, c.arg)
          | None ->
              raise
                (Lowering_error
                   (Printf.sprintf "pattern: no constructor with tag %d" tag)))
      | _ -> raise (Lowering_error "pattern: constructor test on a non-variant")
      )
  | _ -> raise (Lowering_error "pattern: constructor test on a non-variant")

(* ================================================================== *)
(*  Expression lowering                                               *)
(* ================================================================== *)

let rec lower_expr (ctx : ctx) (e : C.expr) : ctx * I.operand =
  let out_ty = mk_ir_ty ctx.type_defs e.ty in
  match e.node with
  | CExp_Constant c -> (ctx, I.CR_OConstant (ir_const_of_core c, out_ty))
  | CExp_Ident id -> (
      match StringMap.find_opt id.name ctx.env with
      | Some v when StringMap.mem id.name ctx.toplevel_functions ->
          let ctx, closure_var = fresh_var ctx out_ty in
          let ctx, _ =
            emit ctx
              (I.CR_Make_closure
                 {
                   dst = closure_var;
                   fn = id.name;
                   free_vars = [];
                   captured_args = [];
                 })
              out_ty
          in
          (ctx, I.CR_OVar closure_var)
      | Some v -> (ctx, I.CR_OVar v)
      | None ->
          raise
            (Lowering_error
               (Printf.sprintf
                  "Unbound identifier during Core->SIR lowering: %s" id.name)))
  | CExp_Apply { closure_fun; args } -> (
      let callee_arg_ctys = List.map (fun (a : C.expr) -> a.ty) args in
      match closure_fun.node with
      | CExp_Ident id -> (
          match StringMap.find_opt id.name ctx.toplevel_functions with
          | Some arity when List.length args = arity ->
              (* Known function, fully applied -> direct call. Uniform slots;
                 `unit` slots are dropped only at LLVM emission. *)
              let slot_tys = full_param_ir_tys ctx.type_defs callee_arg_ctys in
              let ctx, concrete_arg_ops =
                lower_args_to_slots ctx args slot_tys
              in
              let ctx, call_dst, result =
                let ctx, dst = fresh_var ctx out_ty in
                (ctx, dst, I.CR_OVar dst)
              in
              let ctx, _ =
                emit ctx
                  (I.CR_Call
                     {
                       dst = call_dst;
                       target = I.Direct id.name;
                       args = concrete_arg_ops;
                     })
                  out_ty
              in
              (ctx, result)
          | Some _ ->
              (* Known function, partially applied -> capture the represented
                 prefix as a closure *)
              let slot_tys =
                List.map (slot_ir_ty ctx.type_defs) callee_arg_ctys
              in
              let ctx, concrete_arg_ops =
                lower_args_to_slots ctx args slot_tys
              in
              let ctx, fn_var = fresh_var ctx out_ty in
              let ctx, _ =
                emit ctx
                  (I.CR_Make_closure
                     {
                       dst = fn_var;
                       fn = id.name;
                       free_vars =
                         []
                         (* the toplevel functions does not capture free vars
                          only refer to globals *);
                       captured_args = concrete_arg_ops;
                     })
                  out_ty
              in
              (ctx, I.CR_OVar fn_var)
          | None ->
              let ctx, closure = lower_expr ctx closure_fun in
              let closure_var : I.var =
                match closure with
                | I.CR_OVar v -> v
                | _ ->
                    failwith
                      "lowering: expected operand variable for closure apply"
              in
              lower_closure_apply ctx closure_var closure_fun.ty args out_ty)
      | _ ->
          let ctx, closure = lower_expr ctx closure_fun in
          let closure_var : I.var =
            match closure with
            | I.CR_OVar v -> v
            | _ ->
                failwith "lowering: expected operand variable for closure apply"
          in
          lower_closure_apply ctx closure_var closure_fun.ty args out_ty)
  | CExp_Let { rec_flag; name; value } -> (
      let lambda_name = name.name in
      match value.node with
      | CExp_Lambda lam ->
          (* Lift the function and the create closure *)
          let ctx, fn_sir =
            lower_lambda_function ctx lambda_name lam value.ty value.id
          in
          let fn_sir = { fn_sir with I.visibility = I.CR_Private } in
          let ctx = { ctx with lifted_fns = fn_sir :: ctx.lifted_fns } in
          (* Since the type of the let-expession is unit,
            so the type of the bound name is the type of the value *)
          let fn_ty = mk_ir_ty ctx.type_defs value.ty in
          let ctx, fn_var = fresh_var_with_name ctx lambda_name fn_ty in
          let free_var_idents =
            match Hashtbl.find_opt ctx.analysis.CA.closure_infos value.id with
            | Some info -> CA.VarIdSet.elements info.free_vars
            | None -> []
          in
          let free_vars =
            List.filter_map
              (fun (id : C.ident) -> StringMap.find_opt id.name ctx.env)
              free_var_idents
          in
          let make_closure =
            I.CR_Make_closure
              { dst = fn_var; fn = lambda_name; free_vars; captured_args = [] }
          in
          let ctx, _ = emit ctx make_closure fn_ty in
          let ctx = { ctx with env = StringMap.add name.name fn_var ctx.env } in
          (ctx, I.CR_OVar fn_var)
      | _ -> (
          (* Evaluate the value and always bind the let-name in the environment. *)
          let ctx, result = lower_expr ctx value in
          (*  Since the type of the let-expession is unit,
              so the type of the bound name is the type of the value *)
          let value_ty = mk_ir_ty ctx.type_defs value.ty in
          match result with
          | I.CR_OVar v ->
              let ctx = { ctx with env = StringMap.add name.name v ctx.env } in
              (ctx, I.CR_OVar v)
          | I.CR_OConstant _ ->
              let ctx, v = fresh_var_with_name ctx name.name value_ty in
              let rv : I.rvalue =
                {
                  I.id = v.I.id;
                  node = I.CR_Cast { src = result; to_ty = value_ty };
                  ty = value_ty;
                }
              in
              let ctx, _ =
                emit ctx (I.CR_Assign { dst = v; rvalue = rv }) value_ty
              in
              let ctx = { ctx with env = StringMap.add name.name v ctx.env } in
              (ctx, I.CR_OVar v)))
  | CExp_Seq xs ->
      List.fold_left (fun (ctx, _) x -> lower_expr ctx x) (ctx, void_null) xs
  | CExp_If { condition; then_branch; else_branch } ->
      let ctx, cond_op = lower_expr ctx condition in
      let ctx, cond_var =
        match cond_op with
        | I.CR_OVar v -> (ctx, v)
        | _ ->
            let ctx, v = fresh_var ctx (mk_ir_ty ctx.type_defs condition.ty) in
            let rv : I.rvalue =
              {
                I.id = v.I.id;
                node = I.CR_Cast { src = cond_op; to_ty = v.I.ty };
                ty = v.I.ty;
              }
            in
            let ctx, _ =
              emit ctx (I.CR_Assign { dst = v; rvalue = rv }) v.I.ty
            in
            (ctx, v)
      in
      let ctx, result_var = fresh_var ctx out_ty in
      let then_id = fresh_id () in
      let else_id = fresh_id () in
      let merge_id = fresh_id () in
      let ctx =
        finish_block ctx
          (I.CR_CondBr
             { cond = cond_var; then_block = then_id; else_block = else_id })
      in
      let ctx = { ctx with pending_merge_id = Some then_id } in
      let ctx, then_result = lower_expr ctx then_branch in
      let then_rv : I.rvalue =
        {
          I.id = fresh_id ();
          node = I.CR_Move { src = then_result };
          ty = result_var.I.ty;
        }
      in
      let ctx, _ =
        if then_rv.ty.I.ir_type = I.CR_Void then emit ctx I.CR_Nop then_rv.ty
        else
          emit ctx
            (I.CR_Assign { dst = result_var; rvalue = then_rv })
            result_var.I.ty
      in
      let ctx = finish_block ctx (I.CR_Goto merge_id) in
      let ctx, _ =
        let ctx = { ctx with pending_merge_id = Some else_id } in
        match else_branch with
        | Some e ->
            let ctx, r = lower_expr ctx e in
            let else_rv : I.rvalue =
              {
                I.id = fresh_id ();
                node = I.CR_Move { src = r };
                ty = result_var.I.ty;
              }
            in
            let ctx, _ =
              if else_rv.ty.I.ir_type = I.CR_Void then
                emit ctx I.CR_Nop else_rv.ty
              else
                emit ctx
                  (I.CR_Assign { dst = result_var; rvalue = else_rv })
                  result_var.I.ty
            in
            let ctx = finish_block ctx (I.CR_Goto merge_id) in
            (ctx, r)
        | None -> (ctx, I.CR_OConstant (I.CR_Null, void_ir_ty))
      in
      let ctx = { ctx with pending_merge_id = Some merge_id } in
      (ctx, I.CR_OVar result_var)
  | CExp_Lambda lam ->
      let lambda_name = Printf.sprintf "__sy_cir_lambda_%d" (fresh_id ()) in
      let ctx, fn_sir = lower_lambda_function ctx lambda_name lam e.ty e.id in
      let ctx = { ctx with lifted_fns = fn_sir :: ctx.lifted_fns } in
      let ctx, fn_var = fresh_var_with_name ctx lambda_name out_ty in
      let free_var_idents =
        match Hashtbl.find_opt ctx.analysis.CA.closure_infos e.id with
        | Some info -> CA.VarIdSet.elements info.free_vars
        | None -> []
      in
      let free_vars =
        List.filter_map
          (fun (id : C.ident) -> StringMap.find_opt id.name ctx.env)
          free_var_idents
      in
      let make_closure =
        I.CR_Make_closure
          { dst = fn_var; fn = lambda_name; free_vars; captured_args = [] }
      in
      let ctx, _ = emit ctx make_closure out_ty in
      (ctx, I.CR_OVar fn_var)
  | CExp_Record fields ->
      let field_count = List.length fields in
      let ptr_ty = mk_ir_ty ctx.type_defs e.ty in
      let ctx, obj_var = fresh_var ctx ptr_ty in
      let size_op : I.operand =
        I.CR_OConstant
          ( I.CR_IntLit (string_of_int field_count),
            { I.id = 0; I.ir_type = I.CR_I64 } )
      in
      let ctx, _ =
        emit ctx (I.CR_Object_create { dst = obj_var; size = size_op }) ptr_ty
      in
      let ctx =
        List.fold_left
          (fun ctx (f : C.record_field) ->
            let ctx, fval = lower_expr ctx f.field_value in
            let field_ty = mk_ir_ty ctx.type_defs f.field_ty in
            let idx_op : I.operand =
              I.CR_OConstant
                ( I.CR_IntLit (string_of_int f.field_idx),
                  { I.id = 0; I.ir_type = I.CR_I64 } )
            in
            let ctx, _ =
              emit ctx
                (I.CR_Object_set
                   {
                     obj = obj_var;
                     field_idx = idx_op;
                     value = fval;
                     value_ty = field_ty;
                   })
                field_ty
            in
            ctx)
          ctx fields
      in
      (ctx, I.CR_OVar obj_var)
  | CExp_Field { record; field_idx } ->
      let ctx, obj_op = lower_expr ctx record in
      let idx_op : I.operand =
        I.CR_OConstant
          ( I.CR_IntLit (string_of_int field_idx),
            { I.id = 0; I.ir_type = I.CR_I64 } )
      in
      let ctx, dst = fresh_var ctx out_ty in
      let rv : I.rvalue =
        {
          I.id = dst.I.id;
          node =
            I.CR_Object_get
              { obj = obj_op; field_idx = idx_op; value_ty = out_ty };
          ty = out_ty;
        }
      in
      let ctx, _ = emit ctx (I.CR_Assign { dst; rvalue = rv }) out_ty in
      (ctx, I.CR_OVar dst)
  | CExp_FieldSet { record; field_idx; value } ->
      let ctx, obj_op = lower_expr ctx record in
      let obj_var : I.var =
        match obj_op with
        | I.CR_OVar v -> v
        | _ -> raise (Lowering_error "FieldSet target must be a variable")
      in
      let ctx, val_op = lower_expr ctx value in
      let val_ty = mk_ir_ty ctx.type_defs value.ty in
      let idx_op : I.operand =
        I.CR_OConstant
          ( I.CR_IntLit (string_of_int field_idx),
            { I.id = 0; I.ir_type = I.CR_I64 } )
      in
      let ctx, _ =
        emit ctx
          (I.CR_Object_set
             {
               obj = obj_var;
               field_idx = idx_op;
               value = val_op;
               value_ty = val_ty;
             })
          val_ty
      in
      (ctx, void_null)
  | CExp_Match { expr = scrutinee; cases } ->
      lower_match ctx scrutinee cases out_ty
  | CExp_Tuple elements ->
      let count = List.length elements in
      let obj_ty = mk_ir_ty ctx.type_defs e.ty in
      let ctx, obj_var = fresh_var ctx obj_ty in
      let size_op : I.operand =
        I.CR_OConstant (I.CR_IntLit (string_of_int count), i64_ir_ty ())
      in
      let ctx, _ =
        emit ctx (I.CR_Object_create { dst = obj_var; size = size_op }) obj_ty
      in
      let ctx =
        List.fold_left
          (fun (ctx, i) (elem : C.expr) ->
            let ctx, v = lower_expr ctx elem in
            let vty = mk_ir_ty ctx.type_defs elem.ty in
            let idx_op : I.operand =
              I.CR_OConstant (I.CR_IntLit (string_of_int i), i64_ir_ty ())
            in
            let ctx, _ =
              emit ctx
                (I.CR_Object_set
                   {
                     obj = obj_var;
                     field_idx = idx_op;
                     value = v;
                     value_ty = vty;
                   })
                vty
            in
            (ctx, i + 1))
          (ctx, 0) elements
        |> fst
      in
      (ctx, I.CR_OVar obj_var)
  | CExp_VariantConstructor { tag; arg } ->
      lower_variant_constructor ctx e tag arg out_ty
  | CExp_Array _ | CExp_Loop _ | CExp_Break _ | CExp_Continue | CExp_Return _ ->
      raise (Lowering_error "core form not lowered to SIR yet")

and lower_match (ctx : ctx) (scrutinee : C.expr) (cases : C.pattern_case list)
    (out_ty : I.ty) : ctx * I.operand =
  let ctx, scrut_op = lower_expr ctx scrutinee in
  let ctx, scrut_var =
    match scrut_op with
    | I.CR_OVar v -> (ctx, v)
    | I.CR_OConstant _ ->
        let ty = mk_ir_ty ctx.type_defs scrutinee.ty in
        let ctx, v = fresh_var ctx ty in
        if ty.I.ir_type = I.CR_Void then (ctx, v)
        else
          let rv : I.rvalue =
            { I.id = fresh_id (); node = I.CR_Move { src = scrut_op }; ty }
          in
          let ctx, _ = emit ctx (I.CR_Assign { dst = v; rvalue = rv }) ty in
          (ctx, v)
  in
  let saved_occ_scrut_var = ctx.occ_scrut_var in
  let ctx = { ctx with occ_scrut_var = scrut_var } in
  let tree = PM.compile_match ~scrutinee ~cases in
  let ctx, result_var = fresh_var ctx out_ty in
  let merge_id = fresh_id () in
  let bool_ir_ty () : I.ty = { I.id = fresh_id (); I.ir_type = I.CR_Bool } in
  let assign_result (ctx : ctx) (op : I.operand) : ctx =
    if out_ty.I.ir_type = I.CR_Void then ctx
    else
      let rv : I.rvalue =
        { I.id = fresh_id (); node = I.CR_Move { src = op }; ty = out_ty }
      in
      let ctx, _ =
        emit ctx (I.CR_Assign { dst = result_var; rvalue = rv }) out_ty
      in
      ctx
  in
  let emit_equality (ctx : ctx) (sv : I.var) (cst : I.constant) (cst_ty : I.ty)
      : ctx * I.var =
    let bty = bool_ir_ty () in
    let ctx, dst = fresh_var ctx bty in
    let rv : I.rvalue =
      {
        I.id = fresh_id ();
        node =
          I.CR_BinOp
            {
              op = I.CR_Eq;
              lhs = I.CR_OVar sv;
              rhs = I.CR_OConstant (cst, cst_ty);
            };
        ty = bty;
      }
    in
    let ctx, _ = emit ctx (I.CR_Assign { dst; rvalue = rv }) bty in
    (ctx, dst)
  in
  let rec lower_tree (ctx : ctx) (tree : PM.decision_tree) : ctx =
    match tree with
    | PM.DFail -> finish_block ctx I.CR_MatchFailure
    | PM.DLeaf { binds; body } ->
        let ctx = bind_occs ctx binds in
        let ctx, body_op = lower_expr ctx body in
        let ctx = assign_result ctx body_op in
        finish_block ctx (I.CR_Goto merge_id)
    | PM.DGuard { binds; condition; on_pass; on_fail } ->
        let saved_env = ctx.env in
        let ctx = bind_occs ctx binds in
        let ctx, cond_op = lower_expr ctx condition in
        let cond_ty = mk_ir_ty ctx.type_defs condition.ty in
        let ctx, cond_var =
          match cond_op with
          | I.CR_OVar v -> (ctx, v)
          | I.CR_OConstant _ ->
              let ctx, v = fresh_var ctx cond_ty in
              let rv : I.rvalue =
                {
                  I.id = fresh_id ();
                  node = I.CR_Move { src = cond_op };
                  ty = cond_ty;
                }
              in
              let ctx, _ =
                emit ctx (I.CR_Assign { dst = v; rvalue = rv }) cond_ty
              in
              (ctx, v)
        in
        let pass_id = fresh_id () in
        let fail_id = fresh_id () in
        let ctx =
          finish_block ctx
            (I.CR_CondBr
               { cond = cond_var; then_block = pass_id; else_block = fail_id })
        in
        let ctx = { ctx with pending_merge_id = Some pass_id } in
        let ctx = lower_tree ctx on_pass in
        let ctx =
          { ctx with pending_merge_id = Some fail_id; env = saved_env }
        in
        lower_tree ctx on_fail
    | PM.DSwitch { scrutinee = occ; cases; default } ->
        lower_switch ctx occ cases default
  and lower_switch (ctx : ctx) (occ : PM.occurrence)
      (cases : (PM.pattern_test * PM.decision_tree) list)
      (default : PM.decision_tree) : ctx =
    let ctx, sv = materialize_occ ctx occ in
    let ctx, occ_ty = occurrence_ty ctx occ in
    let occ_ty = mk_ir_ty ctx.type_defs occ_ty in
    let is_constant = function PM.Test_Constant _, _ -> true | _ -> false in
    let constant_cases, ctor_cases = List.partition is_constant cases in
    (* Literal column: a cond-br chain on the value. Since switch 
      check only integer and Literal type could vary so switch is not used.*)
    let lower_literal_chain (ctx : ctx) =
      let rec chain (ctx : ctx) = function
        | [] -> lower_tree ctx default
        | (test, subtree) :: rest ->
            let cst =
              match test with
              | PM.Test_Constant c -> ir_const_of_core c
              | PM.Test_Constructor _ ->
                  raise (Lowering_error "pattern: unsupported literal case")
            in
            let ctx, cond_var = emit_equality ctx sv cst occ_ty in
            let case_id = fresh_id () in
            let next_id = fresh_id () in
            let ctx =
              finish_block ctx
                (I.CR_CondBr
                   {
                     cond = cond_var;
                     then_block = case_id;
                     else_block = next_id;
                   })
            in
            let ctx = { ctx with pending_merge_id = Some case_id } in
            let ctx = lower_tree ctx subtree in
            let ctx = { ctx with pending_merge_id = Some next_id } in
            chain ctx rest
      in
      chain ctx constant_cases
    in
    (* Constructor column. An all-constant variant is a plain integer (the
       tag). A mixed variant is an object: constant constructors are tag-11
       immediates and payload constructors carry their tag in the object header,
       so [get_object_tag] yields the plain tag in every case. Either way a
       single switch on the plain tag discriminates the constructors.

       For [type color = Red | Green | Blue] (plain integer) the switch reads
       the scrutinee directly:

         switch %c:i64 [2: bb1, 1: bb2, 0: bb3 default: bb4]

       For [type shape = Circle of i64 | Square of i64] (object) the tag is
       loaded first:

         %Sy_cir_var_1:i64 = get_tag(%s:obj_ptr)
         switch %Sy_cir_var_1:i64 [1: bb1, 0: bb2 default: bb3]

       A mixed variant such as [type option = None | Some of i64] follows the
       object shape: [get_tag] normalizes the tag-11 [None] immediate, so a
       single switch covers both [None] and [Some]. *)
    let lower_constructor_switch (ctx : ctx) =
      let ctx, tag_var =
        if occ_ty.I.ir_type = I.CR_I64 then (ctx, sv)
        else
          let tag_ty = i64_ir_ty () in
          let ctx, tag_var = fresh_var ctx tag_ty in
          let ctx, _ =
            let rv : I.rvalue =
              {
                I.id = fresh_id ();
                node = I.CR_Object_get_tag { obj = I.CR_OVar sv };
                ty = tag_ty;
              }
            in
            emit ctx (I.CR_Assign { dst = tag_var; rvalue = rv }) tag_ty
          in
          (ctx, tag_var)
      in
      let case_blocks = List.map (fun _ -> fresh_id ()) ctor_cases in
      let default_id = fresh_id () in
      let switch_cases =
        List.map2
          (fun (test, _) block ->
            match test with
            | PM.Test_Constructor { tag; _ } ->
                { I.value = tag; I.target_block = block }
            | PM.Test_Constant _ ->
                raise (Lowering_error "pattern: unsupported constructor case"))
          ctor_cases case_blocks
      in
      let ctx =
        finish_block ctx
          (I.CR_Switch
             {
               scrutinee = tag_var;
               cases = switch_cases;
               default_block = Some default_id;
             })
      in
      let ctx =
        List.fold_left2
          (fun ctx (test, subtree) block ->
            let ctx =
              match test with
              | PM.Test_Constructor
                  { tag; payload = PM.Payload_One; payload_occ = Some pocc }
                -> (
                  let ctx, arg = constructor_arg_of_occ ctx occ tag in
                  match arg with
                  | Some arg ->
                      {
                        ctx with
                        occ_payloads =
                          IntMap.add pocc.PM.id arg ctx.occ_payloads;
                      }
                  | None -> ctx)
              | PM.Test_Constant _ | PM.Test_Constructor _ -> ctx
            in
            let ctx = { ctx with pending_merge_id = Some block } in
            lower_tree ctx subtree)
          ctx ctor_cases case_blocks
      in
      let ctx = { ctx with pending_merge_id = Some default_id } in
      lower_tree ctx default
    in
    match (constant_cases, ctor_cases) with
    | _, [] -> lower_literal_chain ctx
    | [], _ -> lower_constructor_switch ctx
    | _ ->
        raise
          (Lowering_error "pattern: mixed literal and constructor switch cases")
  in
  let ctx = lower_tree ctx tree in
  let ctx =
    {
      ctx with
      pending_merge_id = Some merge_id;
      occ_scrut_var = saved_occ_scrut_var;
    }
  in
  (ctx, I.CR_OVar result_var)

and lower_variant_constructor (ctx : ctx) (e : C.expr) (tag : int)
    (arg : C.expr option) (out_ty : I.ty) : ctx * I.operand =
  match e.ty.ty_desc with
  | CTy_Arrow _ ->
      raise
        (Lowering_error
           "variant constructor used as a function is not lowered yet")
  | CTy_Defined { name; _ } -> (
      match StringMap.find_opt name.name ctx.type_defs with
      | Some { def = CTydef_Variant ctors; _ } -> (
          match
            List.find_opt (fun (c : C.constructor_decl) -> c.tag = tag) ctors
          with
          | None ->
              raise
                (Lowering_error
                   (Printf.sprintf "variant: no constructor with tag %d" tag))
          | Some ctor -> (
              match ctor.arg with
              | None -> (
                  (* A constant constructor is the plain tag for an
                     all-constant variant, or a tag-11 immediate for a mixed
                     variant (the tag sits above the two ownership bits and the
                     reserved [11] tag marks it, never a real pointer). *)
                  match out_ty.I.ir_type with
                  | I.CR_I64 ->
                      ( ctx,
                        I.CR_OConstant (I.CR_IntLit (string_of_int tag), out_ty)
                      )
                  | I.CR_Obj { obj_kind = I.CR_Variant_kind _; _ } ->
                      let enc = Int64.to_int (constant_ctor_value tag) in
                      let ctx, v = fresh_var ctx out_ty in
                      let rv : I.rvalue =
                        {
                          I.id = fresh_id ();
                          node =
                            I.CR_Cast
                              {
                                src =
                                  I.CR_OConstant
                                    ( I.CR_IntLit (string_of_int enc),
                                      i64_ir_ty () );
                                to_ty = out_ty;
                              };
                          ty = out_ty;
                        }
                      in
                      let ctx, _ =
                        emit ctx (I.CR_Assign { dst = v; rvalue = rv }) out_ty
                      in
                      (ctx, I.CR_OVar v)
                  | _ ->
                      raise
                        (Lowering_error
                           "variant: constant constructor with unexpected type")
                  )
              | Some ctor_arg -> (
                  match arg with
                  | Some a -> lower_variant_payload ctx name.name tag ctor_arg a
                  | None ->
                      raise
                        (Lowering_error
                           "variant constructor used as a function is not \
                            lowered yet"))))
      | _ -> raise (Lowering_error "variant constructor: not a variant type"))
  | _ -> raise (Lowering_error "variant constructor: unexpected type")

and lower_variant_payload (ctx : ctx) (variant_name : string) (tag : int)
    (ctor_arg : C.constructor_arg) (arg : C.expr) : ctx * I.operand =
  let i64_const n : I.operand =
    I.CR_OConstant (I.CR_IntLit (string_of_int n), i64_ir_ty ())
  in
  let obj_ty = variant_constructor_ty ctx.type_defs variant_name tag ctor_arg in
  let field_count =
    match obj_ty.I.ir_type with
    | I.CR_Obj { obj_kind = I.CR_Variant_kind { constructors = [ c ] }; _ } ->
        List.length c.I.fields
    | _ ->
        raise
          (Lowering_error "variant: constructor object is not a variant kind")
  in
  let ctx, obj_var = fresh_var ctx obj_ty in
  let ctx, _ =
    emit ctx
      (I.CR_Object_create { dst = obj_var; size = i64_const field_count })
      obj_ty
  in
  let set_field (ctx : ctx) (idx : int) (v : I.operand) (vty : I.ty) : ctx =
    let ctx, _ =
      emit ctx
        (I.CR_Object_set
           {
             obj = obj_var;
             field_idx = i64_const idx;
             value = v;
             value_ty = vty;
           })
        vty
    in
    ctx
  in
  let ctx =
    match ctor_arg with
    | Constr_ty { ty_desc = CTy_Tuple tys; _ } -> (
        match arg.node with
        | CExp_Tuple elements ->
            (* Anonymous tuple literal: flatten its elements straight into the
                 block (see [P (1, 2)] below), without materialising an
                 intermediate tuple. *)
            List.fold_left2
              (fun (ctx : ctx) (i, elem) t ->
                let ctx, v = lower_expr ctx elem in
                set_field ctx i v (mk_ir_ty ctx.type_defs t))
              ctx
              (List.mapi (fun i elem -> (i, elem)) elements)
              tys
        | _ ->
            (* A tuple value: project each element into the block. Reached
                 when the payload argument is a tuple-typed expression that is
                 not a tuple literal, e.g. a variable/parameter [P v], a call
                 [P (make_pair x y)], a projection [P r.pair], or an [if]/[match]
                 yielding a tuple.

                 For example, given [type t = P of (i64, i64)]:

                     let mk (v : (i64, i64)) = P v   (* [v] is projected *)
                     let lit = P (1, 2)              (* literal, flattened directly *)

                 The tuple already exists, so each field is read with [obj_get]
                 and copied into the constructor block. *)
            let src_ty = mk_ir_ty ctx.type_defs arg.ty in
            let ctx, src = lower_expr ctx arg in
            let ctx, src_var = operand_as_var ctx src src_ty in
            let ctx, _ =
              List.fold_left
                (fun ((ctx : ctx), i) t ->
                  let fty = mk_ir_ty ctx.type_defs t in
                  let ctx, dst = fresh_var ctx fty in
                  let rv : I.rvalue =
                    {
                      I.id = fresh_id ();
                      node =
                        I.CR_Object_get
                          {
                            obj = I.CR_OVar src_var;
                            field_idx = i64_const i;
                            value_ty = fty;
                          };
                      ty = fty;
                    }
                  in
                  let ctx, _ =
                    emit ctx (I.CR_Assign { dst; rvalue = rv }) fty
                  in
                  (set_field ctx i (I.CR_OVar dst) fty, i + 1))
                (ctx, 0) tys
            in
            ctx)
    | Constr_record _ -> (
        match arg.node with
        | CExp_Record fields ->
            List.fold_left
              (fun ctx (f : C.record_field) ->
                let ctx, v = lower_expr ctx f.field_value in
                set_field ctx f.field_idx v (mk_ir_ty ctx.type_defs f.field_ty))
              ctx fields
        | _ ->
            raise
              (Lowering_error "variant: record payload must be a record literal")
        )
    | Constr_ty t ->
        let ctx, v = lower_expr ctx arg in
        set_field ctx 0 v (mk_ir_ty ctx.type_defs t)
  in
  (ctx, I.CR_OVar obj_var)

and lower_lambda_function (ctx : ctx) (name : string) (lam : C.lambda)
    (lam_ty : C.ty) (lambda_expr_id : int) : ctx * I.function_cir =
  let param_ctys = take (List.length lam.params) (get_args_ty lam_ty) in
  let slot_tys = full_param_ir_tys ctx.type_defs param_ctys in
  let free_idents =
    match Hashtbl.find_opt ctx.analysis.CA.closure_infos lambda_expr_id with
    | Some info -> CA.VarIdSet.elements info.free_vars
    | None -> []
  in
  let free_vars : I.var list =
    List.filter_map (fun (id : C.ident) -> env_find_var_opt ctx id) free_idents
  in
  let lambda_body_ctx, (lambda_param_vars, unit_param_indices) =
    let base_ctx =
      {
        empty_ctx with
        env = ctx.env;
        toplevel_functions = ctx.toplevel_functions;
        analysis = ctx.analysis;
        type_defs = ctx.type_defs;
        tmp_counter = ref 0 (* reset __var_ counter for function body *);
        block_counter = ref 0;
      }
    in
    let ctx_with_free_vars =
      List.fold_left (fun ctx fv -> env_add_var ctx fv) base_ctx free_vars
    in
    let tys = List.combine slot_tys param_ctys in
    let body_ctx, lambda_params, unit_pos_rev, _ =
      List.fold_left2
        (fun (ctx, vars, unit_pos, idx) (p : C.ident) (slot_ty, param_ty) ->
          if is_unit_cty param_ty then
            let ctx, v =
              fresh_var_with_name ctx (Printf.sprintf "__unit.%d" idx) slot_ty
            in
            let ctx = env_add_var ctx v in
            (ctx, v :: vars, idx :: unit_pos, idx + 1)
          else
            let ctx, v = fresh_var_with_name ctx p.name slot_ty in
            let ctx = env_add_var ctx v in
            (ctx, v :: vars, unit_pos, idx + 1))
        (ctx_with_free_vars, free_vars, [], List.length free_vars)
        lam.params tys
    in
    (body_ctx, (List.rev lambda_params, List.rev unit_pos_rev))
  in
  let body_ctx, ret_op = lower_expr lambda_body_ctx lam.body in
  let ctx = { ctx with lifted_fns = body_ctx.lifted_fns @ ctx.lifted_fns } in
  let declared_ret_ty = mk_ir_ty ctx.type_defs lam.ret_ty in
  let ret_term = make_return declared_ret_ty (Some ret_op) in
  let body_ctx = finish_block body_ctx ret_term in
  let blocks = List.rev body_ctx.blocks in
  let entry_block = List.hd blocks in
  let locals = List.rev body_ctx.locals in
  let fn_sir : I.function_cir =
    {
      I.id = fresh_id ();
      name;
      params = lambda_param_vars;
      locals;
      entry_block;
      blocks;
      return_ty = declared_ret_ty;
      visibility = I.CR_Public;
      unit_param_indices;
    }
  in
  (ctx, fn_sir)

and lower_args_to_slots (ctx : ctx) (args : C.expr list) (slot_tys : I.ty list)
    : ctx * I.operand list =
  match slot_tys with
  | [] -> (ctx, [])
  | _ ->
      let ctx, ops =
        List.fold_left2
          (fun (ctx, acc) (a : C.expr) slot_ty ->
            if is_unit_cty a.ty then
              (* a `unit` value carried in an i64 slot is the integer 0 *)
              (ctx, I.CR_OConstant (I.CR_IntLit "0", slot_ty) :: acc)
            else
              let ctx, op = lower_expr ctx a in
              let ctx, op =
                match op with
                | I.CR_OVar v
                  when not
                         (arg_type_compatible v.I.ty.I.ir_type slot_ty.I.ir_type)
                  ->
                    let ctx, new_v = fresh_var ctx slot_ty in
                    let ctx, _ =
                      emit ctx (assign_cast_var new_v v slot_ty) slot_ty
                    in
                    (ctx, I.CR_OVar new_v)
                | I.CR_OVar _ | I.CR_OConstant _ -> (ctx, op)
              in
              (ctx, op :: acc))
          (ctx, []) args slot_tys
      in
      (ctx, List.rev ops)

and lower_closure_apply (ctx : ctx) (closure_var : I.var)
    (closure_fun_ty : C.ty) (args : C.expr list) (out_ty : I.ty) :
    ctx * I.operand =
  let remaining = List.length (get_args_ty closure_fun_ty) in
  let napplied = List.length args in
  let slot_tys =
    List.map (fun (a : C.expr) -> slot_ir_ty ctx.type_defs a.ty) args
  in
  let ctx, concrete_arg_ops = lower_args_to_slots ctx args slot_tys in
  let ctx, call_dst, result =
    let ctx, dst = fresh_var ctx out_ty in
    (ctx, dst, I.CR_OVar dst)
  in
  let ctx, _ =
    if remaining = napplied then
      emit ctx
        (I.CR_Call
           {
             dst = call_dst;
             target = I.Apply { closure = closure_var };
             args = concrete_arg_ops;
           })
        out_ty
    else
      emit ctx
        (I.CR_Partial_apply
           {
             dst = call_dst;
             closure = closure_var;
             new_args = concrete_arg_ops;
           })
        out_ty
  in
  (ctx, result)

let build_const_init_fn (name : string) (value : I.constant) (ty : I.ty) :
    I.function_cir =
  let block_id = fresh_id () in
  let term_id = fresh_id () in
  let void_ty : I.ty = { I.id = 0; I.ir_type = I.CR_Void } in
  let void_var : I.var =
    let id = fresh_id () in
    { I.id; I.name = "__sy_cir_void_" ^ string_of_int id; I.ty = void_ty }
  in
  let ret_op = I.CR_OConstant (value, ty) in
  let term : I.terminator =
    { I.id = term_id; node = make_return ty (Some ret_op) }
  in
  let entry_block : I.block =
    {
      I.id = block_id;
      label_id = 0;
      statements = [];
      terminator = term;
      pred_blocks = [];
      succ_blocks = [];
    }
  in
  {
    I.id = fresh_id ();
    name;
    params = [];
    locals = [ void_var ];
    entry_block;
    blocks = [ entry_block ];
    return_ty = ty;
    visibility = I.CR_Private;
    unit_param_indices = [];
  }

let build_module_initializer (module_name : string)
    (globals : I.global_value list) : I.function_cir =
  let void_ty : I.ty = { I.id = 0; I.ir_type = I.CR_Void } in
  let void_var : I.var =
    let id = fresh_id () in
    { I.id; I.name = "__sy_cir_void_" ^ string_of_int id; I.ty = void_ty }
  in
  let stmts_acc, locals_acc =
    List.fold_left
      (fun (stmts_acc, locals_acc) (index, (gv : I.global_value)) ->
        let tmp_var : I.var =
          {
            I.id = fresh_id ();
            I.name = "__sy_cir_init_tmp_" ^ string_of_int index;
            I.ty = gv.ty;
          }
        in
        let call_stmt : I.statement =
          {
            I.id = fresh_id ();
            node =
              I.CR_Call
                { dst = tmp_var; target = Direct gv.init_fn.name; args = [] };
            ty = gv.ty;
          }
        in
        if gv.ty.I.ir_type = I.CR_Void then (call_stmt :: stmts_acc, locals_acc)
        else
          let store_stmt : I.statement =
            {
              I.id = fresh_id ();
              node =
                I.CR_Store_global
                  { global = gv.name; value = I.CR_OVar tmp_var };
              ty = gv.ty;
            }
          in
          (store_stmt :: call_stmt :: stmts_acc, tmp_var :: locals_acc))
      ([], [])
      (List.mapi (fun i gv -> (i, gv)) globals)
  in
  let stmts = List.rev stmts_acc in
  let locals = List.rev locals_acc in
  let term_id = fresh_id () in
  let term : I.terminator =
    { I.id = term_id; node = make_return void_ty None }
  in
  let block_id = fresh_id () in
  let entry_block : I.block =
    {
      I.id = block_id;
      label_id = 0;
      statements = stmts;
      terminator = term;
      pred_blocks = [];
      succ_blocks = [];
    }
  in
  {
    I.id = fresh_id ();
    name = "__init." ^ module_name;
    params = [];
    locals = void_var :: locals;
    entry_block;
    blocks = [ entry_block ];
    return_ty = void_ty;
    visibility = I.CR_Public;
    unit_param_indices = [];
  }

let lower_program (prog : C.program_core) : I.module_cir =
  let analysis = Syli_core.Closure_analysis.run prog in
  let type_defs =
    List.fold_left
      (fun m (item : C.structure_item) ->
        match item.structure_item_desc with
        | CStr_Type td -> StringMap.add td.name.name td m
        | _ -> m)
      StringMap.empty prog.C.structure_items
  in
  let toplevel_functions = collect_toplevel_functions prog in
  let root_ctx, functions, globals, external_functions =
    List.fold_left
      (fun (ctx, fns, globs, exts) (item : C.structure_item) ->
        match item.structure_item_desc with
        | CStr_Let { value = { node = CExp_Constant CConst_Unit; _ }; _ } ->
            (* Ignore unit constants *)
            (ctx, fns, globs, exts)
        | CStr_Let { name; value; _ } -> (
            match value.node with
            | CExp_Lambda lam ->
                let ctx, fn =
                  lower_lambda_function ctx name.name lam value.ty value.id
                in
                let fn_ty = mk_ir_ty type_defs value.ty in
                let fn_var : I.var =
                  { I.id = fresh_id (); I.name = name.name; I.ty = fn_ty }
                in
                let ctx =
                  { ctx with env = StringMap.add fn_var.name fn_var ctx.env }
                in
                (ctx, fn :: fns, globs, exts)
            | CExp_Constant c ->
                let const_value = ir_const_of_core c in
                let const_ty = mk_ir_ty type_defs value.ty in
                let init_fn_name = "__init_global." ^ name.name in
                let init_fn =
                  build_const_init_fn init_fn_name const_value const_ty
                in
                let gv : I.global_value =
                  {
                    I.name = name.name;
                    init_fn;
                    value = const_value;
                    ty = const_ty;
                    visibility = I.CR_Public;
                  }
                in
                let const_var : I.var =
                  { I.id = fresh_id (); I.name = name.name; I.ty = const_ty }
                in
                let ctx =
                  { ctx with env = StringMap.add name.name const_var ctx.env }
                in
                (ctx, init_fn :: fns, gv :: globs, exts)
            | _ ->
                (* Non-constant, non-lambda:
                   create a global with CR_Null and an init function that computes
                   the value and returns it.
                   The module initializer function will call the init
                   function and store the result to the global. *)
                let global_ty = mk_ir_ty type_defs value.ty in
                let value_ctx =
                  {
                    empty_ctx with
                    env = ctx.env;
                    toplevel_functions;
                    analysis;
                    type_defs;
                    tmp_counter = ref 0;
                    block_counter = ref 0;
                  }
                in
                let value_ctx, result = lower_expr value_ctx value in
                let value_ctx =
                  finish_block value_ctx (make_return global_ty (Some result))
                in
                let init_fn_name = "__init_global." ^ name.name in
                let blocks = List.rev value_ctx.blocks in
                let entry_block = List.hd blocks in
                let init_fn : I.function_cir =
                  {
                    I.id = fresh_id ();
                    name = init_fn_name;
                    params = [];
                    locals = List.rev value_ctx.locals;
                    entry_block;
                    blocks;
                    return_ty = global_ty;
                    visibility = I.CR_Private;
                    unit_param_indices = [];
                  }
                in
                let gv : I.global_value =
                  {
                    I.name = name.name;
                    init_fn;
                    value = I.CR_Null;
                    ty = global_ty;
                    visibility = I.CR_Public;
                  }
                in
                let global_var : I.var =
                  { I.id = fresh_id (); I.name = name.name; I.ty = global_ty }
                in
                let ctx =
                  { ctx with env = StringMap.add name.name global_var ctx.env }
                in
                (ctx, init_fn :: fns, gv :: globs, exts))
        | CStr_Type _ -> (ctx, fns, globs, exts)
        | CStr_External { fname; ty; external_fn } -> (
            match external_fn.kind with
            | Foreign ->
                let ret_ty = get_return_ty ty in
                let param_ctys = get_args_ty ty in
                let ext_fn : I.ffi_external_function =
                  {
                    I.name = external_fn.symbol;
                    I.syli_name = fname.name;
                    I.ret_ty = mk_ir_ty type_defs ret_ty;
                    I.params = full_param_ir_tys type_defs param_ctys;
                    I.calling_convention = external_fn.calling_convention;
                    I.unit_param_indices = unit_indices_of_ctys param_ctys;
                  }
                in
                let ext_ty = mk_ir_ty type_defs ty in
                let ext_var : I.var =
                  { I.id = fresh_id (); I.name = fname.name; I.ty = ext_ty }
                in
                let ctx =
                  { ctx with env = StringMap.add fname.name ext_var ctx.env }
                in
                (ctx, fns, globs, ext_fn :: exts)
            | Primitive ->
                let prim_ty = mk_ir_ty type_defs ty in
                let prim_var : I.var =
                  { I.id = fresh_id (); I.name = fname.name; I.ty = prim_ty }
                in
                let prim_fn =
                  Gen_primitives.build type_defs ~fn_name:fname.name
                    ~symbol:external_fn.symbol ~is_public:external_fn.public ty
                in
                let ctx =
                  { ctx with env = StringMap.add fname.name prim_var ctx.env }
                in
                ( { ctx with primitive_fns = prim_fn :: ctx.primitive_fns },
                  fns,
                  globs,
                  exts )))
      ({ empty_ctx with toplevel_functions; analysis; type_defs }, [], [], [])
      prog.C.structure_items
  in
  let global_values = List.rev globals in
  let module_init_fn =
    build_module_initializer prog.C.name.name global_values
  in
  let functions =
    (module_init_fn :: List.rev (root_ctx.lifted_fns @ List.rev functions))
    @ List.rev root_ctx.primitive_fns
  in
  {
    I.name = prog.C.name.name;
    type_defs = [];
    functions;
    global_values =
      List.filter (fun gv -> not (gv.ty.I.ir_type = I.CR_Void)) global_values;
    ffi_external_functions = List.rev external_functions;
  }

let lower (ctx : Pipeline_types.core_ctx) : Pipeline_types.cir_ctx =
  { Pipeline_types.module_cir = lower_program ctx.Pipeline_types.program }

let run prog = lower_program prog
