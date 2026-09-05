open Typed_ast

let indent n = String.make (n * 2) ' '

let rec string_of_ty (t : ty) : string =
  match t.ty_desc with
  | TTy_Constant TTy_Int64 -> "i64"
  | TTy_Constant TTy_Int32 -> "i32"
  | TTy_Constant TTy_Int16 -> "i16"
  | TTy_Constant TTy_Int8 -> "i8"
  | TTy_Constant TTy_UInt64 -> "u64"
  | TTy_Constant TTy_UInt32 -> "u32"
  | TTy_Constant TTy_UInt16 -> "u16"
  | TTy_Constant TTy_UInt8 -> "u8"
  | TTy_Constant TTy_Bool -> "bool"
  | TTy_Constant TTy_Unit -> "unit"
  | TTy_Constant TTy_F32 -> "f32"
  | TTy_Constant TTy_F64 -> "f64"
  | TTy_Constant TTy_String -> "string"
  | TTy_Constant TTy_Char -> "char"
  | TTy_Array ty -> "array[" ^ string_of_ty ty ^ "]"
  | TTy_Tuple tys -> "(" ^ String.concat " * " (List.map string_of_ty tys) ^ ")"
  | TTy_Arrow (arg, ret) -> string_of_ty arg ^ " -> " ^ string_of_ty ret
  | TTy_Var i -> "'" ^ string_of_int i
  | TTy_Defined { name; args } ->
      let base = name.name in
      if args = [] then base
      else base ^ "[" ^ String.concat ", " (List.map string_of_ty args) ^ "]"
  | TTy_Any -> "_"

let rec string_of_pattern (p : pattern) : string =
  match p.pattern_desc with
  | TPat_Unit -> "()"
  | TPat_BoolLit b -> b
  | TPat_IntLit n -> n
  | TPat_CharLit c -> "'" ^ c ^ "'"
  | TPat_FloatLit f -> f
  | TPat_StringLit s -> "\"" ^ String.escaped s ^ "\""
  | TPat_Ident s -> s.name
  | TPat_Any -> "_"
  | TPat_Tuple { elements } ->
      "(" ^ String.concat ", " (List.map string_of_pattern elements) ^ ")"
  | TPat_Record { fields } ->
      "{ "
      ^ String.concat ", "
          (List.map
             (fun (f : pattern_record_field) ->
               match f.pattern with
               | None -> f.name.name
               | Some p' -> f.name.name ^ ": " ^ string_of_pattern p')
             fields)
      ^ " }"
  | TPat_Constructor { ident = name; pattern = None } -> name
  | TPat_Constructor { ident = name; pattern = Some pat } ->
      name ^ "(" ^ string_of_pattern pat ^ ")"

let string_of_constant (c : constant) : string =
  match c.constant_desc with
  | TConst_Unit -> "()"
  | TConst_BoolLit s -> s
  | TConst_IntLit s -> s
  | TConst_FloatLit s -> s
  | TConst_CharLit s -> "'" ^ s ^ "'"
  | TConst_StringLit s -> "\"" ^ String.escaped s ^ "\""

let rec string_of_expr ?(ind = 0) (expr : expr) : string =
  match expr.expr_desc with
  | TExp_Constant c -> string_of_constant c
  | TExp_Ident idr -> idr.name
  | TExp_Tuple { elements } ->
      "(" ^ String.concat ", " (List.map (string_of_expr ~ind) elements) ^ ")"
  | TExp_Record { fields } ->
      "{ "
      ^ String.concat ", "
          (List.map
             (fun f ->
               f.field_name.name ^ ": " ^ string_of_expr ~ind f.field_value)
             fields)
      ^ " }"
  | TExp_VariantConstructor { name; arg = None } -> name.name
  | TExp_VariantConstructor { name; arg = Some e } ->
      name.name ^ "(" ^ string_of_expr ~ind e ^ ")"
  | TExp_Array { element_ty = _; elements; size } ->
      "array["
      ^ String.concat ", " (List.map (string_of_expr ~ind) elements)
      ^ "]" ^ " size=" ^ string_of_expr ~ind size
  | TExp_Lambda (lam : lambda) ->
      let params =
        List.map
          (fun (p : param) ->
            match p.pattern.pattern_desc with
            | TPat_Ident s -> s.name
            | _ -> "_")
          lam.params
      in
      "lambda(" ^ String.concat ", " params ^ ") => "
      ^ string_of_expr ~ind lam.body
  | TExp_Apply { closure_fun; args } ->
      string_of_expr ~ind closure_fun
      ^ "("
      ^ String.concat ", " (List.map (string_of_expr ~ind) args)
      ^ ")"
  | TExp_Let l ->
      let lhs =
        match l.pattern.pattern_desc with TPat_Ident s -> s.name | _ -> "_"
      in
      "let " ^ lhs ^ " = " ^ string_of_expr ~ind l.value
  | TExp_If { condition; then_branch; else_branch = None } ->
      "if "
      ^ string_of_expr ~ind condition
      ^ " then "
      ^ string_of_expr ~ind then_branch
  | TExp_If { condition; then_branch; else_branch = Some e } ->
      "if "
      ^ string_of_expr ~ind condition
      ^ " then "
      ^ string_of_expr ~ind then_branch
      ^ " else " ^ string_of_expr ~ind e
  | TExp_While { condition; body } ->
      "while "
      ^ string_of_expr ~ind condition
      ^ " do " ^ string_of_expr ~ind body
  | TExp_Loop { expr } -> "loop " ^ string_of_expr ~ind expr
  | TExp_Break { expr_opt = None } -> "break"
  | TExp_Break { expr_opt = Some e } -> "break " ^ string_of_expr ~ind e
  | TExp_Continue -> "continue"
  | TExp_Return { expr_opt = None } -> "return"
  | TExp_Return { expr_opt = Some e } -> "return " ^ string_of_expr ~ind e
  | TExp_Seq { exprs } ->
      "{\n"
      ^ String.concat "\n"
          (List.map
             (fun e -> indent (ind + 1) ^ string_of_expr ~ind:(ind + 1) e)
             exprs)
      ^ "\n" ^ indent ind ^ "}"
  | TExp_Match { expr = scrutinee; cases } ->
      let cases_str =
        List.map
          (fun (c : pattern_case) ->
            let guard =
              match c.when_condition with
              | None -> ""
              | Some g -> " when " ^ string_of_expr ~ind g
            in
            indent (ind + 1)
            ^ "| "
            ^ string_of_pattern c.pattern
            ^ guard ^ " -> "
            ^ string_of_expr ~ind:(ind + 1) c.body)
          cases
      in
      "match "
      ^ string_of_expr ~ind scrutinee
      ^ " {\n"
      ^ String.concat "\n" cases_str
      ^ "\n" ^ indent ind ^ "}"
  | TExp_Field { record; field_name } ->
      string_of_expr ~ind record ^ "." ^ field_name.name
  | TExp_FieldSet { record; field_name; value } ->
      string_of_expr ~ind record ^ "." ^ field_name.name ^ " = "
      ^ string_of_expr ~ind value
