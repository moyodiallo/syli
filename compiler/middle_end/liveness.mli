(** Liveness analysis for reference-typed OIR variables (OR_Obj, OR_Obj_Ptr).
    Used by pass_ownership to insert OR_Release. *)

open Syli_common

type live_info_stmt = { live_before : IntSet.t; live_after : IntSet.t }

type live_info_block = {
  live_entry : IntSet.t;
  live_at_end : IntSet.t;
  dead_entry : IntSet.t;
}

type t = {
  stmts : live_info_stmt IntMap.t; (* statement.id *)
  blocks : live_info_block IntMap.t; (* block.id *)
}

val analyze : Syli_ir.Oir.function_oir -> t
