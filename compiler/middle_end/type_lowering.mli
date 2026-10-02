(** Lowers Core AST types to CIR types.

    [Core_ast.ty] is converted to [Cir.ty]. Recursive variants are cut with
    [CR_Obj_Ptr] so the expansion stays finite. *)

open Syli_common

type type_entry = {
  decl : Syli_core.Core_ast.ty_decl;
  prop : Syli_ir.Cir.cyclic_prop;  (** whole-type property *)
  record_prop : Syli_ir.Cir.cyclic_prop;  (** record body property *)
  ctor_props : (int * Syli_ir.Cir.cyclic_prop) list;
      (** per-constructor properties (tag -> property) *)
}
(** A type declaration together with its cyclicity properties. *)

val get_args_ty : Syli_core.Core_ast.ty -> Syli_core.Core_ast.ty list
val get_return_ty : Syli_core.Core_ast.ty -> Syli_core.Core_ast.ty

val type_key : Syli_core.Core_ast.ty -> string
(** Canonical string key for a Core type (e.g. [i64], [box:i64]). *)

val materialized_name : string -> Syli_core.Core_ast.ty list -> string
(** [materialized_name name args] is the bare [name] when [args] is empty, and
    [name:arg1:arg2...] (colon-joined) otherwise. Used to key materialized
    generic instantiations consistently in the analysis and in lowering. *)

val mk_ir_ty : type_entry StringMap.t -> Syli_core.Core_ast.ty -> Syli_ir.Cir.ty
