(** This pass is about adding ownership annotation on the manipulation of the
    objects.

    It is the implementation of Pass 1 of doc/ownership.md *)

open Syli_ir.Oir
open Syli_common
open Liveness

let void_ty () = { id = fresh_id (); ir_type = OR_Void }

let is_ref_ty (t : ty) : bool =
  match t.ir_type with OR_Obj _ | OR_Obj_Ptr _ -> true | _ -> false

let mk_release (v : var) : statement =
  { id = fresh_id (); node = OR_Release { obj = v }; ty = void_ty () }

let mk_releases (vars : IntSet.t) var_map =
  IntSet.fold
    (fun vid acc ->
      match IntMap.find_opt vid var_map with
      | Some v -> mk_release v :: acc
      | None -> acc)
    vars []

let releases_of_dead_obj (live_map : live_info_stmt IntMap.t) (stmt_id : int)
    (skip : IntSet.t) (var_map : var IntMap.t) : statement list =
  match IntMap.find_opt stmt_id live_map with
  | Some info ->
      let dying =
        IntSet.diff (IntSet.diff info.live_before info.live_after) skip
      in
      IntSet.fold
        (fun vid acc ->
          match IntMap.find_opt vid var_map with
          | Some v -> mk_release v :: acc
          | None -> acc)
        dying []
  | None -> []

let build_var_map (fn : function_oir) : var IntMap.t =
  let add (map : var IntMap.t) (v : var) : var IntMap.t =
    IntMap.add v.id v map
  in
  let map = List.fold_left add IntMap.empty fn.params in
  let map = List.fold_left add map fn.locals in
  List.fold_left
    (fun map (b : block) ->
      List.fold_left
        (fun map (stmt : statement) ->
          match stmt.node with
          | OR_Assign { dst; _ }
          | OR_Object_create { dst; _ }
          | OR_Call { dst; _ } ->
              add map dst
          | OR_Object_set { obj; _ } -> add map obj
          | OR_Release { obj } -> add map obj
          | _ -> map)
        map b.statements)
    map fn.blocks

let annotate_function (fn : function_oir) : function_oir =
  let live_map = analyze fn in
  let var_map = build_var_map fn in
  let release_tmp_counter = ref 0 in
  let mk_get_release_tmp_value_statement (obj : var) (field_idx : operand)
      (value_ty : ty) =
    incr release_tmp_counter;
    let dst =
      {
        id = fresh_id ();
        name = "Sy_release_tmp_" ^ string_of_int !release_tmp_counter;
        ty = value_ty;
      }
    in
    let stmt =
      {
        id = fresh_id ();
        node =
          OR_Assign
            {
              dst;
              rvalue =
                {
                  id = fresh_id ();
                  node =
                    OR_Object_get
                      {
                        obj = OR_OVar obj;
                        field_idx;
                        value_ty;
                        ownership_get = OR_Ownership_transfer;
                      };
                  ty = value_ty;
                };
            };
        ty = value_ty;
      }
    in
    (dst, stmt)
  in
  let blocks =
    List.map
      (fun (block : block) ->
        let statements =
          List.concat_map
            (fun (stmt : statement) ->
              let stmts, no_release =
                match stmt.node with
                | OR_Assign
                    {
                      dst;
                      rvalue =
                        {
                          node =
                            OR_Object_get
                              {
                                obj = OR_OVar src;
                                field_idx;
                                value_ty;
                                ownership_get = _;
                              };
                          _;
                        } as rv_node;
                    } ->
                    let ownership_get =
                      if is_ref_ty dst.ty then
                        match IntMap.find_opt stmt.id live_map.stmts with
                        | Some info when IntSet.mem dst.id info.live_after ->
                            OR_Ownership_share
                        | _ -> OR_Ownership_borrow
                      else OR_Ownership_borrow
                    in
                    let rvalue =
                      {
                        rv_node with
                        node =
                          OR_Object_get
                            {
                              obj = OR_OVar src;
                              field_idx;
                              value_ty;
                              ownership_get;
                            };
                      }
                    in
                    ( [ { stmt with node = OR_Assign { dst; rvalue } } ],
                      IntSet.empty )
                | OR_Object_set ({ obj; field_idx; value; value_ty; _ } as os)
                  ->
                    if is_ref_ty value_ty then
                      let live_after, ownership_set =
                        match value with
                        | OR_OVar v ->
                            let live_after =
                              match IntMap.find_opt stmt.id live_map.stmts with
                              | Some info -> IntSet.mem v.id info.live_after
                              | None -> false
                            in
                            ( live_after,
                              if live_after then OR_Ownership_share
                              else OR_Ownership_own )
                        | _ -> (false, OR_Ownership_own)
                      in
                      let no_release =
                        if live_after then IntSet.empty
                        else
                          match value with
                          | OR_OVar v -> IntSet.singleton v.id
                          | _ -> IntSet.empty
                      in
                      let old_var, old_stmt =
                        mk_get_release_tmp_value_statement obj field_idx
                          value_ty
                      in
                      ( [
                          old_stmt;
                          mk_release old_var;
                          {
                            stmt with
                            node = OR_Object_set { os with ownership_set };
                          };
                        ],
                        no_release )
                    else
                      ( [
                          {
                            stmt with
                            node =
                              OR_Object_set
                                {
                                  os with
                                  ownership_set = OR_Ownership_constant;
                                };
                          };
                        ],
                        IntSet.empty )
                | OR_Call ({ args; _ } as c) ->
                    let args', no_release =
                      List.fold_left
                        (fun (acc_args, acc_nr) a ->
                          match a.operand with
                          | OR_OVar v when is_ref_ty v.ty ->
                              let live_after =
                                match
                                  IntMap.find_opt stmt.id live_map.stmts
                                with
                                | Some info -> IntSet.mem v.id info.live_after
                                | None -> false
                              in
                              let ownership_arg =
                                if live_after then OR_Ownership_borrow
                                else OR_Ownership_transfer
                              in
                              let acc_nr =
                                if live_after then acc_nr
                                else IntSet.add v.id acc_nr
                              in
                              ({ a with ownership_arg } :: acc_args, acc_nr)
                          | _ ->
                              ( { a with ownership_arg = OR_Ownership_constant }
                                :: acc_args,
                                acc_nr ))
                        ([], IntSet.empty) args
                    in
                    ( [
                        {
                          stmt with
                          node = OR_Call { c with args = List.rev args' };
                        };
                      ],
                      no_release )
                | OR_Store_global ({ value; _ } as store_global) ->
                    let live_after, ownership_store =
                      match value with
                      | OR_OVar v when is_ref_ty v.ty ->
                          let live_after =
                            match IntMap.find_opt stmt.id live_map.stmts with
                            | Some info -> IntSet.mem v.id info.live_after
                            | None -> false
                          in
                          ( live_after,
                            if live_after then OR_Ownership_share
                            else OR_Ownership_transfer )
                      | _ -> (true, OR_Ownership_constant)
                    in
                    let no_release =
                      if live_after then IntSet.empty
                      else
                        match value with
                        | OR_OVar v -> IntSet.singleton v.id
                        | _ -> IntSet.empty
                    in
                    ( [
                        {
                          stmt with
                          node =
                            OR_Store_global
                              { store_global with ownership_store };
                        };
                      ],
                      no_release )
                | OR_Assign
                    { rvalue = { node = OR_Move { src = OR_OVar v }; _ }; _ }
                  when is_ref_ty v.ty ->
                    ([ stmt ], IntSet.singleton v.id)
                | _ -> ([ stmt ], IntSet.empty)
              in
              stmts
              @ releases_of_dead_obj live_map.stmts stmt.id no_release var_map)
            block.statements
        in
        let terminator =
          match block.terminator.node with
          | OR_Return { operand = Some op; ownership_ret = _ } ->
              {
                block.terminator with
                node =
                  OR_Return
                    { operand = Some op; ownership_ret = OR_Ownership_own };
              }
          | _ -> block.terminator
        in
        let block_entry_dead =
          match IntMap.find_opt block.id live_map.blocks with
          | Some info -> info.dead_entry
          | None -> IntSet.empty
        in
        {
          block with
          statements = mk_releases block_entry_dead var_map @ statements;
          terminator;
        })
      fn.blocks
  in
  { fn with blocks }

let run (ctx : Pipeline_types.oir_ctx) : Pipeline_types.oir_ctx =
  {
    Pipeline_types.module_oir =
      {
        ctx.Pipeline_types.module_oir with
        functions =
          List.map annotate_function ctx.Pipeline_types.module_oir.functions;
      };
    apply_gen_functions =
      List.map annotate_function ctx.Pipeline_types.apply_gen_functions;
  }
