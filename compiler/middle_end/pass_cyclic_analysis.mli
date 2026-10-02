(** Cyclic analysis over Core AST type declarations.

    Classifies each type, record body and variant constructor as cyclic,
    scannable, acyclic or unknown, without traversing expressions. *)

open Syli_common

type t

val analyze : Syli_core.Core_ast.ty_decl StringMap.t -> t
(** Analyse a type-declaration map. *)

val type_prop : t -> string -> Syli_ir.Cir.cyclic_prop
(** Property of the nominal type node [name]. *)

val record_prop : t -> string -> Syli_ir.Cir.cyclic_prop
(** Property of the record body node of [name]. *)

val ctor_prop : t -> string -> int -> Syli_ir.Cir.cyclic_prop
(** Property of the constructor [tag] of variant type [name]. *)

val array_prop : t -> Syli_core.Core_ast.ty -> Syli_ir.Cir.cyclic_prop
(** Property of the array node whose element type is the given type. *)
