(** Constructs CIR wrapper functions for primitive operators.

    Each primitive declared at the source level (e.g.
    [primitive (+)  : i64 -> i64 -> i64 = "add"]) is turned into a CIR function
    that applies the corresponding [CR_BinOp]. The wrappers are built from the
    annotated types carried by the declaration. *)

open Syli_core.Core_ast
open Syli_ir.Cir
open Syli_common
module C = Syli_core.Core_ast
module I = Syli_ir.Cir

exception Primitive_error of string

let default_cyclic_prop = I.Unknown_cyclic_prop

let mut_flag_of_core = function
  | CMutable -> I.Mutable
  | CImmutable -> I.Immutable

let rec get_args_ty (ty : C.ty) : C.ty list =
  match ty.ty_desc with
  | CTy_Arrow (arg, ret) -> arg :: get_args_ty ret
  | _ -> []

let rec get_return_ty (ty : C.ty) : C.ty =
  match ty.ty_desc with CTy_Arrow (_, ret) -> get_return_ty ret | _ -> ty

let mk_ir_ty (type_defs : C.ty_decl StringMap.t) (cty : C.ty) : I.ty =
  let rec go (t : C.ty) : I.ir_type =
    match t.ty_desc with
    | CTy_Constant c -> (
        match c with
        | CTy_Int64 -> I.CR_I64
        | CTy_Int32 -> I.CR_I32
        | CTy_Int16 -> I.CR_I16
        | CTy_Int8 -> I.CR_I8
        | CTy_UInt64 -> I.CR_U64
        | CTy_UInt32 -> I.CR_U32
        | CTy_UInt16 -> I.CR_U16
        | CTy_UInt8 -> I.CR_U8
        | CTy_Unit -> I.CR_Void
        | CTy_Bool -> I.CR_Bool
        | CTy_F32 -> I.CR_F32
        | CTy_F64 -> I.CR_F64
        | CTy_String -> I.CR_String
        | CTy_Char -> I.CR_Char)
    | CTy_Var v -> I.CR_GenericTyp { type_var = v }
    | CTy_Arrow _ ->
        (* Function parameters follow the Core->CIR calling convention: every
           `unit` parameter is carried as an [i64] slot, uniformly. *)
        let is_unit t =
          match t.ty_desc with C.CTy_Constant C.CTy_Unit -> true | _ -> false
        in
        let args =
          List.map
            (fun a ->
              {
                I.id = fresh_id ();
                I.ir_type = (if is_unit a then I.CR_I64 else go a);
              })
            (get_args_ty t)
        in
        let ret = { I.id = fresh_id (); I.ir_type = go (get_return_ty t) } in
        I.CR_Arrow (args, ret)
    | CTy_Tuple tys ->
        let fields =
          List.mapi
            (fun i t ->
              {
                I.field_idx = i;
                field_ty = { I.id = fresh_id (); I.ir_type = go t };
                field_mut = I.Mutable;
              })
            tys
        in
        I.CR_Obj
          {
            named = None;
            obj_kind = I.CR_Record_kind { fields; cardinal = List.length tys };
            tag_variant = None;
            cyclic_prop = default_cyclic_prop;
          }
    | CTy_Array elem ->
        I.CR_Obj
          {
            named = None;
            obj_kind =
              I.CR_Array_kind
                { element_ty = { I.id = fresh_id (); I.ir_type = go elem } };
            tag_variant = None;
            cyclic_prop = default_cyclic_prop;
          }
    | CTy_Defined { name; _ } -> (
        match StringMap.find_opt name.name type_defs with
        | Some { def = CTydef_Record decl_fields; _ } ->
            let fields =
              List.map
                (fun (f : C.record_field_ty) ->
                  {
                    I.field_idx = f.field_idx;
                    field_ty = { I.id = fresh_id (); I.ir_type = go f.field_ty };
                    field_mut = mut_flag_of_core f.field_mut;
                  })
                decl_fields
            in
            I.CR_Obj
              {
                named = Some name.name;
                obj_kind =
                  I.CR_Record_kind { fields; cardinal = List.length fields };
                tag_variant = None;
                cyclic_prop = default_cyclic_prop;
              }
        | Some { def = CTydef_Alias t; _ } -> failwith "Not supported yet"
        | Some { def = CTydef_Variant _ | CTydef_Abstract; _ } ->
            failwith "Not yet supported"
        | None ->
            let msg = Printf.sprintf "Type %s not found" name.name in
            failwith msg)
  in
  { I.id = fresh_id (); I.ir_type = go cty }

let binop_of_symbol (symbol : string) : I.binop option =
  match symbol with
  | "add" -> Some CR_Add
  | "sub" -> Some CR_Sub
  | "mul" -> Some CR_Mul
  | "div" -> Some CR_Div
  | "mod" -> Some CR_Mod
  | "eq" -> Some CR_Eq
  | "ne" -> Some CR_Ne
  | "lt" -> Some CR_Lt
  | "le" -> Some CR_Le
  | "gt" -> Some CR_Gt
  | "ge" -> Some CR_Ge
  | _ -> None

let build_binop (type_defs : C.ty_decl StringMap.t) (name : string)
    (op : I.binop) (is_public : bool) (annotated_ty : C.ty) : I.function_cir =
  let param_ctys = get_args_ty annotated_ty in
  if List.length param_ctys <> 2 then
    raise
      (Primitive_error
         (Printf.sprintf "primitive %s must be a binary operator, got %d args"
            name (List.length param_ctys)));
  let ret_ty = get_return_ty annotated_ty in
  let param_tys = List.map (mk_ir_ty type_defs) param_ctys in
  let ir_ret_ty = mk_ir_ty type_defs ret_ty in
  let mk_param i ty =
    { I.id = fresh_id (); I.name = (if i = 0 then "x" else "y"); I.ty }
  in
  let x = mk_param 0 (List.nth param_tys 0) in
  let y = mk_param 1 (List.nth param_tys 1) in
  let result : I.var =
    { I.id = fresh_id (); I.name = "Sy_prim_result"; I.ty = ir_ret_ty }
  in
  let assign : I.statement =
    {
      I.id = fresh_id ();
      node =
        I.CR_Assign
          {
            dst = result;
            rvalue =
              {
                I.id = fresh_id ();
                node = I.CR_BinOp { op; lhs = I.CR_OVar x; rhs = I.CR_OVar y };
                ty = ir_ret_ty;
              };
          };
      ty = ir_ret_ty;
    }
  in
  let block_id = fresh_id () in
  let term : I.terminator =
    { I.id = fresh_id (); node = I.CR_Return (Some (I.CR_OVar result)) }
  in
  let entry_block : I.block =
    {
      I.id = block_id;
      label_id = 0;
      statements = [ assign ];
      terminator = term;
      pred_blocks = [];
      succ_blocks = [];
    }
  in
  {
    I.id = fresh_id ();
    name;
    params = [ x; y ];
    locals = [ result ];
    entry_block;
    blocks = [ entry_block ];
    return_ty = ir_ret_ty;
    visibility = (if is_public then I.CR_Public else I.CR_Private);
    unit_param_indices = [];
  }

let build (type_defs : C.ty_decl StringMap.t) ~(fn_name : string)
    ~(symbol : string) ~(is_public : bool) (annotated_ty : C.ty) :
    I.function_cir =
  match binop_of_symbol symbol with
  | Some op -> build_binop type_defs fn_name op is_public annotated_ty
  | None ->
      raise
        (Primitive_error (Printf.sprintf "Unknown primitive symbol: %s" symbol))
