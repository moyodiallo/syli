open Syli_ir.Oir
open Syli_common

let fresh_id = Syli_ir.Oir.fresh_id
let i64_ty : ty = { id = fresh_id (); ir_type = OR_I64 }
let void_ty : ty = { id = fresh_id (); ir_type = OR_Void }
let fn_ptr_ty : ty = { id = fresh_id (); ir_type = OR_FnPtr }
let obj_ptr_ty () : ty = { id = fresh_id (); ir_type = OR_Obj_Ptr }
let fresh_var name ty : var = { id = fresh_id (); name; ty }

let int_operand (value : int) : operand =
  OR_OConstant (OR_IntLit (string_of_int value), i64_ty)

let null_operand (ty : ty) : operand = OR_OConstant (OR_Null, ty)
let make_rvalue node ty : rvalue = { id = fresh_id (); node; ty }
let make_statement node ty : statement = { id = fresh_id (); node; ty }

let operand_ty (op : operand) : ty =
  match op with OR_OConstant (_, ty) -> ty | OR_OVar v -> v.ty

let is_ref_ty (t : ty) : bool =
  match t.ir_type with OR_Obj _ | OR_Obj_Ptr -> true | _ -> false

(** Trampoline functions load ref slot and scalar slot, so to avoid having same
    function with different loads we use this to differenciate the signature of
    the functions *)
let stored_sig_of_tys (tys : ty list) : string =
  if List.for_all (fun t -> not (is_ref_ty t)) tys then ""
  else
    "_k"
    ^ String.concat ""
        (List.map (fun t -> if is_ref_ty t then "o" else "i") tys)

(** Load the stored (capture) slots of a closure node. Object slots (ref-typed)
    are loaded as object reads so that the ownership memory model would not miss
    it. Scalar slots load as i64. *)
let stored_slot_loads (clos_var : var) (field_base : int) (tys : ty list) :
    var list * statement list =
  let items =
    tys
    |> List.mapi (fun idx ty ->
        if is_ref_ty ty then
          let obj_var =
            fresh_var ("Sy_oir_obj" ^ string_of_int idx) (obj_ptr_ty ())
          in
          let stmt =
            make_statement
              (OR_Assign
                 {
                   dst = obj_var;
                   rvalue =
                     make_rvalue
                       (OR_Object_get
                          {
                            obj = OR_OVar clos_var;
                            field_idx = int_operand (field_base + idx);
                            value_ty = obj_var.ty;
                            ownership_get = OR_Ownership_unknown;
                          })
                       obj_var.ty;
                 })
              obj_var.ty
          in
          (obj_var, stmt)
        else
          let imm_var = fresh_var ("Sy_oir_imm" ^ string_of_int idx) i64_ty in
          let stmt =
            make_statement
              (OR_Assign
                 {
                   dst = imm_var;
                   rvalue =
                     make_rvalue
                       (OR_Object_get
                          {
                            obj = OR_OVar clos_var;
                            field_idx = int_operand (field_base + idx);
                            value_ty = i64_ty;
                            ownership_get = OR_Ownership_unknown;
                          })
                       i64_ty;
                 })
              i64_ty
          in
          (imm_var, stmt))
  in
  List.split items

let rec type_key_of_ty (t : ty) : string =
  match t.ir_type with
  | OR_Bool -> "bool"
  | OR_I64 -> "i64"
  | OR_I32 -> "i32"
  | OR_I16 -> "i16"
  | OR_I8 -> "i8"
  | OR_U64 -> "u64"
  | OR_U32 -> "u32"
  | OR_U16 -> "u16"
  | OR_U8 -> "u8"
  | OR_F32 -> "f32"
  | OR_F64 -> "f64"
  | OR_FnPtr -> "fn_ptr"
  | OR_Char -> "char"
  | OR_String -> "str"
  | OR_Void -> "void"
  | OR_Obj_Ptr -> "obj_ptr"
  | OR_Obj { named; obj_kind; _ } -> (
      let name = match named with Some n -> n | None -> "" in
      match obj_kind with
      | OR_Record_kind { fields; _ } ->
          let field_keys =
            String.concat "_"
              (List.map (fun f -> type_key_of_ty f.field_ty) fields)
          in
          "obj_" ^ name ^ "_" ^ field_keys
      | OR_Array_kind { element_ty } ->
          "obj_" ^ name ^ "_" ^ type_key_of_ty element_ty)

(* Partial closure accum dispatch name: shared per (stored tys, args) *)
let partial_closure_accum_dispatch_name ~(stored_tys : ty list)
    ~(args_size : int) ~(ret_ty : ty) : string =
  Printf.sprintf "__partial_closure_accum.dispatch.clos%d%s_arg%d_ret_%s"
    (List.length stored_tys)
    (stored_sig_of_tys stored_tys)
    args_size (type_key_of_ty ret_ty)

(** Accumulator function for Partial_apply. Layout:
    - clos[0]=accum,
    - clos[1]=parent,
    - clos[2]=dispatch_edge,
    - clos[3+]=stored_args

    Params: (args_from_child..., clos, dispatch_id) Loads stored args from
    clos[3+], chains to parent[0] with dispatch_id passed through. *)
let build_partial_closure_accum_dispatch ~(stored_tys : ty list)
    ~(args_size : int) (result_ty : ty) : function_oir =
  let fn_name =
    partial_closure_accum_dispatch_name ~stored_tys ~args_size ~ret_ty:result_ty
  in
  let stored_args_size = List.length stored_tys in
  let clos_ty = obj_ptr_ty () in
  let clos_var = fresh_var "Sy_oir_clos" (obj_ptr_ty ()) in
  let dispatch_param = fresh_var "Sy_oir_dp_id" i64_ty in
  let arg_params =
    List.init args_size (fun i ->
        fresh_var ("Sy_oir_x" ^ string_of_int i) i64_ty)
  in
  let dispatch_clos_var = fresh_var "Sy_oir_dp_clos" i64_ty in
  let load_dispatch_stmt =
    make_statement
      (OR_Assign
         {
           dst = dispatch_clos_var;
           rvalue =
             make_rvalue
               (OR_Object_get
                  {
                    obj = OR_OVar clos_var;
                    field_idx = int_operand 1;
                    value_ty = i64_ty;
                    ownership_get = OR_Ownership_unknown;
                  })
               i64_ty;
         })
      i64_ty
  in
  let accum_dispatch_id_var = fresh_var "Sy_oir_accum_dp_id" i64_ty in
  let accum_dispatch_id_stmt =
    make_statement
      (OR_Assign
         {
           dst = accum_dispatch_id_var;
           rvalue =
             make_rvalue
               (OR_BinOp
                  {
                    op = OR_Add;
                    lhs = OR_OVar dispatch_param;
                    rhs = OR_OVar dispatch_clos_var;
                  })
               i64_ty;
         })
      i64_ty
  in
  let parent_clos_var = fresh_var "Sy_oir_p_clos" clos_ty in
  let load_parent_stmt =
    make_statement
      (OR_Assign
         {
           dst = parent_clos_var;
           rvalue =
             make_rvalue
               (OR_Object_get
                  {
                    obj = OR_OVar clos_var;
                    field_idx = int_operand 2;
                    value_ty = clos_ty;
                    ownership_get = OR_Ownership_unknown;
                  })
               clos_ty;
         })
      clos_ty
  in
  let parent_accum_var = fresh_var "Sy_oir_p_accum" fn_ptr_ty in
  let load_parent_accum_stmt =
    make_statement
      (OR_Assign
         {
           dst = parent_accum_var;
           rvalue =
             make_rvalue
               (OR_Object_get
                  {
                    obj = OR_OVar parent_clos_var;
                    field_idx = int_operand 0;
                    value_ty = fn_ptr_ty;
                    ownership_get = OR_Ownership_unknown;
                  })
               fn_ptr_ty;
         })
      fn_ptr_ty
  in
  let stored_vars, stored_load_stmts =
    List.init stored_args_size (fun i ->
        let sv = fresh_var ("Sy_oir_imm" ^ string_of_int i) i64_ty in
        let load_stmt =
          make_statement
            (OR_Assign
               {
                 dst = sv;
                 rvalue =
                   make_rvalue
                     (OR_Object_get
                        {
                          obj = OR_OVar clos_var;
                          field_idx = int_operand (3 + i);
                          value_ty = i64_ty;
                          ownership_get = OR_Ownership_unknown;
                        })
                     i64_ty;
               })
            i64_ty
        in
        (sv, load_stmt))
    |> List.split
  in
  let dst_var = fresh_var "Sy_oir_rst" result_ty in
  let return_term =
    {
      id = fresh_id ();
      node =
        OR_Return
          {
            operand = Some (OR_OVar dst_var);
            ownership_ret = OR_Ownership_unknown;
          };
    }
  in
  let call_stmt =
    make_statement
      (OR_Call
         {
           dst = dst_var;
           target = Direct_fn_ptr { ptr = parent_accum_var };
           args =
             List.map
               (fun v ->
                 { operand = OR_OVar v; ownership_arg = OR_Ownership_unknown })
               (stored_vars @ arg_params)
             @ [
                 {
                   operand = OR_OVar parent_clos_var;
                   ownership_arg = OR_Ownership_unknown;
                 };
                 {
                   operand = OR_OVar accum_dispatch_id_var;
                   ownership_arg = OR_Ownership_unknown;
                 };
               ];
         })
      dst_var.ty
  in
  let entry_block =
    {
      id = fresh_id ();
      label_id = 0;
      statements =
        [
          load_dispatch_stmt;
          accum_dispatch_id_stmt;
          load_parent_stmt;
          load_parent_accum_stmt;
        ]
        @ stored_load_stmts @ [ call_stmt ];
      terminator = return_term;
      pred_blocks = [];
      succ_blocks = [];
    }
  in
  let locals =
    [
      dst_var;
      dispatch_clos_var;
      dispatch_param;
      parent_clos_var;
      parent_accum_var;
    ]
    @ stored_vars
  in
  {
    id = fresh_id ();
    name = fn_name;
    params = arg_params @ [ clos_var; dispatch_param ];
    locals;
    entry_block;
    blocks = [ entry_block ];
    return_ty = result_ty;
    visibility = OR_Private;
    unit_param_indices = [];
  }

(* Partial closure accum name: shared per (stored tys, args) *)
let partial_closure_accum_name ~(stored_tys : ty list) ~(args_size : int)
    ~(ret_ty : ty) : string =
  Printf.sprintf "__partial_closure_accum.clos%d%s_arg%d_ret_%s"
    (List.length stored_tys)
    (stored_sig_of_tys stored_tys)
    args_size (type_key_of_ty ret_ty)

(** Accumulator function for Partial_apply. Layout:
    - clos[0]=accum,
    - clos[1]=parent,
    - clos[2+]=stored_args

    Params: (args_from_child..., clos, dispatch_id) Loads stored args from
    clos[3+], chains to parent[0]. *)
let build_partial_closure_accum ~(stored_tys : ty list) ~(args_size : int)
    (result_ty : ty) : function_oir =
  let fn_name =
    partial_closure_accum_name ~stored_tys ~args_size ~ret_ty:result_ty
  in
  let stored_args_size = List.length stored_tys in
  let clos_var = fresh_var "Sy_oir_clos" (obj_ptr_ty ()) in
  let dispatch_param = fresh_var "Sy_oir_dp_id" i64_ty in
  let closure_obj_ptr_ty = obj_ptr_ty () in
  let arg_params =
    List.init args_size (fun i ->
        fresh_var ("Sy_oir_x" ^ string_of_int i) i64_ty)
  in
  let parent_clos_var = fresh_var "Sy_oir_p_clos" closure_obj_ptr_ty in
  let load_parent_stmt =
    make_statement
      (OR_Assign
         {
           dst = parent_clos_var;
           rvalue =
             make_rvalue
               (OR_Object_get
                  {
                    obj = OR_OVar clos_var;
                    field_idx = int_operand 1;
                    value_ty = closure_obj_ptr_ty;
                    ownership_get = OR_Ownership_unknown;
                  })
               closure_obj_ptr_ty;
         })
      closure_obj_ptr_ty
  in
  let parent_accum_var = fresh_var "Sy_oir_p_accum" fn_ptr_ty in
  let load_parent_accum_stmt =
    make_statement
      (OR_Assign
         {
           dst = parent_accum_var;
           rvalue =
             make_rvalue
               (OR_Object_get
                  {
                    obj = OR_OVar parent_clos_var;
                    field_idx = int_operand 0;
                    value_ty = fn_ptr_ty;
                    ownership_get = OR_Ownership_unknown;
                  })
               fn_ptr_ty;
         })
      fn_ptr_ty
  in
  let stored_vars, stored_load_stmts =
    List.init stored_args_size (fun i ->
        let sv = fresh_var ("Sy_oir_imm" ^ string_of_int i) i64_ty in
        let load_stmt =
          make_statement
            (OR_Assign
               {
                 dst = sv;
                 rvalue =
                   make_rvalue
                     (OR_Object_get
                        {
                          obj = OR_OVar clos_var;
                          field_idx = int_operand (2 + i);
                          value_ty = i64_ty;
                          ownership_get = OR_Ownership_unknown;
                        })
                     i64_ty;
               })
            i64_ty
        in
        (sv, load_stmt))
    |> List.split
  in
  let dst_var = fresh_var "Sy_oir_rst" result_ty in
  let return_term =
    {
      id = fresh_id ();
      node =
        OR_Return
          {
            operand = Some (OR_OVar dst_var);
            ownership_ret = OR_Ownership_unknown;
          };
    }
  in
  let call_stmt =
    make_statement
      (OR_Call
         {
           dst = dst_var;
           target = Direct_fn_ptr { ptr = parent_accum_var };
           args =
             List.map
               (fun v ->
                 { operand = OR_OVar v; ownership_arg = OR_Ownership_unknown })
               (stored_vars @ arg_params)
             @ [
                 {
                   operand = OR_OVar parent_clos_var;
                   ownership_arg = OR_Ownership_unknown;
                 };
                 {
                   operand = OR_OVar dispatch_param;
                   ownership_arg = OR_Ownership_unknown;
                 };
               ];
         })
      dst_var.ty
  in
  let entry_block =
    {
      id = fresh_id ();
      label_id = 0;
      statements =
        [ load_parent_stmt; load_parent_accum_stmt ]
        @ stored_load_stmts @ [ call_stmt ];
      terminator = return_term;
      pred_blocks = [];
      succ_blocks = [];
    }
  in
  let locals =
    [ dst_var; dispatch_param; parent_clos_var; parent_accum_var ] @ stored_vars
  in
  {
    id = fresh_id ();
    name = fn_name;
    params = arg_params @ [ clos_var; dispatch_param ];
    locals;
    entry_block;
    blocks = [ entry_block ];
    return_ty = result_ty;
    visibility = OR_Private;
    unit_param_indices = [];
  }

(* Helper: build a block with a Return terminator *)
let return_block (label_id : int) (stmts : statement list) (ret_val : var) :
    block =
  {
    id = fresh_id ();
    label_id;
    statements = stmts;
    terminator =
      {
        id = fresh_id ();
        node =
          OR_Return
            {
              operand = Some (OR_OVar ret_val);
              ownership_ret = OR_Ownership_unknown;
            };
      };
    pred_blocks = [];
    succ_blocks = [];
  }

let apply_wrapper_name ~(fn_name : string) ~param_tys ~ret_ty
    ~(cast_from : ty option) : qualified_name =
  let param_tys = List.map type_key_of_ty param_tys in
  let base =
    Printf.sprintf "__wrapper.%s.%s" fn_name (String.concat "_" param_tys)
  in
  match cast_from with
  | None -> Printf.sprintf "%s_ret_%s" base (type_key_of_ty ret_ty)
  | Some c ->
      Printf.sprintf "%s_cast_%s_ret_%s" base (type_key_of_ty c)
        (type_key_of_ty ret_ty)

(** Wrapper input typing: the first [n_make_closure_loads] params are the
    closure's stored args, loaded by the make_closure_accum.dispatch.

    the ref slots in make_closure_loads should be exposed to the ownership
    memory model

    The cast to each callee param's real type happens in prepare_args. *)
let wrapper_input_params (n_make_closure_loads : int) (param_tys : ty list) :
    var list =
  List.mapi
    (fun i (pty : ty) ->
      let in_ty =
        if i < n_make_closure_loads && is_ref_ty pty then obj_ptr_ty ()
        else i64_ty
      in
      fresh_var ("Sy_oir_x" ^ string_of_int i) in_ty)
    param_tys

(** Cast each wrapper input to its real param type when they differ. *)
let prepare_args (params : var list) (param_tys : ty list) :
    var list * statement list =
  let make_statement (i : int) (v : var) (pty : ty) =
    if v.ty.ir_type = pty.ir_type then (v, None)
    else
      let cv = fresh_var ("Sy_oir_s" ^ string_of_int i) pty in
      let cast_stmt =
        make_statement
          (OR_Assign
             {
               dst = cv;
               rvalue =
                 make_rvalue
                   (OR_Cast
                      {
                        src = OR_OVar v;
                        to_ty = pty;
                        ownership = OR_Ownership_unknown;
                      })
                   pty;
             })
          pty
      in
      (cv, Some cast_stmt)
  in
  let args, casts =
    List.mapi
      (fun i (v, pty) -> make_statement i v pty)
      (List.combine params param_tys)
    |> List.split
  in
  (args, List.filter_map Fun.id casts)

(** Build a __wrapper function.

    Signature: (captures typed..., applied_args as i64...) -> ret_ty

    Body: cast each carrier arg to param_tys[i], call fn_name(casted_args...);
    when the callee's real return (cast_from) differs from the wrapper's ret_ty
    (generic carrier), cast the result to ret_ty before returning.

    Generated once per unique (fn_name, param_tys, ret_ty, cast_from). *)
let build_apply_wrapper ~(fn_name : string) ~(param_tys : ty list)
    ~(ret_ty : ty) ~(callee_name : string) ~(cast_from : ty option)
    ~(n_make_closure_loads : int) : function_oir =
  let wrapper_name =
    apply_wrapper_name ~fn_name ~param_tys ~ret_ty ~cast_from
  in
  let arg_params = wrapper_input_params n_make_closure_loads param_tys in
  let callee_args, cast_stmts = prepare_args arg_params param_tys in
  let casted_args =
    List.map
      (fun v -> { operand = OR_OVar v; ownership_arg = OR_Ownership_unknown })
      callee_args
  in
  let callee_result_ty = Option.value ~default:ret_ty cast_from in
  let dst_var = fresh_var "Sy_oir_rst" callee_result_ty in
  let call_stmt =
    make_statement
      (OR_Call
         { dst = dst_var; target = Direct callee_name; args = casted_args })
      callee_result_ty
  in
  let ret_var, extra_stmts, extra_locals =
    match cast_from with
    | None -> (dst_var, [], [])
    | Some _ ->
        let result_var = fresh_var "Sy_oir_result" ret_ty in
        let cast_result_stmt =
          make_statement
            (OR_Assign
               {
                 dst = result_var;
                 rvalue =
                   make_rvalue
                     (OR_Cast
                        {
                          src = OR_OVar dst_var;
                          to_ty = ret_ty;
                          ownership = OR_Ownership_unknown;
                        })
                     ret_ty;
               })
            ret_ty
        in
        (result_var, [ cast_result_stmt ], [ result_var ])
  in
  let entry_block =
    return_block 0 (cast_stmts @ [ call_stmt ] @ extra_stmts) ret_var
  in
  {
    id = fresh_id ();
    name = wrapper_name;
    params = arg_params;
    locals = (dst_var :: callee_args) @ extra_locals;
    entry_block;
    blocks = [ entry_block ];
    return_ty = ret_ty;
    visibility = OR_Private;
    unit_param_indices = [];
  }

let make_closure_accum_dispatch_name (id : int) ~(ret_ty : ty) : qualified_name
    =
  Printf.sprintf "__make_closure_accum.dispatch.%d_ret_%s" id
    (type_key_of_ty ret_ty)

(** Build a make_closure_accum_dispatch function (multi-path).

    Signature: (all_remaining_args..., clos, dispatch_id) -> ret_ty

    Body: load stored args from clos[1+], combine with remaining_args, switch on
    dispatch_id, each case calls the corresponding __wrapper with all m args.

    Closure Layout:
    - clos[0] = __make_closure_accum_dispatch,
    - clos[1+] = stored_args *)
let build_make_closure_accum_dispatch ~(stored_tys : ty list) ~args_size
    ~(specializations : (int * string * ty list * ty) list) ~ret_ty id :
    function_oir =
  let dispatch_accum_fn_name = make_closure_accum_dispatch_name id ~ret_ty in
  let apply_arg_params =
    List.init args_size (fun i ->
        fresh_var ("Sy_oir_x" ^ string_of_int i) i64_ty)
  in
  let clos_ty = obj_ptr_ty () in
  let clos_var = fresh_var "Sy_oir_clos" clos_ty in
  let dispatch_param = fresh_var "Sy_oir_dp_id" i64_ty in
  (* Load stored args from clos[1+]; object slots are loaded as object reads so
     pass_ownership emits a share (each application takes an owned copy). *)
  let stored_vars, stored_load_stmts =
    stored_slot_loads clos_var 1 stored_tys
  in
  let all_arg_vars = stored_vars @ apply_arg_params in
  let case_data =
    List.map
      (fun (tag_id, fn_name, param_tys, spe_ret_ty) ->
        let cast_needed = type_key_of_ty spe_ret_ty <> type_key_of_ty ret_ty in
        let direct_fn =
          apply_wrapper_name ~fn_name ~param_tys ~ret_ty
            ~cast_from:(if cast_needed then Some spe_ret_ty else None)
        in
        let case_dst =
          fresh_var ("Sy_oir_case_result" ^ string_of_int tag_id) ret_ty
        in
        let call_stmt =
          make_statement
            (OR_Call
               {
                 dst = case_dst;
                 target = Direct direct_fn;
                 args =
                   List.map
                     (fun v ->
                       {
                         operand = OR_OVar v;
                         ownership_arg = OR_Ownership_unknown;
                       })
                     all_arg_vars;
               })
            ret_ty
        in
        let blk = return_block tag_id [ call_stmt ] case_dst in
        (blk, [ case_dst ], { value = tag_id; target_block = blk.id }))
      specializations
  in
  let case_blocks = List.map (fun (b, _, _) -> b) case_data in
  let case_locals = List.concat_map (fun (_, l, _) -> l) case_data in
  let cases = List.map (fun (_, _, c) -> c) case_data in
  let entry_block =
    {
      id = fresh_id ();
      label_id = -1;
      statements = stored_load_stmts;
      terminator =
        {
          id = fresh_id ();
          node =
            OR_Switch
              { scrutinee = dispatch_param; cases; default_block = None };
        };
      pred_blocks = [];
      succ_blocks = [];
    }
  in
  let all_blocks = entry_block :: case_blocks in
  {
    id = fresh_id ();
    name = dispatch_accum_fn_name;
    params = apply_arg_params @ [ clos_var; dispatch_param ];
    locals = stored_vars @ case_locals;
    entry_block;
    blocks = all_blocks;
    return_ty = ret_ty;
    visibility = OR_Private;
    unit_param_indices = [];
  }

let make_closure_accum_name ~(fn_name : string) (id : int) ~(ret_ty : ty) :
    qualified_name =
  Printf.sprintf "__make_closure_accum.%s.%d_ret_%s" fn_name id
    (type_key_of_ty ret_ty)

(** Build a make_closure_accum function.

    Signature: (all_remaining_args..., clos, dispatch_id) -> ret_ty

    Body: load stored args from clos[1+], combine with remaining_args, call the
    corresponding __wrapper with all m args.

    Closure layout:
    - clos[0] = __make_closure_accum,
    - clos[1+] = stored_args *)
let build_make_closure_accum ~(fn_name : string) ~(stored_tys : ty list)
    ~args_size ~(specializations : ty list) ~ret_ty id : function_oir =
  let accum_fn_name = make_closure_accum_name ~fn_name id ~ret_ty in
  let dispatch_param = fresh_var "Sy_oir_dp_id" i64_ty in
  let clos_var = fresh_var "Sy_oir_clos" (obj_ptr_ty ()) in
  let arg_params =
    List.init args_size (fun i ->
        fresh_var ("Sy_oir_x" ^ string_of_int i) i64_ty)
  in
  let stored_vars, stored_load_stmts =
    stored_slot_loads clos_var 1 stored_tys
  in
  let dst_var = fresh_var "Sy_oir_rst" ret_ty in
  let return_term =
    {
      id = fresh_id ();
      node =
        OR_Return
          {
            operand = Some (OR_OVar dst_var);
            ownership_ret = OR_Ownership_unknown;
          };
    }
  in
  let specialization_name =
    apply_wrapper_name ~fn_name ~param_tys:specializations ~ret_ty
      ~cast_from:None
  in
  let call_stmt =
    make_statement
      (OR_Call
         {
           dst = dst_var;
           target = Direct specialization_name;
           args =
             List.map
               (fun v ->
                 { operand = OR_OVar v; ownership_arg = OR_Ownership_unknown })
               (stored_vars @ arg_params);
         })
      dst_var.ty
  in
  let entry_block =
    {
      id = fresh_id ();
      label_id = 0;
      statements = stored_load_stmts @ [ call_stmt ];
      terminator = return_term;
      pred_blocks = [];
      succ_blocks = [];
    }
  in
  let locals = dst_var :: stored_vars in
  {
    id = fresh_id ();
    name = accum_fn_name;
    params = arg_params @ [ clos_var; dispatch_param ];
    locals;
    entry_block;
    blocks = [ entry_block ];
    return_ty = ret_ty;
    visibility = OR_Private;
    unit_param_indices = [];
  }
