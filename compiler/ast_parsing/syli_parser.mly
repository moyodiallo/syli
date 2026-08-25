%{
  open Parser_helpers
  open Ast
%}

%token <string> INT
%token <string> IDENT UIDENT STRING
%token <string> CHAR
%token <string> FLOAT
%token <string> BOOL_VAL
%token TY_INT64 TY_INT32 TY_INT16 TY_INT8 TY_UINT64 TY_UINT32 TY_UINT16 TY_UINT8
%token TY_CHAR TY_BOOL TY_UNIT TY_STRING TY_ARRAY TY_F32 TY_F64
%token REC LET RETURN IF ELSE ELSEIF THEN FUN
%token VAL EXTERN SIGNATURE PRIMITIVE
%token WHILE LOOP DO END CONTINUE BREAK MATCH WITH TYPE OF MUTABLE
%token LPAREN RPAREN LBRACKET RBRACKET LBRACE RBRACE LBRACKET_BAR RBRACKET_BAR
%token COMMA SEMI COLON COLONEQ NEWLINE DOT ARROW
%token EQ PLUS MINUS STAR PERCENT SLASH TIMES
%token LT GT EQEQ BANGEQ LTEQ GTEQ AMPAMPAND NOT
%token BARBAR BAR CARET BANG UNDERSCORE
%token INDENT DEDENT EOF
%token MODULE
%token <int> SPACE

%start <Ast.module_structure> module_structure
%start <Ast.module_structure> module_file_sy
%start <Ast.module_signature> module_signature
%start <Ast.module_signature> module_file_syi

%type <Ast.expr> expr
%type <Ast.param list> params
%type <Ast.ty> ty
%type <Ast.ty_decl> type_def
%type <Ast.variant_constructor_decl> ty_constructor_decl

%nonassoc COLONEQ
%left BARBAR
%left AMPAMPAND
%left GT LT GTEQ LTEQ EQEQ BANGEQ
%left PLUS MINUS
%left TIMES PERCENT SLASH

%nonassoc UMINUS        /* highest precedence */
%nonassoc UPLUS         /* highest precedence */
%nonassoc BANG

%%

term_end:
  | DEDENT { () }
  | DEDENT END { () }

module_file_sy:
  | structure_items EOF
      {
        mk_module_struct $startpos $endpos (mk_ident $startpos $endpos "") $1
      }

module_file_syi:
  | signature_items EOF
      {
        mk_module_signature $startpos $endpos (mk_ident $startpos $endpos "")
          $1
      }

module_structure:
  | MODULE name = uident structure_items term_end
    { mk_module_struct $startpos $endpos name $3 }

module_signature:
  | MODULE name = uident signature_items term_end
    { mk_module_signature $startpos $endpos name $3 }


signature_items:
  | { [] }
  | signature { [$1] }
  | signature sep signature_items { $1 :: $3 }

signature:
  | VAL name = ident COLON value_ty = ty
    {
      mk_signature_item $startpos $endpos name value_ty
    }
  | EXTERN name = ident COLON value_ty = ty EQ ext_name = STRING
    {
      mk_signature_external_value $startpos $endpos name value_ty ext_name
    }
  | PRIMITIVE name = ident COLON value_ty = ty EQ prim_name = STRING
    {
      mk_signature_primitive_value $startpos $endpos name value_ty prim_name
    }

structure_items:
  | { [] }
  | structure { [$1] }
  | structure sep structure_items { $1 :: $3 }
  | structure structure_items     { $1 :: $2 }

structure:
  | structure_desc { mk_structure_item $startpos $endpos $1 }

structure_desc:
  | let_def { Str_Let $1 }
  | module_structure { Str_ModuleStruct $1 }
  | type_def { Str_TypeDef $1 }
  | SIGNATURE COLON NEWLINE INDENT signatures = signature_items term_end
    {
      Str_Signature signatures
    }
  | EXTERN name = ident COLON value_ty = ty EQ ext_name = STRING
    {
      mk_structure_external_value $startpos $endpos name value_ty ext_name
    }
  | PRIMITIVE name = ident COLON value_ty = ty EQ prim_name = STRING
    {
      mk_structure_primitive_value $startpos $endpos name value_ty prim_name
    }

let_def:
  | LET REC name = ident_fn_or_apply params = params eq_body = eq_let_body_expr
    {
      if params = [] then
        let (value, ty_opt) = eq_body in
        mk_letdef $startpos $endpos LetVal pat NonRecursive value ty_opt
      else
        let (value, ty_opt) = eq_body in
        let lambda = mk_lambda $startpos $endpos params value ty_opt in
        let pat = mk_pattern $startpos $endpos (Pat_Ident name) in
        let value_expr = mk_expr $startpos $endpos (Exp_Lambda lambda) in
        mk_letdef $startpos $endpos LetFun pat Recursive value_expr None
    }
  | LET name = ident_fn_or_apply params = params eq_body = eq_let_body_expr
    {
      if params = [] then
        let (value, ty_opt) = eq_body in
        mk_letdef $startpos $endpos LetVal pat NonRecursive value ty_opt
      else
        let (value, ty_opt) = eq_body in
        let lambda = mk_lambda $startpos $endpos params value ty_opt in
        let pat = mk_pattern $startpos $endpos (Pat_Ident name) in
        let value_expr = mk_expr $startpos $endpos (Exp_Lambda lambda) in
        mk_letdef $startpos $endpos LetFun pat NonRecursive value_expr None
    }

eq_let_body_expr:
  | EQ body_sequence { ($2, None) }
  | COLON ty = ty EQ body_sequence = body_sequence
    { (body_sequence, Some ty) }

lambda:
  | FUN params_lambda lambda_body
    { mk_lambda $startpos $endpos $2 (fst $3) (snd $3) }

params_lambda:
  | param_lambda           { [$1] }
  | param_lambda params    { $1 :: $2 }

param_lambda:
  | pattern { mk_param $startpos $endpos $1 None }
  | LPAREN pattern COLON ty RPAREN { mk_param $startpos $endpos $2 (Some $4) }

lambda_body:
  | ARROW expr          { ($2, None) }
  | COLON ty ARROW expr { ($4, Some $2) }

sep:
  | NEWLINE { () }

sequence:
  | sequence_expr   { $1 }
  | expr            { $1 }

sequence_expr:
  | NEWLINE INDENT sequence_exprs term_end { mk_seq $startpos $endpos $3 }

sequence_exprs:
  | expr                    { [$1] }
  | expr sep                { [$1] }
  | expr sep sequence_exprs { $1 :: $3 }
  | expr sequence_exprs     { $1 :: $2 }

body_sequence:
  | expr          { $1 }
  | sequence_expr { $1 }

elseif_chain:
  | { None }
  | ELSEIF expr = expr THEN cond_seq = body_sequence else_chain = elseif_chain
    { Some
        (mk_expr $startpos $endpos
            (Exp_If
              {
                cond = expr;
                then_branch = cond_seq;
                else_branch = else_chain}))
    }
  | ELSE body_sequence { Some $2 }

loop_body:
  | expr            { $1 }
  | sequence_expr   { $1 }

ty:
  | name = ident
    { mk_ty $startpos $endpos (Ty_Defined { name; args = [] }) }

  | TY_INT64  { mk_ty $startpos $endpos (Ty_Constant Ty_Int64) }
  | TY_INT32  { mk_ty $startpos $endpos (Ty_Constant Ty_Int32) }
  | TY_INT16  { mk_ty $startpos $endpos (Ty_Constant Ty_Int16) }
  | TY_INT8   { mk_ty $startpos $endpos (Ty_Constant Ty_Int8)  }

  | TY_UINT64 { mk_ty $startpos $endpos (Ty_Constant Ty_UInt64) }
  | TY_UINT32 { mk_ty $startpos $endpos (Ty_Constant Ty_UInt32) }
  | TY_UINT16 { mk_ty $startpos $endpos (Ty_Constant Ty_UInt16) }
  | TY_UINT8  { mk_ty $startpos $endpos (Ty_Constant Ty_UInt8) }

  | TY_F32    { mk_ty $startpos $endpos (Ty_Constant Ty_F32) }
  | TY_F64    { mk_ty $startpos $endpos (Ty_Constant Ty_F64) }

  | TY_CHAR   { mk_ty $startpos $endpos (Ty_Constant Ty_CharLit) }
  | TY_BOOL   { mk_ty $startpos $endpos (Ty_Constant Ty_Bool) }
  | TY_UNIT   { mk_ty $startpos $endpos (Ty_Constant Ty_Unit) }
  | TY_STRING { mk_ty $startpos $endpos (Ty_Constant Ty_String) }

  | ty TY_ARRAY { mk_ty $startpos $endpos (Ty_Array $1) }
  | ty_tuple    { mk_ty $startpos $endpos (Ty_Tuple $1) }
  | ty_arrow    { mk_ty $startpos $endpos $1 }

  | LPAREN ty RPAREN { $2 }

ty_tuple:
  | ty               { [$1] }
  | ty STAR ty_tuple { $1 :: $3 }

ty_arrow:
  | ty ARROW ty       { Ty_Arrow ($1, $3) }
  | ty ARROW ty_arrow { Ty_Arrow ($1, $3) }


record_field_ty:
  | field_name = ident COLON ty
    { mk_record_field_decl $startpos $endpos field_name $3 Immutable }
  | MUTABLE field_name = ident COLON ty
    { mk_record_field_decl $startpos $endpos field_name $4 Mutable }


record_field_ty_list:
  | field_desc = record_field_ty { [field_desc] }
  | field_desc = record_field_ty SEMI record_field_ty_list = record_field_ty_list
    { field_desc :: record_field_ty_list }

ty_constructor_decls:
  | ty_constructor_decl                           { [$1] }
  | ty_constructor_decl BAR ty_constructor_decls { $1 :: $3 }

ty_constructor_decl:
  | name = uident        { mk_constructor_decl $startpos $endpos name None }
  | name = uident OF ty  { mk_constructor_decl $startpos $endpos name (Some ( Constr_ty $3)) }
  | name = uident OF LBRACE record_ty = record_field_ty_list RBRACE
    { mk_constructor_decl $startpos $endpos name
        (Some (Constr_record record_ty)) }

type_def:
  | TYPE name = ident EQ constructors = ty_constructor_decls
    { mk_ty_decl $startpos $endpos name []
        (Tydef_Variant constructors)
        [] }
  | TYPE name = ident EQ  LBRACE record_ty = record_field_ty_list RBRACE
    { mk_ty_decl $startpos $endpos name []
        (Tydef_Record record_ty)
        [] }

param:
  | pattern
    { mk_param $startpos $endpos $1 None }
  | LPAREN pattern COLON ty RPAREN
    { mk_param $startpos $endpos $2 (Some $4) }

params:
  |               { [] }
  | param         { [$1] }
  | param params  { $1 :: $2 }

args:
  | atom_expr       { [$1] }
  | atom_expr args  { $1 :: $2 }

ident:
  | IDENT
    { let is_operator = check_operator $1 in
      mk_ident ~is_operator $startpos $endpos $1 }

ident_fn_or_apply:
  | LPAREN IDENT RPAREN { mk_ident ~is_operator:true $startpos $endpos $2 }
  | IDENT
    { if check_operator $1 then failwith "operator should be in ( ) like (op)"
      else mk_ident $startpos $endpos }

uident:
  | UIDENT { mk_ident $startpos $endpos $1 }

pattern_desc:
  | UNDERSCORE                          { Pat_Any }
  | INT                                 { Pat_IntLit $1 }
  | STRING                              { Pat_StringLit $1 }
  | CHAR                                { Pat_CharLit $1 }
  | FLOAT                               { Pat_FloatLit $1 }
  | BOOL_VAL                            { Pat_BoolLit $1 }
  | LPAREN RPAREN                       { Pat_Unit }
  | LPAREN pattern_tuple RPAREN       { Pat_Tuple { elements = $2} }
  | LBRACE record_pattern_list RBRACE { Pat_Record { fields = $2} }
  | name = uident pattern_desc
    { Pat_Constructor
        { name; pattern = Some (mk_pattern $startpos $endpos $2)} }
  | name = uident
    { Pat_Constructor { name; pattern = None} }
  | name = ident { Pat_Ident name }

pattern:
  | pattern_desc { mk_pattern $startpos $endpos $1 }

pattern_tuple:
  | pattern                     { [$1] }
  | pattern COMMA pattern_tuple { $1 :: $3 }

record_pattern_list:
  | field_pattern_desc                          { [$1] }
  | field_pattern_desc SEMI record_pattern_list { $1 :: $3 }

field_pattern_desc:
  | field_name = ident
    {
      { name = field_name; pattern = None; loc = mk_loc $startpos $endpos }
    }
  | field_name = ident EQ pattern
    {
      { name = field_name; pattern = Some $3; loc = mk_loc $startpos $endpos }
    }

ident_atomic:
  | id = ident { mk_expr $startpos $endpos (Exp_Ident id) }

uident_atomic:
  | id = uident
    { mk_expr $startpos $endpos
        (Exp_VariantConstructor { name = id; arg = None })
    }

pattern_case:
  | pattern ARROW body_sequence
    { mk_pattern_case $startpos $endpos $1 $3 None }

match_pattern:
  |                                         { [] }
  | pattern_case match_pattern              { $1 :: $2 }
  | BAR pattern_case match_pattern          { $2 :: $3 }
  | BAR pattern_case NEWLINE match_pattern  { $2 :: $4 }
  | pattern_case BAR match_pattern          { $1 :: $3 }

atom_expr:
  | LPAREN RPAREN
    { mk_constant $startpos $endpos Const_Unit
      |> fun c -> mk_expr $startpos $endpos (Exp_Constant c)}
  | BOOL_VAL
    { mk_constant $startpos $endpos (Const_BoolLit $1)
      |> fun c -> mk_expr $startpos $endpos (Exp_Constant c)}
  | INT
    { mk_constant $startpos $endpos (Const_IntLit $1)
      |> fun c -> mk_expr $startpos $endpos (Exp_Constant c)}
  | STRING
    { mk_constant $startpos $endpos (Const_StringLit $1)
      |> fun c -> mk_expr $startpos $endpos (Exp_Constant c)}
  | CHAR
    { mk_constant $startpos $endpos (Const_CharLit $1)
      |> fun c -> mk_expr $startpos $endpos (Exp_Constant c)}
  | FLOAT
    { mk_constant $startpos $endpos (Const_FloatLit $1)
      |> fun c -> mk_expr $startpos $endpos (Exp_Constant c)}
  | LPAREN expr RPAREN { $2 }
  | LPAREN tuple_expr RPAREN
    { mk_expr $startpos $endpos (Exp_Tuple { elements = tuple_expr })}
  | LBRACE record_fields_expr RBRACE
    { mk_expr $startpos $endpos (Exp_Record { fields = $2})}
  | expr LBRACKET_BAR expr RBRACKET_BAR
    { let closure = mk_ident ~is_operator:true "uindex" in
        Expr_Apply {closure_fun = closure; args = [$1; $3] }}
  | expr LBRACKET_BAR expr RBRACKET_BAR COLONEQ expr
    { let closure = mk_ident ~is_operator:true "uindex_get" in
        Expr_Apply {closure_fun = closure; args = [$1; $3; $6] }}
  | expr DOT IDENT
    { let ident = mk_ident $startpos $endpos $3 in
        Expr_Field {record = $1; field_name = ident }}
  | expr DOT IDENT COLONEQ expr
    { let ident = mk_ident $startpos $endpos $3 in
        Expr_FieldSet {record = $1; field_name = ident; value = $5 }}
  | NOT expr
    { let ident = mk_ident $startpos $endpos "not" in
        Expr_Apply { closure_fun = ident; args = [$2] }}
  | lambda        { mk_expr $startpos $endpos (Exp_Lambda $1) }
  | ident_atomic  { $1 }
  | uident_atomic { $1 }
  | operation     { $1 }
  | expr_variant  { $1 }
  | apply_expr    { $1 }

apply_expr:
  | ident_fn_or_apply exprs { Expr_Apply { closure_fun = $1; args = $2 } }
  | expr exprs              { Expr_Apply { closure_fun = $1; args = $2 } }

exprs:
  | expr        { [$1] }
  | expr exprs  { $1::$2 }

tuple_expr:
  | expr            { [$1] }
  | expr COMMA expr { $1::$3 }

expr_variant:
  | name = uident atom_expr
    { mk_expr $startpos $endpos
        (Exp_VariantConstructor { name; arg = Some $2 })
    }

infix_operation:
  | expr operator expr
    { let closure = mk_ident ~is_operator:true $startpos $endpos $2 in
      Expr_Apply {
          closure_fun closure; args = [$1,$3]
        }}

operation:
  | infix_operation { $1 }
  | MINUS expr %prec UMINUS
    { let closure = mk_ident ~is_operator:true "unegative" in
      Expr_Apply {closure_fun = closure; args = [$2] }
    }
  | PLUS expr %prec UPLUS
    { let closure = mk_ident ~is_operator:true "upositive" in
      Expr_Apply {closure_fun = closure; args = [$2] }
    }
  | BANG expr
    { let closure = mk_ident ~is_operator:true "!" in
      Expr_Apply {closure_fun = closure; args = [$2] }
    }

operator:
  (* = := ! *)
  | EQ
  | COLONEQ
  | BANG

  (* && || *)
  | AMPAMPAND
  | BARBAR

  (* > < >= <= == != *)
  | GT
  | LT
  | GTEQ
  | LTEQ
  | EQEQ
  | BANGEQ

  (* + - *)
  | PLUS
  | MINUS

  (* * % / *)
  | TIMES
  | PERCENT
  | SLASH

  | CARET

  { mk_ident ~is_operator:true $startpos $endpos $1}

expr:
  | atom_expr    { $1 }
  | let_def      { mk_expr $startpos $endpos (Exp_Let $1)}
  | IF expr THEN body_sequence elseif_chain
    { mk_expr $startpos $endpos
        (Exp_If { cond = $2; then_branch = $4; else_branch = $5})}
  | WHILE expr DO loop_body
    { mk_expr $startpos $endpos (Exp_While { cond = $2; body = $4})}
  | LOOP sequence
    { mk_expr $startpos $endpos (Exp_Loop { condition = $2})}
  | BREAK expr
    { mk_expr $startpos $endpos (Exp_Break { value = $2 })}
  | CONTINUE
    { mk_expr $startpos $endpos (Exp_Continue)}
  | RETURN expr
    { mk_expr $startpos $endpos (Exp_Return { value = $2})}
  | MATCH expr = expr WITH NEWLINE mpat = match_pattern
    { mk_expr $startpos $endpos (Exp_Match { expr; cases = mpat})}
  | MATCH expr = expr WITH mpat = match_pattern
    { mk_expr $startpos $endpos (Exp_Match { expr; cases = mpat})}

record_fields_expr:
  | { [] }
  | field_name = ident EQ expr
    { let field_name = (field_name : ident) in
      [mk_record_field_expr $startpos $endpos field_name $3]}
  | field_name = ident EQ expr SEMI record_fields_expr
    { let field_name = (field_name : ident) in
      mk_record_field_expr $startpos $endpos field_name $3 :: $5}

%%
