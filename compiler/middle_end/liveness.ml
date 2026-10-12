(** Liveness analysis for reference-typed OIR variables *)

open Syli_ir.Oir
open Syli_common
module Cfg = Syli_ir.Oir_cfg

type live_info_stmt = { live_before : IntSet.t; live_after : IntSet.t }

type live_info_block = {
  live_entry : IntSet.t;
  live_at_end : IntSet.t;
  dead_entry : IntSet.t;
}

type t = { stmts : live_info_stmt IntMap.t; blocks : live_info_block IntMap.t }

(* ── Helpers ──────────────────────────────────────────────────── *)

let is_ref_ir_type (t : ir_type) : bool =
  match t with OR_Obj _ | OR_Obj_Ptr | OR_String -> true | _ -> false

let is_ref_ty (t : ty) : bool = is_ref_ir_type t.ir_type

let vars_of_operand (op : operand) : IntSet.t =
  match op with
  | OR_OVar v when is_ref_ty v.ty -> IntSet.singleton v.id
  | _ -> IntSet.empty

let vars_of_rvalue (rv : rvalue) : IntSet.t =
  match rv.node with
  | OR_BinOp { lhs; rhs } ->
      IntSet.union (vars_of_operand lhs) (vars_of_operand rhs)
  | OR_UnOp { operand } -> vars_of_operand operand
  | OR_Object_get { obj; field_idx } ->
      IntSet.union (vars_of_operand obj) (vars_of_operand field_idx)
  | OR_Object_length { obj } -> vars_of_operand obj
  | OR_Object_get_tag { obj } -> vars_of_operand obj
  | OR_Cast { src } -> vars_of_operand src
  | OR_Move { src } -> vars_of_operand src
  | OR_Addr_fn _ -> IntSet.empty

let ref_use_of_stmt (stmt : statement) : IntSet.t =
  match stmt.node with
  | OR_Assign { rvalue; _ } -> vars_of_rvalue rvalue
  | OR_Object_set { obj; field_idx; value; _ } ->
      IntSet.union
        (vars_of_operand (OR_OVar obj))
        (IntSet.union (vars_of_operand field_idx) (vars_of_operand value))
  | OR_Object_create { size; _ } -> vars_of_operand size
  | OR_Call { args; _ } ->
      List.fold_left
        (fun s a -> IntSet.union s (vars_of_operand a.operand))
        IntSet.empty args
  | OR_Release { obj } -> IntSet.singleton obj.id
  | OR_Store_global { value } -> vars_of_operand value
  | OR_Nop | OR_GC_cycle -> IntSet.empty

let ref_def_of_stmt (stmt : statement) : IntSet.t =
  match stmt.node with
  | OR_Assign { dst; _ } when is_ref_ty dst.ty -> IntSet.singleton dst.id
  | OR_Object_create { dst; _ } when is_ref_ty dst.ty -> IntSet.singleton dst.id
  | OR_Call { dst; _ } when is_ref_ty dst.ty -> IntSet.singleton dst.id
  | _ -> IntSet.empty

let terminator_uses (term : terminator) : IntSet.t =
  match term.node with
  | OR_Return { operand = Some op; _ } -> vars_of_operand op
  | OR_CondBr { cond; _ } -> vars_of_operand (OR_OVar cond)
  | OR_Switch { scrutinee; _ } -> vars_of_operand (OR_OVar scrutinee)
  | OR_Return { operand = None; _ } | OR_Goto _ | OR_MatchFailure ->
      IntSet.empty

(* ── Main analysis ────────────────────────────────────────────── *)

let analyze (fn : function_oir) : t =
  let cfg = Cfg.build_cfg fn.blocks in
  let block_map = Cfg.build_block_map fn.blocks in
  let entry_id = fn.entry_block.id in
  let entry_params =
    List.fold_left
      (fun s (p : var) -> if is_ref_ty p.ty then IntSet.add p.id s else s)
      IntSet.empty fn.params
  in
  let live_before_stmt (live : IntSet.t) (stmt : statement) : IntSet.t =
    IntSet.union (ref_use_of_stmt stmt)
      (IntSet.diff live (ref_def_of_stmt stmt))
  in
  let live_at_block_entry (live_at_end : IntSet.t) (b : block) : IntSet.t =
    List.fold_left live_before_stmt live_at_end (List.rev b.statements)
  in
  let union_succ_entries (entries : IntSet.t IntMap.t) (block_id : int) :
      IntSet.t =
    List.fold_left
      (fun live sid ->
        match IntMap.find_opt sid entries with
        | Some info -> IntSet.union live info
        | None -> live)
      IntSet.empty
      (Cfg.get_succ cfg block_id)
  in
  let live_at_end_of (entries : IntSet.t IntMap.t) (b : block) : IntSet.t =
    IntSet.union
      (union_succ_entries entries b.id)
      (terminator_uses b.terminator)
  in
  (* Process blocks so that successors are visited before predecessors. *)
  let order = Cfg.compute_rpo cfg entry_id |> List.rev in
  (* Phase 1: fixpoint on per-block live_entry. The transfer is monotone
     (union-only), so iterating from empty converges for cyclic CFGs too. *)
  let rec fixpoint (entries : IntSet.t IntMap.t) : IntSet.t IntMap.t =
    let changed = ref false in
    let entries' =
      List.fold_left
        (fun acc block_id ->
          let b =
            try IntMap.find block_id block_map
            with Not_found -> failwith "liveness: block not found"
          in
          let live_at_first =
            live_at_block_entry (live_at_end_of entries b) b
          in
          let new_entry =
            if block_id = entry_id then IntSet.union entry_params live_at_first
            else live_at_first
          in
          let old =
            match IntMap.find_opt block_id entries with
            | Some s -> s
            | None -> IntSet.empty
          in
          if not (IntSet.equal old new_entry) then changed := true;
          IntMap.add block_id new_entry acc)
        entries order
    in
    if !changed then fixpoint entries' else entries'
  in
  let block_entries = fixpoint IntMap.empty in
  (* Phase 2: per-statement live ranges, using the fixpointed block entries. *)
  let result =
    List.fold_left
      (fun result (b : block) ->
        let _, result =
          List.fold_left
            (fun (live, map) (stmt : statement) ->
              let live_after = live in
              let live_before = live_before_stmt live stmt in
              (live_before, IntMap.add stmt.id { live_before; live_after } map))
            (live_at_end_of block_entries b, result)
            (List.rev b.statements)
        in
        result)
      IntMap.empty fn.blocks
  in
  (* Phase 3: dead_entry, using the fixpointed entries. *)
  let blocks =
    List.fold_left
      (fun blocks (block : block) ->
        let live_entry =
          match IntMap.find_opt block.id block_entries with
          | Some s -> s
          | None -> IntSet.empty
        in
        let dead_entry =
          if block.id = entry_id then
            match block.statements with
            | first :: _ -> (
                (*The first instruction reveals the liveness*)
                match IntMap.find_opt first.id result with
                | Some i -> IntSet.diff live_entry i.live_before
                | None -> live_entry)
            | [] -> IntSet.diff live_entry (live_at_end_of block_entries block)
          else
            let pred_ids = Cfg.get_pred cfg block.id in
            let dead_at_edge p_id =
              let p =
                try IntMap.find p_id block_map
                with Not_found -> failwith "liveness: pred block not found"
              in
              IntSet.diff (live_at_end_of block_entries p) live_entry
            in
            match pred_ids with
            | [] -> IntSet.empty
            | p :: rest ->
                List.fold_left
                  (fun acc p -> IntSet.inter acc (dead_at_edge p))
                  (dead_at_edge p) rest
        in
        IntMap.add block.id
          {
            live_entry;
            live_at_end = live_at_end_of block_entries block;
            dead_entry;
          }
          blocks)
      IntMap.empty fn.blocks
  in
  { stmts = result; blocks }
