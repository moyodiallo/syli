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
  let param_ctys = Type_lowering.get_args_ty annotated_ty in
  if List.length param_ctys <> 2 then
    raise
      (Primitive_error
         (Printf.sprintf "primitive %s must be a binary operator, got %d args"
            name (List.length param_ctys)));
  let ret_ty = Type_lowering.get_return_ty annotated_ty in
  let param_tys = List.map (Type_lowering.mk_ir_ty type_defs) param_ctys in
  let ir_ret_ty = Type_lowering.mk_ir_ty type_defs ret_ty in
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
