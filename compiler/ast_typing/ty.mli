(** This module provides type construction, comparison, unification, and
    printing utilities for the typed AST. *)

val mk_ty : Typed_ast.ty_desc -> Typed_ast.ty
(** Wraps a type descriptor into a typed AST type node. *)

val is_numeric_const_ty : Typed_ast.constant_ty -> bool
(** Returns [true] for numeric constant types (integers, floats, doubles). *)

val is_integer_const_ty : Typed_ast.constant_ty -> bool
(** Returns [true] for integer constant types (both signed and unsigned). *)

val ensure_numeric_ty : Typed_ast.ty -> unit
(** Raises [Type_error] if the type is not numeric (used in operator
    type-checking). *)

val ensure_integer_ty : Typed_ast.ty -> unit
(** Raises [Type_error] if the type is not an integer type (used in bitwise
    operator type-checking). *)

val equal_ty : Typed_ast.ty -> Typed_ast.ty -> bool
(** Structural equality check for two typed AST types (ignoring IDs and
    locations). *)

val occurs : int -> Typed_ast.ty -> bool
(** Occurs check for unification: returns [true] if the type variable ID appears
    anywhere in the type. *)

val unify : Subst.t -> Typed_ast.ty -> Typed_ast.ty -> Subst.t
(** Unifies two types, threading and extending the substitution. Raises
    [Type_error] if unification fails. *)

val apply_ty : Env.infer_ctx -> Typed_ast.ty -> Typed_ast.ty
(** Replaces all type variables in the type with their substituted values from
    the inference context. *)

val unify_into : Env.infer_ctx -> Typed_ast.ty -> Typed_ast.ty -> Env.infer_ctx
(** Unifies two types within an inference context. *)

val ty_vars : Typed_ast.ty -> int list
(** Collects all free type variable IDs referenced in the type. *)
