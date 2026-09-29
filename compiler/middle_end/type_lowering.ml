(** Lowers Core AST types to CIR types.

    [Core_ast.ty] is converted to [Cir.ty]. Recursive variants are cut with
    [CR_Obj_Ptr] so the expansion stays finite. *)

open Syli_core.Core_ast
open Syli_ir.Cir
open Syli_common
module C = Syli_core.Core_ast
module I = Syli_ir.Cir

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
  (* [visited] is the set of variant names currently being expanded, used to
     break cycles in recursive types. *)
  let rec go (visited : StringSet.t) (t : C.ty) : I.ir_type =
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
                I.ir_type = (if is_unit a then I.CR_I64 else go visited a);
              })
            (get_args_ty t)
        in
        let ret =
          { I.id = fresh_id (); I.ir_type = go visited (get_return_ty t) }
        in
        I.CR_Arrow (args, ret)
    | CTy_Tuple tys ->
        let fields =
          List.mapi
            (fun i t ->
              {
                I.field_idx = i;
                field_ty = { I.id = fresh_id (); I.ir_type = go visited t };
                field_mut = I.Immutable;
              })
            tys
        in
        I.CR_Obj
          {
            named = None;
            obj_kind = I.CR_Record_kind { fields };
            tag_variant = None;
            cyclic_prop = default_cyclic_prop;
          }
    | CTy_Array elem ->
        I.CR_Obj
          {
            named = None;
            obj_kind =
              I.CR_Array_kind
                {
                  element_ty =
                    { I.id = fresh_id (); I.ir_type = go visited elem };
                };
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
                    field_ty =
                      { I.id = fresh_id (); I.ir_type = go visited f.field_ty };
                    field_mut = mut_flag_of_core f.field_mut;
                  })
                decl_fields
            in
            I.CR_Obj
              {
                named = Some name.name;
                obj_kind = I.CR_Record_kind { fields };
                tag_variant = None;
                cyclic_prop = default_cyclic_prop;
              }
        | Some { def = CTydef_Alias t; _ } -> go visited t
        | Some { def = CTydef_Variant ctors; _ } ->
            (* Three lowerings, in order:
               - all-constant variant (e.g. [Red | Green | Blue]) -> the plain
                 integer tag;
               - variant with payloads -> a tagged heap object, where constant
                 constructors are tag-11 immediates and payload constructors are
                 tagged objects;
               - recursive variant -> the recursive occurrence is cut with
                 [CR_Obj_Ptr], the shallow pointer such a field already has at
                 runtime.

               For example, expanding

                   type list = Nil | Cons of (i64, list)

               would rebuild [list] from inside [Cons]'s payload forever. The
               [visited] set holds the variant names on the current expansion
               path, so the nested [list] becomes [CR_Obj_Ptr] and the walk
               terminates. *)
            if List.for_all (fun (c : C.constructor_decl) -> c.arg = None) ctors
            then I.CR_I64
            else if StringSet.mem name.name visited then
              (* [list] is already being expanded: keep it shallow *)
              I.CR_Obj_Ptr
            else
              let visited = StringSet.add name.name visited in
              let constructors =
                List.map
                  (fun (c : C.constructor_decl) ->
                    let fields = ctor_fields visited c.arg in
                    { I.tag = c.tag; fields })
                  ctors
              in
              I.CR_Obj
                {
                  named = Some name.name;
                  obj_kind = I.CR_Variant_kind { constructors };
                  tag_variant = None;
                  cyclic_prop = default_cyclic_prop;
                }
        | Some { def = CTydef_Abstract; _ } -> failwith "Not yet supported"
        | None ->
            let msg = Printf.sprintf "Type %s not found" name.name in
            failwith msg)
  (* Payload fields of one constructor; [visited] is forwarded so a recursive
     occurrence inside the payload is cut by [go]. *)
  and ctor_fields (visited : StringSet.t) (arg : C.constructor_arg option) :
      I.record_field_ty list =
    match arg with
    | None -> []
    | Some (Constr_ty { ty_desc = CTy_Tuple tys; _ }) ->
        List.mapi
          (fun i t ->
            {
              I.field_idx = i;
              field_ty = { I.id = fresh_id (); I.ir_type = go visited t };
              field_mut = I.Immutable;
            })
          tys
    | Some (Constr_record decl_fields) ->
        List.map
          (fun (f : C.record_field_ty) ->
            {
              I.field_idx = f.field_idx;
              field_ty =
                { I.id = fresh_id (); I.ir_type = go visited f.field_ty };
              field_mut = mut_flag_of_core f.field_mut;
            })
          decl_fields
    | Some (Constr_ty t) ->
        [
          {
            I.field_idx = 0;
            field_ty = { I.id = fresh_id (); I.ir_type = go visited t };
            field_mut = I.Immutable;
          };
        ]
  in
  { I.id = fresh_id (); ir_type = go StringSet.empty cty }
