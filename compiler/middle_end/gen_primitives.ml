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

(** The operation a primitive symbol stands for. *)
type operation =
  | Op_binop of I.binop (* add sub mul div mod eq ne lt le gt ge *)
  | Op_array_len (* array length *)
  | Op_array_size (* array size in bytes *)
  | Op_index_get (* array index get *)
  | Op_index_set (* array index set *)

let operation_of_symbol : string -> operation option = function
  | "add" -> Some (Op_binop CR_Add)
  | "sub" -> Some (Op_binop CR_Sub)
  | "mul" -> Some (Op_binop CR_Mul)
  | "div" -> Some (Op_binop CR_Div)
  | "mod" -> Some (Op_binop CR_Mod)
  | "eq" -> Some (Op_binop CR_Eq)
  | "ne" -> Some (Op_binop CR_Ne)
  | "lt" -> Some (Op_binop CR_Lt)
  | "le" -> Some (Op_binop CR_Le)
  | "gt" -> Some (Op_binop CR_Gt)
  | "ge" -> Some (Op_binop CR_Ge)
  | "array_len" -> Some Op_array_len
  | "array_size" -> Some Op_array_size
  | "array_index_get" -> Some Op_index_get
  | "array_index_set" -> Some Op_index_set
  | _ -> None

(** Assemble a single-block CIR function from its parts. *)
let make_prim_function ~(name : string) ~(params : I.var list)
    ~(locals : I.var list) ~(statements : I.statement list)
    ~(term_node : I.terminator_node) ~(ret_ty : I.ty) ~(is_public : bool) :
    I.function_cir =
  let block_id = fresh_id () in
  let term : I.terminator = { I.id = fresh_id (); node = term_node } in
  let entry_block : I.block =
    {
      I.id = block_id;
      label_id = 0;
      statements;
      terminator = term;
      pred_blocks = [];
      succ_blocks = [];
    }
  in
  {
    I.id = fresh_id ();
    name;
    params;
    locals;
    entry_block;
    blocks = [ entry_block ];
    return_ty = ret_ty;
    visibility = (if is_public then I.CR_Public else I.CR_Private);
    unit_param_indices = [];
  }

let build_operation (type_defs : Type_lowering.type_entry StringMap.t)
    (name : string) (op : operation) (is_public : bool) (annotated_ty : C.ty) :
    I.function_cir =
  match op with
  | Op_binop binop ->
      let param_ctys = Type_lowering.get_args_ty annotated_ty in
      if List.length param_ctys <> 2 then
        raise
          (Primitive_error
             (Printf.sprintf
                "primitive %s must be a binary operator, got %d args" name
                (List.length param_ctys)));
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
                    node =
                      I.CR_BinOp
                        { op = binop; lhs = I.CR_OVar x; rhs = I.CR_OVar y };
                    ty = ir_ret_ty;
                  };
              };
          ty = ir_ret_ty;
        }
      in
      make_prim_function ~name ~params:[ x; y ] ~locals:[ result ]
        ~statements:[ assign ]
        ~term_node:(I.CR_Return (Some (I.CR_OVar result))) ~ret_ty:ir_ret_ty
        ~is_public
  | Op_array_len | Op_array_size ->
      let param_ctys = Type_lowering.get_args_ty annotated_ty in
      if List.length param_ctys <> 1 then
        raise
          (Primitive_error
             (Printf.sprintf "primitive %s must be unary, got %d args" name
                (List.length param_ctys)));
      let ret_ty = Type_lowering.get_return_ty annotated_ty in
      let param_ty = Type_lowering.mk_ir_ty type_defs (List.nth param_ctys 0) in
      let ir_ret_ty = Type_lowering.mk_ir_ty type_defs ret_ty in
      let x : I.var = { I.id = fresh_id (); I.name = "x"; I.ty = param_ty } in
      let result : I.var =
        { I.id = fresh_id (); I.name = "Sy_prim_result"; I.ty = ir_ret_ty }
      in
      let node : I.rvalue_node =
        match op with
        | Op_array_len -> I.CR_Object_length { obj = I.CR_OVar x }
        | _ -> I.CR_Object_size { obj = I.CR_OVar x }
      in
      let assign : I.statement =
        {
          I.id = fresh_id ();
          node =
            I.CR_Assign
              {
                dst = result;
                rvalue = { I.id = fresh_id (); node; ty = ir_ret_ty };
              };
          ty = ir_ret_ty;
        }
      in
      make_prim_function ~name ~params:[ x ] ~locals:[ result ]
        ~statements:[ assign ]
        ~term_node:(I.CR_Return (Some (I.CR_OVar result))) ~ret_ty:ir_ret_ty
        ~is_public
  | Op_index_get | Op_index_set ->
      let param_ctys = Type_lowering.get_args_ty annotated_ty in
      let ret_cty = Type_lowering.get_return_ty annotated_ty in
      let param_tys = List.map (Type_lowering.mk_ir_ty type_defs) param_ctys in
      let ir_ret_ty = Type_lowering.mk_ir_ty type_defs ret_cty in
      let mk_param i ty =
        let name = match i with 0 -> "x" | 1 -> "y" | _ -> "z" in
        { I.id = fresh_id (); I.name; I.ty }
      in
      let need n =
        if List.length param_ctys <> n then
          raise
            (Primitive_error
               (Printf.sprintf "primitive %s must take %d arguments, got %d"
                  name n (List.length param_ctys)))
      in
      let arr = mk_param 0 (List.nth param_tys 0) in
      let idx = mk_param 1 (List.nth param_tys 1) in
      let projection = I.CR_Project_array (I.CR_OVar idx) in
      let params, locals, statements, term_node =
        match op with
        | Op_index_get ->
            need 2;
            let elt_ty = ir_ret_ty in
            let result : I.var =
              { I.id = fresh_id (); I.name = "Sy_prim_result"; I.ty = elt_ty }
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
                          node =
                            I.CR_Object_get
                              {
                                obj = I.CR_OVar arr;
                                projection;
                                value_ty = elt_ty;
                              };
                          ty = elt_ty;
                        };
                    };
                ty = elt_ty;
              }
            in
            ( [ arr; idx ],
              [ result ],
              [ assign ],
              I.CR_Return (Some (I.CR_OVar result)) )
        | _ ->
            need 3;
            let val_v = mk_param 2 (List.nth param_tys 2) in
            let elt_ty = List.nth param_tys 2 in
            let set_stmt : I.statement =
              {
                I.id = fresh_id ();
                node =
                  I.CR_Object_set
                    {
                      obj = arr;
                      projection;
                      value = I.CR_OVar val_v;
                      value_ty = elt_ty;
                    };
                ty = elt_ty;
              }
            in
            ([ arr; idx; val_v ], [], [ set_stmt ], I.CR_Return None)
      in
      make_prim_function ~name ~params ~locals ~statements ~term_node
        ~ret_ty:ir_ret_ty ~is_public

let build (type_defs : Type_lowering.type_entry StringMap.t) ~(fn_name : string)
    ~(symbol : string) ~(is_public : bool) (annotated_ty : C.ty) :
    I.function_cir =
  match operation_of_symbol symbol with
  | Some op -> build_operation type_defs fn_name op is_public annotated_ty
  | None ->
      raise
        (Primitive_error (Printf.sprintf "Unknown primitive symbol: %s" symbol))
