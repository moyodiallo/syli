open Ast

type 'acc visitor = {
  ty : 'acc visitor -> 'acc -> ty -> 'acc;
  expr : 'acc visitor -> 'acc -> expr -> 'acc;
  pattern : 'acc visitor -> 'acc -> pattern -> 'acc;
  pattern_case : 'acc visitor -> 'acc -> pattern_case -> 'acc;
  structure_item : 'acc visitor -> 'acc -> structure_item -> 'acc;
  signature_item : 'acc visitor -> 'acc -> signature_item -> 'acc;
  module_signature : 'acc visitor -> 'acc -> module_signature -> 'acc;
  module_structure : 'acc visitor -> 'acc -> module_structure -> 'acc;
}

let rec visit_ty_children (v : 'acc visitor) (acc : 'acc) (ty : ty) : 'acc =
  match ty.ty_desc with
  | Ty_Constant _ | Ty_Var _ | Ty_Any -> acc
  | Ty_Array inner -> v.ty v acc inner
  | Ty_Tuple tys -> List.fold_left (v.ty v) acc tys
  | Ty_Arrow (param_ty, ret) ->
      let acc = v.ty v acc param_ty in
      v.ty v acc ret
  | Ty_Defined { args; _ } -> List.fold_left (v.ty v) acc args

let rec visit_pattern_children (v : 'acc visitor) (acc : 'acc) (p : pattern) :
    'acc =
  match p.node with
  | Pat_Unit | Pat_BoolLit _ | Pat_IntLit _ | Pat_CharLit _ | Pat_FloatLit _
  | Pat_StringLit _ | Pat_Ident _ | Pat_Any ->
      acc
  | Pat_Tuple { elements } -> List.fold_left (v.pattern v) acc elements
  | Pat_Record { fields } ->
      List.fold_left
        (fun a (f : pattern_record_field) ->
          Option.fold ~none:a ~some:(v.pattern v a) f.value)
        acc fields
  | Pat_Constructor { value; _ } ->
      Option.fold ~none:acc ~some:(v.pattern v acc) value

let visit_param (v : 'acc visitor) (acc : 'acc) (p : param) : 'acc =
  let acc = v.pattern v acc p.pattern in
  Option.fold ~none:acc ~some:(v.ty v acc) p.param_ty

let visit_lambda (v : 'acc visitor) (acc : 'acc) (lam : lambda) : 'acc =
  let acc = List.fold_left (visit_param v) acc lam.params in
  let acc = v.expr v acc lam.body in
  Option.fold ~none:acc ~some:(v.ty v acc) lam.ret_ty

let visit_letdef (v : 'acc visitor) (acc : 'acc) (ld : letdef) : 'acc =
  let acc = v.pattern v acc ld.pattern in
  let acc = v.expr v acc ld.value in
  Option.fold ~none:acc ~some:(v.ty v acc) ld.ty_annot

let rec visit_expr_children (v : 'acc visitor) (acc : 'acc) (e : expr) : 'acc =
  match e.expr_desc with
  | Exp_Constant _ | Exp_Ident _ | Exp_Continue -> acc
  | Exp_Tuple { elements } -> List.fold_left (v.expr v) acc elements
  | Exp_Record { fields } ->
      List.fold_left (fun a f -> v.expr v a f.field_value) acc fields
  | Exp_VariantConstructor { arg; _ } ->
      Option.fold ~none:acc ~some:(v.expr v acc) arg
  | Exp_Array { elements; size; _ } ->
      let acc = List.fold_left (v.expr v) acc elements in
      v.expr v acc size
  | Exp_Lambda lam -> visit_lambda v acc lam
  | Exp_Apply { closure_fun; args } ->
      let acc = v.expr v acc closure_fun in
      List.fold_left (v.expr v) acc args
  | Exp_Let ld -> visit_letdef v acc ld
  | Exp_If { condition; then_branch; else_branch } ->
      let acc = v.expr v acc condition in
      let acc = v.expr v acc then_branch in
      Option.fold ~none:acc ~some:(v.expr v acc) else_branch
  | Exp_While { condition; body } ->
      let acc = v.expr v acc condition in
      v.expr v acc body
  | Exp_Loop { condition } -> v.expr v acc condition
  | Exp_Break { value } | Exp_Return { value } ->
      Option.fold ~none:acc ~some:(v.expr v acc) value
  | Exp_Seq { exprs } -> List.fold_left (v.expr v) acc exprs
  | Exp_Match { expr = scrutinee; cases } ->
      let acc = v.expr v acc scrutinee in
      List.fold_left (v.pattern_case v) acc cases
  | Exp_Field { record; _ } -> v.expr v acc record
  | Exp_FieldSet { record; value; _ } ->
      let acc = v.expr v acc record in
      v.expr v acc value

let visit_pattern_case_children (v : 'acc visitor) (acc : 'acc)
    (c : pattern_case) : 'acc =
  let acc = v.pattern v acc c.pattern in
  let acc = Option.fold ~none:acc ~some:(v.expr v acc) c.when_condition in
  v.expr v acc c.body

let visit_ty_decl (v : 'acc visitor) (acc : 'acc) (td : ty_decl) : 'acc =
  match td.def with
  | Tydef_Alias ty -> v.ty v acc ty
  | Tydef_Record fields ->
      List.fold_left (fun a f -> v.ty v a f.field_ty) acc fields
  | Tydef_Variant ctors ->
      List.fold_left
        (fun a c ->
          match c.arg with
          | None -> a
          | Some (Constr_ty t) -> v.ty v a t
          | Some (Constr_record fields) ->
              List.fold_left (fun a f -> v.ty v a f.field_ty) a fields)
        acc ctors
  | Tydef_Abstract -> acc

let visit_signature_item_children (v : 'acc visitor) (acc : 'acc)
    (s : signature_item) : 'acc =
  match s.signature_item_desc with
  | Sig_Value { ty; _ } -> v.ty v acc ty
  | Sig_External { ty; _ } -> v.ty v acc ty
  | Sig_Type td -> visit_ty_decl v acc td
  | Sig_ModuleSignature ms -> v.module_signature v acc ms

let visit_module_signature_children (v : 'acc visitor) (acc : 'acc)
    (ms : module_signature) : 'acc =
  List.fold_left (v.signature_item v) acc ms.signature_items

let visit_structure_item_children (v : 'acc visitor) (acc : 'acc)
    (s : structure_item) : 'acc =
  match s.structure_item_desc with
  | Str_Let ld -> visit_letdef v acc ld
  | Str_External { ty; _ } -> v.ty v acc ty
  | Str_Type td -> visit_ty_decl v acc td
  | Str_ModuleStructure ms -> v.module_structure v acc ms
  | Str_ModuleSignature ms -> v.module_signature v acc ms

let visit_module_structure_children (v : 'acc visitor) (acc : 'acc)
    (ms : module_structure) : 'acc =
  List.fold_left (v.structure_item v) acc ms.structure_items

let default_ty (v : 'acc visitor) (acc : 'acc) (ty : ty) : 'acc =
  visit_ty_children v acc ty

let default_expr (v : 'acc visitor) (acc : 'acc) (e : expr) : 'acc =
  visit_expr_children v acc e

let default_pattern (v : 'acc visitor) (acc : 'acc) (p : pattern) : 'acc =
  visit_pattern_children v acc p

let default_pattern_case (v : 'acc visitor) (acc : 'acc) (c : pattern_case) :
    'acc =
  visit_pattern_case_children v acc c

let default_structure_item (v : 'acc visitor) (acc : 'acc) (s : structure_item)
    : 'acc =
  visit_structure_item_children v acc s

let default_signature_item (v : 'acc visitor) (acc : 'acc) (s : signature_item)
    : 'acc =
  visit_signature_item_children v acc s

let default_module_signature (v : 'acc visitor) (acc : 'acc)
    (ms : module_signature) : 'acc =
  visit_module_signature_children v acc ms

let default_module_structure (v : 'acc visitor) (acc : 'acc)
    (ms : module_structure) : 'acc =
  visit_module_structure_children v acc ms

let identity_visitor : 'acc visitor =
  {
    ty = default_ty;
    expr = default_expr;
    pattern = default_pattern;
    pattern_case = default_pattern_case;
    structure_item = default_structure_item;
    signature_item = default_signature_item;
    module_signature = default_module_signature;
    module_structure = default_module_structure;
  }

let default_visitor = identity_visitor

let visit_expr (v : 'acc visitor) (acc : 'acc) (e : expr) : 'acc =
  v.expr v acc e

let visit_pattern (v : 'acc visitor) (acc : 'acc) (p : pattern) : 'acc =
  v.pattern v acc p

let visit_ty (v : 'acc visitor) (acc : 'acc) (ty : ty) : 'acc = v.ty v acc ty

let visit_pattern_case (v : 'acc visitor) (acc : 'acc) (c : pattern_case) : 'acc
    =
  v.pattern_case v acc c

let visit_structure_item (v : 'acc visitor) (acc : 'acc) (s : structure_item) :
    'acc =
  v.structure_item v acc s

let visit_program (v : 'acc visitor) (acc : 'acc) (prog : structure_item list) :
    'acc =
  List.fold_left (v.structure_item v) acc prog

let collect_idents (prog : structure_item list) : string list =
  let visitor =
    {
      default_visitor with
      expr =
        (fun v acc e ->
          let acc =
            match e.expr_desc with
            | Exp_Ident { name; _ } -> name :: acc
            | _ -> acc
          in
          visit_expr_children v acc e);
    }
  in
  visit_program visitor [] prog

let collect_function_names (prog : structure_item list) : string list =
  let visitor =
    {
      default_visitor with
      structure_item =
        (fun v acc s ->
          let acc =
            match s.structure_item_desc with
            | Str_Let
                { let_kind = LetFun; pattern = { node = Pat_Ident id; _ }; _ }
              ->
                id.name :: acc
            | _ -> acc
          in
          visit_structure_item_children v acc s);
    }
  in
  visit_program visitor [] prog

let collect_type_defs (prog : structure_item list) : (string * ty_decl) list =
  let visitor =
    {
      default_visitor with
      structure_item =
        (fun v acc s ->
          let acc =
            match s.structure_item_desc with
            | Str_Type td -> (td.name.name, td) :: acc
            | _ -> acc
          in
          visit_structure_item_children v acc s);
    }
  in
  visit_program visitor [] prog

let count_expr_nodes (prog : structure_item list) : int =
  let visitor =
    {
      default_visitor with
      expr =
        (fun v acc e ->
          let acc = acc + 1 in
          visit_expr_children v acc e);
    }
  in
  visit_program visitor 0 prog

let collect_pattern_vars (p : pattern) : string list =
  let visitor =
    {
      default_visitor with
      pattern =
        (fun v acc p ->
          let acc =
            match p.node with Pat_Ident x -> x.name :: acc | _ -> acc
          in
          visit_pattern_children v acc p);
    }
  in
  visit_pattern visitor [] p
