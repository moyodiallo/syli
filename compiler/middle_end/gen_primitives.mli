(** Constructs CIR wrapper functions for primitive operators.

    Each primitive declared at the source level (e.g.
    [primitive (+)  : i64 -> i64 -> i64 = "add"]) is turned into a CIR function
    that applies the corresponding CIR operation.*)

open Syli_common

val build :
  Syli_core.Core_ast.ty_decl StringMap.t ->
  fn_name:string ->
  symbol:string ->
  is_public:bool ->
  Syli_core.Core_ast.ty ->
  Syli_ir.Cir.function_cir
