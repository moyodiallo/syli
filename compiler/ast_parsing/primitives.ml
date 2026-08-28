open Ast

type primitive_instances = { name : string; tys : ty list }

let mk_ty ty_desc : ty =
  { id = 0; ty_desc; loc = { start_pos = 0; end_pos = 0; filename = "" } }

let triple_arithmetic_arrow_ty ty_desc =
  mk_ty
  @@ Ty_Arrow
       (mk_ty @@ ty_desc, mk_ty @@ Ty_Arrow (mk_ty @@ ty_desc, mk_ty @@ ty_desc))

let triple_comparison_arrow_ty ty_desc =
  mk_ty
  @@ Ty_Arrow
       ( mk_ty @@ ty_desc,
         mk_ty @@ Ty_Arrow (mk_ty @@ ty_desc, mk_ty @@ Ty_Constant Ty_Bool) )

let arithmetic_const_tys =
  [
    Ty_Constant Ty_Int8;
    Ty_Constant Ty_Int16;
    Ty_Constant Ty_Int32;
    Ty_Constant Ty_Int64;
    Ty_Constant Ty_UInt8;
    Ty_Constant Ty_UInt16;
    Ty_Constant Ty_UInt32;
    Ty_Constant Ty_UInt64;
    Ty_Constant Ty_F32;
    Ty_Constant Ty_F64;
  ]

let comparison_const_tys =
  [
    Ty_Constant Ty_Int8;
    Ty_Constant Ty_Int16;
    Ty_Constant Ty_Int32;
    Ty_Constant Ty_Int64;
    Ty_Constant Ty_UInt8;
    Ty_Constant Ty_UInt16;
    Ty_Constant Ty_UInt32;
    Ty_Constant Ty_UInt64;
    Ty_Constant Ty_F32;
    Ty_Constant Ty_F64;
  ]

let primitives =
  [
    {
      name = "add";
      tys = List.map triple_arithmetic_arrow_ty arithmetic_const_tys;
    };
    {
      name = "sub";
      tys = List.map triple_arithmetic_arrow_ty arithmetic_const_tys;
    };
    {
      name = "mul";
      tys = List.map triple_arithmetic_arrow_ty arithmetic_const_tys;
    };
    {
      name = "div";
      tys = List.map triple_arithmetic_arrow_ty arithmetic_const_tys;
    };
    {
      name = "mod";
      tys = List.map triple_arithmetic_arrow_ty arithmetic_const_tys;
    };
    {
      name = "eq";
      tys = List.map triple_comparison_arrow_ty comparison_const_tys;
    };
    {
      name = "lt";
      tys = List.map triple_comparison_arrow_ty comparison_const_tys;
    };
    {
      name = "gt";
      tys = List.map triple_comparison_arrow_ty comparison_const_tys;
    };
    {
      name = "le";
      tys = List.map triple_comparison_arrow_ty comparison_const_tys;
    };
    {
      name = "ge";
      tys = List.map triple_comparison_arrow_ty comparison_const_tys;
    };
  ]

let rec is_ty_equal (ty1 : ty) (ty2 : ty) : bool =
  match (ty1.ty_desc, ty2.ty_desc) with
  | Ty_Constant c1, Ty_Constant c2 -> c1 = c2
  | Ty_Any, Ty_Any -> true
  | Ty_Var v1, Ty_Var v2 -> v1 = v2
  | Ty_Arrow (arg1, ret1), Ty_Arrow (arg2, ret2) ->
      is_ty_equal arg1 arg2 && is_ty_equal ret1 ret2
  | Ty_Tuple elems1, Ty_Tuple elems2 ->
      List.length elems1 = List.length elems2
      && List.for_all2 is_ty_equal elems1 elems2
  | Ty_Array elem1, Ty_Array elem2 -> is_ty_equal elem1 elem2
  | Ty_Defined { name = n1; args = a1 }, Ty_Defined { name = n2; args = a2 } ->
      n1.name = n2.name
      && List.length a1 = List.length a2
      && List.for_all2 is_ty_equal a1 a2
  | _ -> false

let find_primitive (name : string) : primitive_instances option =
  List.find_opt (fun p -> p.name = name) primitives

let ty_match_primitive_instance (ty : ty) (p : primitive_instances) : bool =
  List.exists (fun t -> is_ty_equal t ty) p.tys
