(** Lowers Core AST types to CIR types.

    [Core_ast.ty] is converted to [Cir.ty]. Recursive variants are cut with
    [CR_Obj_Ptr] so the expansion stays finite.

    Each type declaration is carried together with its cyclicity property
    (computed by {!Pass_cyclic_analysis}): the whole-type property, the record
    body property and the per-constructor properties. Anonymous tuples/arrays
    are [Acyclic] when all their elements are, and [Unknown_cyclic_prop]
    otherwise. *)

open Syli_core.Core_ast
open Syli_ir.Cir
open Syli_common
module C = Syli_core.Core_ast
module I = Syli_ir.Cir

type type_entry = {
  decl : C.ty_decl;
  prop : I.cyclic_prop;
  record_prop : I.cyclic_prop;
  ctor_props : (int * I.cyclic_prop) list;
}

let mut_flag_of_core = function
  | CMutable -> I.Mutable
  | CImmutable -> I.Immutable

let rec get_args_ty (ty : C.ty) : C.ty list =
  match ty.ty_desc with
  | CTy_Arrow (arg, ret) -> arg :: get_args_ty ret
  | _ -> []

let rec get_return_ty (ty : C.ty) : C.ty =
  match ty.ty_desc with CTy_Arrow (_, ret) -> get_return_ty ret | _ -> ty

(** Canonical string key for a Core type, used to build materialized type names
    (e.g. [i64], [box:i64], [array:i64]). *)
let rec type_key (t : C.ty) : string =
  match t.ty_desc with
  | CTy_Var n -> Printf.sprintf "'%d" n
  | CTy_Constant c -> (
      match c with
      | CTy_Int64 -> "i64"
      | CTy_Int32 -> "i32"
      | CTy_Int16 -> "i16"
      | CTy_Int8 -> "i8"
      | CTy_UInt64 -> "u64"
      | CTy_UInt32 -> "u32"
      | CTy_UInt16 -> "u16"
      | CTy_UInt8 -> "u8"
      | CTy_Unit -> "unit"
      | CTy_Bool -> "bool"
      | CTy_F32 -> "f32"
      | CTy_F64 -> "f64"
      | CTy_String -> "string"
      | CTy_Char -> "char")
  | CTy_Arrow (a, b) -> Printf.sprintf "(%s->%s)" (type_key a) (type_key b)
  | CTy_Tuple ts -> "(" ^ String.concat "," (List.map type_key ts) ^ ")"
  | CTy_Array t -> "array:" ^ type_key t
  | CTy_Defined { name; args } -> materialized_name name.name args

(** Materialized name of [name] applied to [args]: the bare [name] when there
    are no arguments, otherwise [name:arg1:arg2...] (colon-joined). *)
and materialized_name (name : string) (args : C.ty list) : string =
  if args = [] then name
  else name ^ ":" ^ String.concat ":" (List.map type_key args)

(** An IR type that carries no reference and can never reach a cyclic object:
    constants, and objects already classified [Acyclic]. *)
let is_acyclic_ir (t : I.ir_type) : bool =
  match t with
  | I.CR_Obj { cyclic_prop = I.Acyclic; _ } -> true
  | I.CR_Bool | I.CR_I64 | I.CR_I32 | I.CR_I16 | I.CR_I8 | I.CR_U64 | I.CR_U32
  | I.CR_U16 | I.CR_U8 | I.CR_F32 | I.CR_F64 | I.CR_Char | I.CR_String
  | I.CR_Void ->
      true
  | I.CR_FnPtr | I.CR_Obj_Ptr | I.CR_GenericTyp _ | I.CR_Arrow _ | I.CR_Obj _ ->
      false

let mk_ir_ty (type_defs : type_entry StringMap.t) (cty : C.ty) : I.ty =
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
        (* A tuple pointing exclusively at acyclic elements is acyclic. *)
        let prop =
          if List.for_all (fun f -> is_acyclic_ir f.field_ty.I.ir_type) fields
          then I.Acyclic
          else I.Unknown_cyclic_prop
        in
        I.CR_Obj
          {
            named = None;
            obj_kind = I.CR_Record_kind { fields };
            tag_variant = None;
            cyclic_prop = prop;
          }
    | CTy_Array elem ->
        let element_ir = go visited elem in
        let prop =
          if is_acyclic_ir element_ir then I.Acyclic else I.Unknown_cyclic_prop
        in
        I.CR_Obj
          {
            named = None;
            obj_kind =
              I.CR_Array_kind
                { element_ty = { I.id = fresh_id (); I.ir_type = element_ir } };
            tag_variant = None;
            cyclic_prop = prop;
          }
    | CTy_Defined { name; args } -> (
        let key = materialized_name name.name args in
        match StringMap.find_opt key type_defs with
        | Some { decl = { def = CTydef_Record decl_fields; _ }; record_prop; _ }
          ->
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
                named = Some key;
                obj_kind = I.CR_Record_kind { fields };
                tag_variant = None;
                cyclic_prop = record_prop;
              }
        | Some { decl = { def = CTydef_Alias t; _ }; _ } -> go visited t
        | Some { decl = { def = CTydef_Variant ctors; _ }; prop; _ } ->
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
            else if StringSet.mem key visited then
              (* [list] is already being expanded: keep it shallow *)
              I.CR_Obj_Ptr
            else
              let visited = StringSet.add key visited in
              let constructors =
                List.map
                  (fun (c : C.constructor_decl) ->
                    let fields = ctor_fields visited c.arg in
                    { I.tag = c.tag; fields })
                  ctors
              in
              I.CR_Obj
                {
                  named = Some key;
                  obj_kind = I.CR_Variant_kind { constructors };
                  tag_variant = None;
                  cyclic_prop = prop;
                }
        | Some { decl = { def = CTydef_Abstract; _ }; _ } ->
            failwith "Not yet supported"
        | None ->
            let msg = Printf.sprintf "Type %s not found" key in
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
