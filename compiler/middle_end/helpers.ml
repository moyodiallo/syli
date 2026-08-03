open Syli_ir.Cir

let rec type_key_of_ty (t : ty) : string =
  match t.ir_type with
  | CR_Bool -> "bool"
  | CR_I64 -> "i64"
  | CR_I32 -> "i32"
  | CR_I16 -> "i16"
  | CR_I8 -> "i8"
  | CR_U64 -> "u64"
  | CR_U32 -> "u32"
  | CR_U16 -> "u16"
  | CR_U8 -> "u8"
  | CR_Float -> "f32"
  | CR_Double -> "f64"
  | CR_FnPtr -> "fn_ptr"
  | CR_Char -> "char"
  | CR_Str -> "str"
  | CR_Void -> "void"
  | CR_GenericTyp { type_var } -> "gen" ^ string_of_int type_var
  | CR_Obj_Ptr -> "obj_ptr"
  | CR_Obj { named; obj_kind; _ } -> (
      let name = match named with Some n -> n | None -> "obj" in
      match obj_kind with
      | CR_Record_kind { fields; _ } ->
          let field_keys =
            String.concat "_"
              (List.map (fun f -> type_key_of_ty f.field_ty) fields)
          in
          if named = None && field_keys <> "" then
            "obj_" ^ name ^ "_" ^ field_keys
          else "obj_" ^ name
      | CR_Array_kind { element_ty } ->
          "obj_" ^ name ^ "_" ^ type_key_of_ty element_ty)
  | CR_Arrow (args, ret) ->
      "fn_"
      ^ String.concat "_" (List.map type_key_of_ty args)
      ^ "_" ^ type_key_of_ty ret

let rec ir_type_equal (a : ir_type) (b : ir_type) : bool =
  match (a, b) with
  | CR_Arrow (args1, ret1), CR_Arrow (args2, ret2) ->
      List.length args1 = List.length args2
      && List.for_all2 (fun a b -> ty_equal a b) args1 args2
      && ty_equal ret1 ret2
  | CR_Obj_Ptr, CR_Obj_Ptr -> true
  | CR_Obj a, CR_Obj b ->
      a.named = b.named
      && a.tag_variant = b.tag_variant
      && a.cyclic_prop = b.cyclic_prop
      && obj_kind_equal a.obj_kind b.obj_kind
  | _ -> a = b

and obj_kind_equal (a : obj_kind) (b : obj_kind) : bool =
  match (a, b) with
  | ( CR_Record_kind { fields = fa; cardinal = ca },
      CR_Record_kind { fields = fb; cardinal = cb } ) ->
      ca = cb
      && List.for_all2
           (fun fa fb ->
             fa.field_idx = fb.field_idx
             && fa.field_mut = fb.field_mut
             && ty_equal fa.field_ty fb.field_ty)
           fa fb
  | CR_Array_kind { element_ty = ea }, CR_Array_kind { element_ty = eb } ->
      ty_equal ea eb
  | _, _ -> false

and ty_equal (a : ty) (b : ty) : bool = ir_type_equal a.ir_type b.ir_type

let specialization_name (fn_name : qualified_name) (arg_tys : ty list)
    (ret_ty : ty) : string =
  let rec check_ty ty =
    match ty.ir_type with
    | CR_Arrow (args, ret) -> List.for_all check_ty args && check_ty ret
    | CR_GenericTyp _ -> false
    | ty -> true
  in
  if not (check_ty ret_ty && List.for_all check_ty arg_tys) then
    failwith "Generic param ty for monomorphize funciton"
  else
    let suffix = String.concat "__" (List.map type_key_of_ty arg_tys) in
    if suffix = "" then fn_name
    else fn_name ^ "__" ^ suffix ^ "_ret_" ^ type_key_of_ty ret_ty
