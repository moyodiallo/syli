open Ast

let mk_loc startpos endpos =
  let start_pos = startpos.Lexing.pos_cnum in
  let end_pos = endpos.Lexing.pos_cnum in
  let filename = startpos.Lexing.pos_fname in
  { start_pos; end_pos; filename }

let mk_expr startpos endpos expr_desc : expr =
  { id = fresh_id (); expr_desc; loc = mk_loc startpos endpos }

let mk_ty startpos endpos ty_desc : ty =
  { id = fresh_id (); ty_desc; loc = mk_loc startpos endpos }

let mk_ident ?(is_operator = false) startpos endpos name : ident =
  {
    name;
    path = [];
    id = fresh_id ();
    loc = mk_loc startpos endpos;
    is_operator;
  }

let mk_structure_item startpos endpos structure_item_desc : structure_item =
  { id = fresh_id (); structure_item_desc; loc = mk_loc startpos endpos }

let mk_external_fn symbol ty kind : external_fn =
  { symbol; kind; calling_convention = None }

let check_operator (s : string) : bool =
  let is_op_char c =
    match c with
    | '=' | ':' | '!' | '&' | '|' | '>' | '<' | '+' | '-' | '*' | '%' | '/'
    | '^' | '~' ->
        true
    | _ -> false
  in
  s <> "" && String.for_all is_op_char s

let mk_signature_value startpos endpos name ty : signature_item_desc =
  Sig_Value { name; ty }

let mk_signature_external_value startpos endpos fname ty ext_ident :
    signature_item_desc =
  Sig_External { fname; ty; external_fn = ext_ident }

let mk_structure_external_value startpos endpos fname ty ext_ident :
    structure_item_desc =
  Str_External { fname; ty; external_fn = ext_ident }

let mk_module_signature startpos endpos name signature_items : module_signature
    =
  { id = fresh_id (); name; signature_items; loc = mk_loc startpos endpos }

let mk_pattern startpos endpos node : pattern =
  { id = fresh_id (); node; loc = mk_loc startpos endpos }

let mk_pattern_case startpos endpos pattern body when_opt : pattern_case =
  {
    id = fresh_id ();
    pattern;
    when_condition = when_opt;
    body;
    loc = mk_loc startpos endpos;
  }

let mk_lambda startpos endpos params body ret_ty_opt : lambda =
  { params; body; ret_ty = ret_ty_opt; loc = mk_loc startpos endpos }

let mk_param startpos endpos pattern param_ty_opt : param =
  { pattern; param_ty = param_ty_opt; loc = mk_loc startpos endpos }

let mk_record_field_expr startpos endpos field_name field_value : record_field =
  { id = fresh_id (); field_name; field_value; loc = mk_loc startpos endpos }

let mk_record_field_decl startpos endpos field_name field_ty field_mut :
    record_field_decl =
  {
    id = fresh_id ();
    field_name;
    field_ty;
    field_mut;
    loc = mk_loc startpos endpos;
  }

let mk_letdef startpos endpos let_kind pattern rec_flag value ty_annot : letdef
    =
  { let_kind; pattern; rec_flag; value; ty_annot; loc = mk_loc startpos endpos }

let mk_module_struct startpos endpos name structure_items : module_structure =
  { id = fresh_id (); name; structure_items; loc = mk_loc startpos endpos }

let mk_ty_decl startpos endpos name params def annotations : ty_decl =
  {
    id = fresh_id ();
    name;
    params;
    def;
    annotations;
    loc = mk_loc startpos endpos;
  }

let mk_constant startpos endpos constant_desc : constant =
  { id = fresh_id (); constant_desc; loc = mk_loc startpos endpos }

let mk_seq startpos endpos exprs =
  match exprs with
  | [] ->
      mk_expr startpos endpos
        (Exp_Constant (mk_constant startpos endpos Const_Unit))
  | [ e ] -> e
  | _ -> mk_expr startpos endpos (Exp_Seq { exprs })

let mk_constructor_decl startpos endpos name arg_ty_opt :
    variant_constructor_decl =
  { id = fresh_id (); name; arg = arg_ty_opt; loc = mk_loc startpos endpos }
