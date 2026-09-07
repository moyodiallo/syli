One polymorphic higher-order function used as a closure over an object and over i64:
  $ cat >two_kinds.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > type box = { mutable value: i64 }
  > let mk v f = f v
  > let main () =
  >   let b = { value = 40 }
  >   let go v f = mk v f
  >   syli_print_i64 ((go b (fun (x : box) -> x.value)) + (go 2 (fun x -> x)))
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build two_kinds.sy
  $ ./two_kinds.exe
  42

  $ dune exec sylic -- llvm two_kinds.sy
  declare void @syli_print_i64(i64)
  declare void @syli_rt_gc_cycle()
  declare ptr addrspace(1) @syli_rt_ownership_alloc_object(i64, i32, i32)
  declare void @syli_rt_ownership_decr(ptr addrspace(1))
  declare void @syli_rt_ownership_incr(ptr addrspace(1))
  
  define i32 @syli_startup_program() gc "statepoint-example" {
  bb0:
    call void @syli_modules_init()
    ret i32 0
  }
  
  define void @syli_modules_init() gc "statepoint-example" {
  bb0:
    call void @__init.Two_kinds()
    ret void
  }
  
  define void @__init.Two_kinds() gc "statepoint-example" {
  bb0:
    call void @__init_global.syliTwo_kinds.sy3_any_pat()
    ret void
  }
  
  define void @__init_global.syliTwo_kinds.sy3_any_pat() gc "statepoint-example" {
  bb0:
    call void @syliTwo_kinds.main()
    ret void
  }
  
  define void @syliTwo_kinds.main() gc "statepoint-example" {
  bb0:
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_0 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621889, i32 1, i64 1)
    ; nop
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 0
    store i64 40, ptr addrspace(1) %Sy_llvm_tmp_1
    call void @syli_rt_gc_cycle()
    %sy2_go = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621889, i32 1, i32 1)
    ; nop
    %Sy_oir_accum_fn_0 = bitcast ptr @__make_closure_accum.dispatch.91_ret_i64 to ptr
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %sy2_go)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_0, ptr addrspace(1) %Sy_llvm_tmp_3
    ; nop
    call void @syli_rt_gc_cycle()
    %__sy_cir_lambda_119 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621889, i32 1, i32 1)
    ; nop
    %Sy_oir_accum_fn_1 = bitcast ptr @__make_closure_accum.__sy_cir_lambda_119.132_ret_i64 to ptr
    %Sy_llvm_tmp_4 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %__sy_cir_lambda_119)
    %Sy_llvm_tmp_5 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_4, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_1, ptr addrspace(1) %Sy_llvm_tmp_5
    ; nop
    %Sy_llvm_tmp_6 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %sy2_go)
    %Sy_llvm_tmp_7 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_6, i32 0, i32 2, i32 0
    %Sy_accum_ptr_2 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_7
    %Sy_apply_cast_3 = ptrtoint ptr addrspace(1) %Sy_cir_var_0 to i64
    %Sy_apply_cast_4 = ptrtoint ptr addrspace(1) %__sy_cir_lambda_119 to i64
    %Sy_rir_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_borrow(ptr addrspace(1) %sy2_go)
    %Sy_cir_var_1 = call i64 %Sy_accum_ptr_2(i64 %Sy_apply_cast_3, i64 %Sy_apply_cast_4, ptr addrspace(1) %Sy_rir_tmp_0, i64 1)
    ; nop
    call void @syli_rt_gc_cycle()
    %__sy_cir_lambda_151 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621889, i32 1, i32 1)
    ; nop
    %Sy_oir_accum_fn_5 = bitcast ptr @__make_closure_accum.__sy_cir_lambda_151.159_ret_i64 to ptr
    %Sy_llvm_tmp_8 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %__sy_cir_lambda_151)
    %Sy_llvm_tmp_9 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_8, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_5, ptr addrspace(1) %Sy_llvm_tmp_9
    ; nop
    %Sy_llvm_tmp_10 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %sy2_go)
    %Sy_llvm_tmp_11 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_10, i32 0, i32 2, i32 0
    %Sy_accum_ptr_6 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_11
    %Sy_apply_cast_7 = ptrtoint ptr addrspace(1) %__sy_cir_lambda_151 to i64
    %Sy_cir_var_2 = call i64 %Sy_accum_ptr_6(i64 2, i64 %Sy_apply_cast_7, ptr addrspace(1) %sy2_go, i64 0)
    ; nop
    %Sy_cir_var_3 = call i64 @"syliTwo_kinds.+"(i64 %Sy_cir_var_1, i64 %Sy_cir_var_2)
    call void @syli_print_i64(i64 %Sy_cir_var_3)
    ret void
  }
  
  define i64 @__sy_cir_lambda_119(ptr addrspace(1) %x) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %x)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 0
    %Sy_cir_var_0 = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %x)
    ret i64 %Sy_cir_var_0
  }
  
  define i64 @__sy_cir_lambda_151(i64 %x) gc "statepoint-example" {
  bb0:
    ret i64 %x
  }
  
  define i64 @"syliTwo_kinds.+"(i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_prim_result = add i64 %x, %y
    ret i64 %Sy_prim_result
  }
  
  define i64 @sy2_go__obj_syliTwo_kinds.box__fn_obj_syliTwo_kinds.box_i64_ret_i64(ptr addrspace(1) %v, ptr addrspace(1) %f) gc "statepoint-example" {
  bb0:
    %Sy_cir_var_0 = call i64 @syliTwo_kinds.mk__obj_syliTwo_kinds.box__fn_obj_syliTwo_kinds.box_i64_ret_i64(ptr addrspace(1) %v, ptr addrspace(1) %f)
    ret i64 %Sy_cir_var_0
  }
  
  define i64 @sy2_go__i64__fn_i64_i64_ret_i64(i64 %v, ptr addrspace(1) %f) gc "statepoint-example" {
  bb0:
    %Sy_cir_var_0 = call i64 @syliTwo_kinds.mk__i64__fn_i64_i64_ret_i64(i64 %v, ptr addrspace(1) %f)
    ret i64 %Sy_cir_var_0
  }
  
  define i64 @syliTwo_kinds.mk__i64__fn_i64_i64_ret_i64(i64 %v, ptr addrspace(1) %f) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %f)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i32 0
    %Sy_accum_ptr_0 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_cir_var_0 = call i64 %Sy_accum_ptr_0(i64 %v, ptr addrspace(1) %f, i64 0)
    ; nop
    ret i64 %Sy_cir_var_0
  }
  
  define i64 @syliTwo_kinds.mk__obj_syliTwo_kinds.box__fn_obj_syliTwo_kinds.box_i64_ret_i64(ptr addrspace(1) %v, ptr addrspace(1) %f) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %f)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i32 0
    %Sy_accum_ptr_0 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_apply_cast_1 = ptrtoint ptr addrspace(1) %v to i64
    %Sy_cir_var_0 = call i64 %Sy_accum_ptr_0(i64 %Sy_apply_cast_1, ptr addrspace(1) %f, i64 0)
    ; nop
    ret i64 %Sy_cir_var_0
  }
  
  define i64 @__make_closure_accum.__sy_cir_lambda_119.132_ret_i64(i64 %Sy_oir_x0, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_oir_rst = call i64 @__wrapper.__sy_cir_lambda_119.obj_syliTwo_kinds.box_i64_ret_i64(i64 %Sy_oir_x0)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__make_closure_accum.__sy_cir_lambda_151.159_ret_i64(i64 %Sy_oir_x0, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_oir_rst = call i64 @__wrapper.__sy_cir_lambda_151.i64_ret_i64(i64 %Sy_oir_x0)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__make_closure_accum.dispatch.91_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb-1:
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    switch i64 %Sy_oir_dp_id, label %switch_default_unreachable [
      i64 0, label %bb0
      i64 1, label %bb1
    ]
  bb0:
    %Sy_oir_case_result0 = call i64 @__wrapper.sy2_go.i64_obj_ptr_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1)
    ret i64 %Sy_oir_case_result0
  bb1:
    %Sy_oir_case_result1 = call i64 @__wrapper.sy2_go.obj_syliTwo_kinds.box_i64_obj_ptr_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1)
    ret i64 %Sy_oir_case_result1
  switch_default_unreachable:
    unreachable
  }
  
  define i64 @__wrapper.__sy_cir_lambda_119.obj_syliTwo_kinds.box_i64_ret_i64(i64 %Sy_oir_x0) gc "statepoint-example" {
  bb0:
    %Sy_oir_s0 = inttoptr i64 %Sy_oir_x0 to ptr addrspace(1)
    %Sy_oir_rst = call i64 @__sy_cir_lambda_119(ptr addrspace(1) %Sy_oir_s0)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__wrapper.__sy_cir_lambda_151.i64_ret_i64(i64 %Sy_oir_x0) gc "statepoint-example" {
  bb0:
    %Sy_oir_rst = call i64 @__sy_cir_lambda_151(i64 %Sy_oir_x0)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__wrapper.sy2_go.i64_obj_ptr_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1) gc "statepoint-example" {
  bb0:
    %Sy_oir_s1 = inttoptr i64 %Sy_oir_x1 to ptr addrspace(1)
    %Sy_oir_rst = call i64 @sy2_go__i64__fn_i64_i64_ret_i64(i64 %Sy_oir_x0, ptr addrspace(1) %Sy_oir_s1)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__wrapper.sy2_go.obj_syliTwo_kinds.box_i64_obj_ptr_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1) gc "statepoint-example" {
  bb0:
    %Sy_oir_s0 = inttoptr i64 %Sy_oir_x0 to ptr addrspace(1)
    %Sy_oir_s1 = inttoptr i64 %Sy_oir_x1 to ptr addrspace(1)
    %Sy_oir_rst = call i64 @sy2_go__obj_syliTwo_kinds.box__fn_obj_syliTwo_kinds.box_i64_ret_i64(ptr addrspace(1) %Sy_oir_s0, ptr addrspace(1) %Sy_oir_s1)
    ret i64 %Sy_oir_rst
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %p) {
  bb0:
    %i = ptrtoint ptr addrspace(1) %p to i64
    %u = and i64 %i, -2
    %r = inttoptr i64 %u to ptr addrspace(1)
    ret ptr addrspace(1) %r
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_borrow(ptr addrspace(1) %p) {
  bb0:
    %i = ptrtoint ptr addrspace(1) %p to i64
    %u = and i64 %i, -2
    %r = inttoptr i64 %u to ptr addrspace(1)
    ret ptr addrspace(1) %r
  }
  
  define void @syli_inlinable_ownership_release(ptr addrspace(1) %p) {
  bb0:
    %pi = ptrtoint ptr addrspace(1) %p to i64
    %tag = and i64 %pi, 1
    %is_own = icmp ne i64 %tag, 0
    br i1 %is_own, label %own, label %done
  own:
    call void @syli_rt_ownership_decr(ptr addrspace(1) %p)
    ret void
  done:
    ret void
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_own(ptr addrspace(1) %p) {
  bb0:
    %pi = ptrtoint ptr addrspace(1) %p to i64
    %tag = and i64 %pi, 1
    %is_borrow = icmp eq i64 %tag, 0
    br i1 %is_borrow, label %promote, label %done
  promote:
    %r = or i64 %pi, 1
    %rp = inttoptr i64 %r to ptr addrspace(1)
    call void @syli_rt_ownership_incr(ptr addrspace(1) %rp)
    ret ptr addrspace(1) %rp
  done:
    ret ptr addrspace(1) %p
  }
  
