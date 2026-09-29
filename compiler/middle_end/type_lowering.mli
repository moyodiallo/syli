(** Lowers Core AST types to CIR types.

    [Core_ast.ty] is converted to [Cir.ty]. Recursive variants are cut with
    [CR_Obj_Ptr] so the expansion stays finite. *)

open Syli_common

val get_args_ty : Syli_core.Core_ast.ty -> Syli_core.Core_ast.ty list
val get_return_ty : Syli_core.Core_ast.ty -> Syli_core.Core_ast.ty

val mk_ir_ty :
  Syli_core.Core_ast.ty_decl StringMap.t ->
  Syli_core.Core_ast.ty ->
  Syli_ir.Cir.ty
