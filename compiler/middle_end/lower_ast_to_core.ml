open Syli_typing.Typed_ast
open Syli_core.Core_ast
module Typed_ast = Syli_typing.Typed_ast
open Syli_common

exception Desugar_error of string

type env = {
  current_path : string list;
  bind_subst : string StringMap.t;
  type_subst : string StringMap.t;
  toplevel_last_ids : IntSet.t;
  letbind_inc_id : int ref;
}

let string_of_loc (loc : Typed_ast.location) : string =
  Printf.sprintf "%s:%d-%d" loc.filename loc.start_pos loc.end_pos

let error_at (loc : Typed_ast.location) (msg : string) : 'a =
  raise (Desugar_error (Printf.sprintf "%s: %s" (string_of_loc loc) msg))

let toplevel_name (env : env) (name : string) : string =
  match env.current_path with
  | [] -> name
  | path -> String.concat "." (path @ [ name ])

let qualify_name (env : env) (name : string) : string =
  match StringMap.find_opt name env.bind_subst with
  | Some qname -> qname
  | None ->
      raise
        (Desugar_error
           (Printf.sprintf "Name %s not found in substitution map" name))

let qualify_type_name (env : env) (name : string) : string =
  match StringMap.find_opt name env.type_subst with
  | Some qname -> qname
  | None ->
      raise
        (Desugar_error
           (Printf.sprintf "Type %s not found in type substitution map" name))

let letbind_rename (env : env) (name : string) (id : int) : string =
  if not @@ IntSet.mem id env.toplevel_last_ids then
    let _ = incr env.letbind_inc_id in
    "sy" ^ string_of_int !(env.letbind_inc_id) ^ "_" ^ name
  else name

let rec desugar_ty env (t : Typed_ast.ty) : ty =
  let ty_desc =
    match t.ty_desc with
    | TTy_Var v -> CTy_Var v
    | TTy_Any -> CTy_Var (-1)
    | TTy_Constant c ->
        CTy_Constant
          (match c with
          | TTy_Int8 -> CTy_Int8
          | TTy_Int16 -> CTy_Int16
          | TTy_Int32 -> CTy_Int32
          | TTy_Int64 -> CTy_Int64
          | TTy_UInt8 -> CTy_UInt8
          | TTy_UInt16 -> CTy_UInt16
          | TTy_UInt32 -> CTy_UInt32
          | TTy_UInt64 -> CTy_UInt64
          | TTy_Bool -> CTy_Bool
          | TTy_Unit -> CTy_Unit
          | TTy_F32 -> CTy_F32
          | TTy_F64 -> CTy_F64
          | TTy_String -> CTy_String
          | TTy_Char -> CTy_Char)
    | TTy_Arrow (arg, ret) -> CTy_Arrow (desugar_ty env arg, desugar_ty env ret)
    | TTy_Tuple elems -> CTy_Tuple (List.map (desugar_ty env) elems)
    | TTy_Array elem -> CTy_Array (desugar_ty env elem)
    | TTy_Defined d ->
        CTy_Defined
          {
            name =
              {
                name = qualify_type_name env d.name.name;
                path = env_path_of_ident d.name;
                id = d.name.id;
                is_operator = d.name.is_operator;
              };
            args = List.map (desugar_ty env) d.args;
          }
  in
  { ty_desc }

and env_path_of_ident (id : Typed_ast.ident) : string list = id.path

let hash_index (name : string) : int = abs (Hashtbl.hash name)

let rec desugar_pattern (p : Typed_ast.pattern) : pattern =
  let id = p.id in
  let node =
    match p.pattern_desc with
    | TPat_Unit -> Pat_Unit
    | TPat_BoolLit s -> Pat_BoolLit s
    | TPat_IntLit s -> Pat_IntLit s
    | TPat_FloatLit s -> Pat_FloatLit s
    | TPat_CharLit s -> Pat_CharLit s
    | TPat_StringLit s -> Pat_StringLit s
    | TPat_Ident name ->
        Pat_Ident
          {
            name = name.name;
            path = name.path;
            id = name.id;
            is_operator = name.is_operator;
          }
    | TPat_Tuple { elements } ->
        error_at p.loc "tuple pattern is not lowered to core yet"
    | TPat_Record { fields } ->
        Pat_Record
          (List.map
             (fun (f : Typed_ast.pattern_record_field) ->
               {
                 name =
                   {
                     name = f.name.name;
                     path = f.name.path;
                     id = f.name.id;
                     is_operator = f.name.is_operator;
                   };
                 pattern = Option.map desugar_pattern f.pattern;
               })
             fields)
    | TPat_Constructor { ident; pattern } ->
        Pat_Constructor
          {
            tag = hash_index ident;
            pattern = Option.map desugar_pattern pattern;
          }
    | TPat_Any -> Pat_Any
  in
  { id; node }

let desugar_lambda_params (env : env) (params : Typed_ast.param list) :
    ident list * env =
  let idents, param_substs =
    List.split
      (List.filter_map
         (fun (p : Typed_ast.param) ->
           match p.pattern.pattern_desc with
           | TPat_Ident name ->
               Some
                 ( {
                     name = name.name;
                     path = name.path;
                     id = p.pattern.id;
                     is_operator = name.is_operator;
                   },
                   (name.name, name.name) )
           | TPat_Unit -> None
           | _ -> error_at p.loc "lambda parameter must desugar to identifier")
         params)
  in
  let env' =
    {
      env with
      bind_subst =
        List.fold_left
          (fun s (n, q) -> StringMap.add n q s)
          env.bind_subst param_substs;
    }
  in
  (idents, env')

let rec desugar_expr (env : env) (e : Typed_ast.expr) : expr * env =
  let ty = desugar_ty env e.ty in
  let node, env' =
    match e.expr_desc with
    | TExp_Constant c ->
        ( CExp_Constant
            (match c.constant_desc with
            | TConst_Unit -> CConst_Unit
            | TConst_BoolLit s -> CConst_BoolLit s
            | TConst_IntLit s -> CConst_IntLit s
            | TConst_FloatLit s -> CConst_FloatLit s
            | TConst_CharLit s -> CConst_CharLit s
            | TConst_StringLit s -> CConst_StringLit s),
          env )
    | TExp_Ident i ->
        ( CExp_Ident
            {
              name = qualify_name env i.name;
              path = i.path;
              id = i.id;
              is_operator = i.is_operator;
            },
          env )
    | TExp_Tuple _ ->
        error_at e.loc "tuple expressions are not lowered to Core yet"
    | TExp_Record { fields } ->
        let lowered_fields =
          fields
          |> List.mapi (fun i (f : Typed_ast.record_field) ->
              {
                field_idx = i;
                field_ty = desugar_ty env f.field_value.ty;
                field_value = fst (desugar_expr env f.field_value);
              })
        in
        (CExp_Record lowered_fields, env)
    | TExp_VariantConstructor { name; arg } ->
        let tag = hash_index name.name in
        ( CExp_VariantConstructor
            { tag; arg = Option.map (fun a -> fst (desugar_expr env a)) arg },
          env )
    | TExp_Array { element_ty; elements; size } ->
        ( CExp_Array
            {
              element_ty = desugar_ty env element_ty;
              elements = List.map (fun a -> fst (desugar_expr env a)) elements;
              size = fst (desugar_expr env size);
            },
          env )
    | TExp_Lambda l ->
        let l = (l : Typed_ast.lambda) in
        let params, env_params = desugar_lambda_params env l.params in
        let ret_ty =
          match l.ret_ty with
          | Some rt -> desugar_ty env rt
          | None -> desugar_ty env l.body.ty
        in
        ( CExp_Lambda
            { params; body = fst (desugar_expr env_params l.body); ret_ty },
          env )
    | TExp_Apply { closure_fun; args } ->
        let args =
          List.filter_map
            (fun a ->
              match a.expr_desc with
              | TExp_Constant { constant_desc = TConst_Unit; _ } -> None
              | _ -> Some (fst (desugar_expr env a)))
            args
        in
        ( CExp_Apply { closure_fun = fst (desugar_expr env closure_fun); args },
          env )
    | TExp_Let l ->
        let name =
          match l.pattern.pattern_desc with
          | TPat_Ident name -> name
          | _ ->
              error_at l.loc "the pattern should be desugared to an identifier"
        in
        let qualified_name = letbind_rename env name.name name.id in
        let new_bind_subst =
          StringMap.add name.name qualified_name env.bind_subst
        in
        let value_env =
          match l.rec_flag with
          | TRecursive -> { env with bind_subst = new_bind_subst }
          | TNonRecursive -> env
        in
        ( CExp_Let
            {
              rec_flag =
                (match l.rec_flag with
                | TRecursive -> CRecursive
                | TNonRecursive -> CNonRecursive);
              name =
                {
                  name = qualified_name;
                  path = name.path;
                  id = l.pattern.id;
                  is_operator = name.is_operator;
                };
              value = fst (desugar_expr value_env l.value);
            },
          { env with bind_subst = new_bind_subst } )
    | TExp_FieldSet { record; field_name; value } ->
        let record_e = fst (desugar_expr env record) in
        let value_e = fst (desugar_expr env value) in
        let field_idx = Int.abs field_name.id in
        (CExp_FieldSet { record = record_e; field_idx; value = value_e }, env)
    | TExp_If { condition; then_branch; else_branch } ->
        ( CExp_If
            {
              condition = fst (desugar_expr env condition);
              then_branch = fst (desugar_expr env then_branch);
              else_branch =
                Option.map (fun e -> fst (desugar_expr env e)) else_branch;
            },
          env )
    | TExp_While { condition; body } ->
        ( CExp_Loop
            {
              id = e.id;
              node =
                CExp_If
                  {
                    condition = fst (desugar_expr env condition);
                    then_branch =
                      {
                        id = body.id;
                        node =
                          CExp_Seq
                            [
                              fst (desugar_expr env body);
                              {
                                id = body.id;
                                node = CExp_Continue;
                                ty = desugar_ty env body.ty;
                              };
                            ];
                        ty = desugar_ty env body.ty;
                      };
                    else_branch =
                      Some
                        {
                          id = e.id;
                          node = CExp_Break None;
                          ty = desugar_ty env e.ty;
                        };
                  };
              ty = desugar_ty env e.ty;
            },
          env )
    | TExp_Loop { expr } -> (CExp_Loop (fst (desugar_expr env expr)), env)
    | TExp_Break { expr_opt } ->
        ( CExp_Break (Option.map (fun e -> fst (desugar_expr env e)) expr_opt),
          env )
    | TExp_Continue -> (CExp_Continue, env)
    | TExp_Return { expr_opt } ->
        ( CExp_Return (Option.map (fun e -> fst (desugar_expr env e)) expr_opt),
          env )
    | TExp_Seq { exprs } ->
        let exprs, final_env =
          List.fold_left
            (fun (acc, e) x ->
              let e', env' = desugar_expr e x in
              (e' :: acc, env'))
            ([], env) exprs
        in
        (CExp_Seq (List.rev exprs), final_env)
    | TExp_Match { expr = scrutinee; cases } ->
        let scrutinee' = fst (desugar_expr env scrutinee) in
        let cases' =
          List.map
            (fun (c : Typed_ast.pattern_case) ->
              {
                id = c.id;
                pattern = desugar_pattern c.pattern;
                when_condition =
                  Option.map
                    (fun w -> fst (desugar_expr env w))
                    c.when_condition;
                body = fst (desugar_expr env c.body);
              })
            cases
        in
        (CExp_Match { expr = scrutinee'; cases = cases' }, env)
    | TExp_Field { record; field_name } ->
        ( CExp_Field
            {
              record = fst (desugar_expr env record);
              field_idx = Int.abs field_name.id;
            },
          env )
  in
  ({ id = e.id; node; ty }, env')

let desugar_type_decl (env : env) (td : Typed_ast.ty_decl) : ty_decl =
  let def =
    match td.def with
    | TTydef_Alias t -> CTydef_Alias (desugar_ty env t)
    | TTydef_Variant ctors ->
        CTydef_Variant
          (ctors
          |> List.mapi (fun i (c : Typed_ast.variant_constructor_decl) ->
              {
                id = c.id;
                variant_tag = i;
                arg =
                  Option.map
                    (function
                      | Typed_ast.Constr_ty t -> Constr_ty (desugar_ty env t)
                      | Typed_ast.Constr_record fields ->
                          Constr_record
                            (List.mapi
                               (fun fi (f : Typed_ast.record_field_decl) ->
                                 {
                                   id = f.id;
                                   field_idx = fi;
                                   field_ty = desugar_ty env f.field_ty;
                                   field_mut =
                                     (match f.field_mut with
                                     | TMutable -> CMutable
                                     | TImmutable -> CImmutable);
                                 })
                               fields))
                    c.arg;
              }))
    | TTydef_Record fields ->
        CTydef_Record
          (fields
          |> List.mapi (fun i (f : Typed_ast.record_field_decl) ->
              {
                id = f.id;
                field_idx = i;
                field_ty = desugar_ty env f.field_ty;
                field_mut =
                  (match f.field_mut with
                  | TMutable -> CMutable
                  | TImmutable -> CImmutable);
              }))
    | TTydef_Abstract -> CTydef_Abstract
  in
  {
    id = td.id;
    name =
      {
        name = toplevel_name env td.name.name;
        path = td.name.path;
        id = td.name.id;
        is_operator = td.name.is_operator;
      };
    params = List.map (fun (p : Typed_ast.ident) -> p.name) td.params;
    def;
  }

let rec desugarize_structure_items (env : env)
    (items : Typed_ast.structure_item list) : structure_item list =
  let _, result =
    List.fold_left
      (fun (env, acc) (item : Typed_ast.structure_item) ->
        match item.structure_item_desc with
        | Typed_ast.TStr_Let ldef ->
            let name =
              match ldef.pattern.pattern_desc with
              | TPat_Ident n -> n
              | _ ->
                  error_at ldef.loc
                    "top-level let pattern must desugar to identifier"
            in
            let qname =
              toplevel_name env @@ letbind_rename env name.name name.id
            in
            let new_bind_subst = StringMap.add name.name qname env.bind_subst in
            let body_env =
              match ldef.rec_flag with
              | TRecursive -> { env with bind_subst = new_bind_subst }
              | TNonRecursive -> env
            in
            ( { env with bind_subst = new_bind_subst },
              {
                id = item.id;
                structure_item_desc =
                  CStr_Let
                    {
                      rec_flag =
                        (match ldef.rec_flag with
                        | TRecursive -> CRecursive
                        | TNonRecursive -> CNonRecursive);
                      name =
                        {
                          name = qname;
                          path = name.path;
                          id = ldef.pattern.id;
                          is_operator = name.is_operator;
                        };
                      value = fst (desugar_expr body_env ldef.value);
                      public = true;
                      (*TODO: should check the signature to decide*)
                    };
              }
              :: acc )
        | Typed_ast.TStr_External { fname; ty; external_fn } ->
            let env' =
              {
                env with
                bind_subst =
                  StringMap.add fname.name
                    (toplevel_name env fname.name)
                    env.bind_subst;
              }
            in
            ( env',
              {
                id = item.id;
                structure_item_desc =
                  CStr_External
                    {
                      fname =
                        {
                          name = qualify_name env' fname.name;
                          path = fname.path;
                          id = fname.id;
                          is_operator = fname.is_operator;
                        };
                      ty = desugar_ty env ty;
                      external_fn =
                        {
                          symbol = external_fn.symbol.name;
                          kind =
                            (match external_fn.kind with
                            | Typed_ast.Foreign -> Foreign
                            | Typed_ast.Primitive -> Primitive);
                          calling_convention = external_fn.calling_convention;
                        };
                    };
              }
              :: acc )
        | Typed_ast.TStr_Type td ->
            let qname = toplevel_name env td.name.name in
            let env' =
              {
                env with
                type_subst = StringMap.add td.name.name qname env.type_subst;
              }
            in
            ( env',
              {
                id = item.id;
                structure_item_desc = CStr_Type (desugar_type_decl env' td);
              }
              :: acc )
        | Typed_ast.TStr_ModuleStructure ms ->
            let env' =
              {
                current_path = env.current_path @ [ ms.name.name ];
                bind_subst = env.bind_subst;
                letbind_inc_id = env.letbind_inc_id;
                toplevel_last_ids = env.toplevel_last_ids;
                type_subst = env.type_subst;
              }
            in
            let items' = desugarize_structure_items env' ms.structure_items in
            (env, List.rev_append items' acc)
        | Typed_ast.TStr_ModuleSignature _ -> (env, acc))
      (env, []) items
  in
  List.rev result

let desugarize_module_structure (module_structure : Typed_ast.module_structure)
    (env : env) : program_core =
  {
    id = module_structure.id;
    name =
      {
        name = module_structure.name.name;
        path = module_structure.name.path;
        id = module_structure.name.id;
        is_operator = module_structure.name.is_operator;
      };
    structure_items =
      desugarize_structure_items env module_structure.structure_items;
  }

let prefix_syli = "syli"

let rec compute_toplevel_last_ids (items : Typed_ast.structure_item list) :
    IntSet.t =
  List.fold_left
    (fun acc (item : Typed_ast.structure_item) ->
      match item.structure_item_desc with
      | Typed_ast.TStr_Let ldef -> (
          match ldef.pattern.pattern_desc with
          | TPat_Ident name -> IntSet.add name.id acc
          | _ -> acc)
      | Typed_ast.TStr_ModuleStructure ms ->
          IntSet.union acc (compute_toplevel_last_ids ms.structure_items)
      | _ -> acc)
    IntSet.empty items

let desugarize_ast (program : Typed_ast.module_structure) : program_core =
  let root_env =
    {
      current_path = [ prefix_syli ^ program.name.name ];
      bind_subst = StringMap.empty;
      toplevel_last_ids = compute_toplevel_last_ids program.structure_items;
      letbind_inc_id = ref 0;
      type_subst = StringMap.empty;
    }
  in
  {
    id = 0;
    name =
      {
        name = program.name.name;
        path = program.name.path;
        id = program.name.id;
        is_operator = program.name.is_operator;
      };
    structure_items =
      desugarize_structure_items root_env program.structure_items;
  }

let lower program = desugarize_ast program
