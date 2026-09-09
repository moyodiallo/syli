Closure with last argument as unit:
  $ cat >test_multi.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let add x () = x
  > let main () =
  >   let add1 = add 2
  >   let result =
  >     if false then
  >       add1 ()
  >     else add1 ()
  >   syli_print_i64 result
  > let _ = main ()
  > EOF
  $ dune exec sylic -- llvm test_multi.sy
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
    call void @__init.Test_multi()
    ret void
  }
  
  define void @__init.Test_multi() gc "statepoint-example" {
  bb0:
    call void @__init_global.syliTest_multi.sy3_any_pat()
    ret void
  }
  
  define void @__init_global.syliTest_multi.sy3_any_pat() gc "statepoint-example" {
  bb0:
    call void @syliTest_multi.main()
    ret void
  }
  
  define void @syliTest_multi.main() gc "statepoint-example" {
  bb0:
    %Sy_cir_var_2 = alloca i64
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_0 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621890, i32 1, i32 2)
    ; nop
    %Sy_oir_accum_fn_0 = bitcast ptr @__make_closure_accum.dispatch.30_ret_i64 to ptr
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_0, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i32 1
    store i64 2, ptr addrspace(1) %Sy_llvm_tmp_3
    ; nop
    br i1 false, label %bb1, label %bb2
  bb2:
    %Sy_llvm_tmp_4 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_5 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_4, i32 0, i32 2, i32 0
    %Sy_accum_ptr_1 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_5
    %Sy_cir_var_4 = call i64 %Sy_accum_ptr_1(i64 0, ptr addrspace(1) %Sy_cir_var_0, i64 1)
    ; nop
    store i64 %Sy_cir_var_4, ptr %Sy_cir_var_2
    br label %bb3
  bb1:
    %Sy_llvm_tmp_6 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_7 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_6, i32 0, i32 2, i32 0
    %Sy_accum_ptr_2 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_7
    %Sy_cir_var_3 = call i64 %Sy_accum_ptr_2(i64 0, ptr addrspace(1) %Sy_cir_var_0, i64 0)
    ; nop
    store i64 %Sy_cir_var_3, ptr %Sy_cir_var_2
    br label %bb3
  bb3:
    %Sy_llvm_tmp_8 = load i64, ptr %Sy_cir_var_2
    call void @syli_print_i64(i64 %Sy_llvm_tmp_8)
    ret void
  }
  
  define i64 @syliTest_multi.add__i64__i64_ret_i64(i64 %x) gc "statepoint-example" {
  bb0:
    ret i64 %x
  }
  
  define i64 @__make_closure_accum.dispatch.30_ret_i64(i64 %Sy_oir_x0, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb-1:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_oir_imm0 = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    switch i64 %Sy_oir_dp_id, label %switch_default_unreachable [
      i64 1, label %bb1
      i64 0, label %bb0
    ]
  bb1:
    %Sy_oir_case_result1 = call i64 @__wrapper.syliTest_multi.add.i64_i64_ret_i64(i64 %Sy_oir_imm0, i64 %Sy_oir_x0)
    ret i64 %Sy_oir_case_result1
  bb0:
    %Sy_oir_case_result0 = call i64 @__wrapper.syliTest_multi.add.i64_i64_ret_i64(i64 %Sy_oir_imm0, i64 %Sy_oir_x0)
    ret i64 %Sy_oir_case_result0
  switch_default_unreachable:
    unreachable
  }
  
  define i64 @__wrapper.syliTest_multi.add.i64_i64_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1) gc "statepoint-example" {
  bb0:
    %Sy_oir_rst = call i64 @syliTest_multi.add__i64__i64_ret_i64(i64 %Sy_oir_x0)
    ret i64 %Sy_oir_rst
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %p) {
  bb0:
    %i = ptrtoint ptr addrspace(1) %p to i64
    %u = and i64 %i, -4
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
    %tag = and i64 %pi, 3
    %is_own = icmp eq i64 %tag, 1
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
    %tag = and i64 %pi, 3
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
  
  define ptr addrspace(1) @syli_inlinable_ownership_share(ptr addrspace(1) %p) {
  bb0:
    %pi = ptrtoint ptr addrspace(1) %p to i64
    %tag = and i64 %pi, 2
    %is_always = icmp ne i64 %tag, 0
    br i1 %is_always, label %done, label %promote
  promote:
    %r = or i64 %pi, 1
    %rp = inttoptr i64 %r to ptr addrspace(1)
    call void @syli_rt_ownership_incr(ptr addrspace(1) %rp)
    ret ptr addrspace(1) %rp
  done:
    ret ptr addrspace(1) %p
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_make_always_borrow(ptr addrspace(1) %p) {
  bb0:
    %i = ptrtoint ptr addrspace(1) %p to i64
    %u = and i64 %i, -4
    %r = or i64 %u, 2
    %rp = inttoptr i64 %r to ptr addrspace(1)
    ret ptr addrspace(1) %rp
  }
  
Closure with unit as arguments:
  $ cat >test_multi.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let apply f x y = f x y
  > let add () () z = z
  > let main () =
  >   let add1 = add ()
  >   let result =
  >     if false then
  >       apply add1 () 4
  >     else apply add1 () 2
  >   syli_print_i64 result
  > let _ = main ()
  > EOF
  $ dune exec sylic -- llvm test_multi.sy
  declare void @syli_print_i64(i64)
  declare void @syli_rt_gc_cycle()
  declare ptr addrspace(1) @syli_rt_ownership_alloc_object(i64, i32, i32)
  declare void @syli_rt_ownership_decr(ptr addrspace(1))
  declare void @syli_rt_ownership_incr(ptr addrspace(1))
  declare void @syli_rt_ownership_notify_mutation(ptr addrspace(1), ptr addrspace(1))
  
  define i32 @syli_startup_program() gc "statepoint-example" {
  bb0:
    call void @syli_modules_init()
    ret i32 0
  }
  
  define void @syli_modules_init() gc "statepoint-example" {
  bb0:
    call void @__init.Test_multi()
    ret void
  }
  
  define void @__init.Test_multi() gc "statepoint-example" {
  bb0:
    call void @__init_global.syliTest_multi.sy3_any_pat()
    ret void
  }
  
  define void @__init_global.syliTest_multi.sy3_any_pat() gc "statepoint-example" {
  bb0:
    call void @syliTest_multi.main()
    ret void
  }
  
  define void @syliTest_multi.main() gc "statepoint-example" {
  bb0:
    %Sy_cir_var_2 = alloca i64
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_0 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621890, i32 1, i32 2)
    ; nop
    %Sy_oir_accum_fn_0 = bitcast ptr @__make_closure_accum.dispatch.66_ret_i64 to ptr
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_0, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i32 1
    store i64 0, ptr addrspace(1) %Sy_llvm_tmp_3
    ; nop
    br i1 false, label %bb1, label %bb2
  bb2:
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_5 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 4251398048237748355, i32 1, i32 3)
    ; nop
    %Sy_oir_accum_fn_1 = bitcast ptr @__partial_closure_accum.dispatch.clos0_arg2_ret_i64 to ptr
    %Sy_llvm_tmp_4 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_5)
    %Sy_llvm_tmp_5 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_4, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_1, ptr addrspace(1) %Sy_llvm_tmp_5
    %Sy_llvm_tmp_6 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_5)
    %Sy_llvm_tmp_7 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_6, i32 0, i32 2, i32 1
    store i64 1, ptr addrspace(1) %Sy_llvm_tmp_7
    %Sy_llvm_tmp_8 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_5)
    %Sy_llvm_tmp_9 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_8, i32 0, i32 2, i32 2
    %Sy_oir_release_tmp_1 = load ptr addrspace(1), ptr addrspace(1) %Sy_llvm_tmp_9
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_release_tmp_1)
    %Sy_rir_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_own(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_10 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_5)
    %Sy_llvm_tmp_11 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_10, i32 0, i32 2, i32 2
    store ptr addrspace(1) %Sy_rir_tmp_0, ptr addrspace(1) %Sy_llvm_tmp_11
    call void @syli_rt_ownership_notify_mutation(ptr addrspace(1) %Sy_cir_var_5, ptr addrspace(1) %Sy_rir_tmp_0)
    ; nop
    %Sy_cir_var_6 = call i64 @syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(ptr addrspace(1) %Sy_cir_var_5, i64 0, i64 2)
    store i64 %Sy_cir_var_6, ptr %Sy_cir_var_2
    br label %bb3
  bb1:
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_3 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 4251398048237748290, i32 1, i32 2)
    ; nop
    %Sy_oir_accum_fn_2 = bitcast ptr @__partial_closure_accum.clos0_arg2_ret_i64 to ptr
    %Sy_llvm_tmp_12 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_3)
    %Sy_llvm_tmp_13 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_12, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_2, ptr addrspace(1) %Sy_llvm_tmp_13
    %Sy_llvm_tmp_14 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_3)
    %Sy_llvm_tmp_15 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_14, i32 0, i32 2, i32 1
    %Sy_oir_release_tmp_2 = load ptr addrspace(1), ptr addrspace(1) %Sy_llvm_tmp_15
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_release_tmp_2)
    %Sy_rir_tmp_1 = call ptr addrspace(1) @syli_inlinable_ownership_own(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_16 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_3)
    %Sy_llvm_tmp_17 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_16, i32 0, i32 2, i32 1
    store ptr addrspace(1) %Sy_rir_tmp_1, ptr addrspace(1) %Sy_llvm_tmp_17
    call void @syli_rt_ownership_notify_mutation(ptr addrspace(1) %Sy_cir_var_3, ptr addrspace(1) %Sy_rir_tmp_1)
    ; nop
    %Sy_cir_var_4 = call i64 @syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(ptr addrspace(1) %Sy_cir_var_3, i64 0, i64 4)
    store i64 %Sy_cir_var_4, ptr %Sy_cir_var_2
    br label %bb3
  bb3:
    %Sy_llvm_tmp_18 = load i64, ptr %Sy_cir_var_2
    call void @syli_print_i64(i64 %Sy_llvm_tmp_18)
    ret void
  }
  
  define i64 @syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(ptr addrspace(1) %f, i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %f)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i32 0
    %Sy_accum_ptr_0 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_cir_var_0 = call i64 %Sy_accum_ptr_0(i64 %x, i64 %y, ptr addrspace(1) %f, i64 0)
    ; nop
    ret i64 %Sy_cir_var_0
  }
  
  define i64 @syliTest_multi.add__i64__i64__i64_ret_i64(i64 %z) gc "statepoint-example" {
  bb0:
    ret i64 %z
  }
  
  define i64 @__make_closure_accum.dispatch.66_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb-1:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_oir_imm0 = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    switch i64 %Sy_oir_dp_id, label %switch_default_unreachable [
      i64 1, label %bb1
      i64 0, label %bb0
    ]
  bb1:
    %Sy_oir_case_result1 = call i64 @__wrapper.syliTest_multi.add.i64_i64_i64_ret_i64(i64 %Sy_oir_imm0, i64 %Sy_oir_x0, i64 %Sy_oir_x1)
    ret i64 %Sy_oir_case_result1
  bb0:
    %Sy_oir_case_result0 = call i64 @__wrapper.syliTest_multi.add.i64_i64_i64_ret_i64(i64 %Sy_oir_imm0, i64 %Sy_oir_x0, i64 %Sy_oir_x1)
    ret i64 %Sy_oir_case_result0
  switch_default_unreachable:
    unreachable
  }
  
  define i64 @__partial_closure_accum.clos0_arg2_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_rir_raw_tmp_0 = load ptr addrspace(1), ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_oir_p_clos = call ptr addrspace(1) @syli_inlinable_ownership_share(ptr addrspace(1) %Sy_rir_raw_tmp_0)
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_p_clos)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i64 0
    %Sy_oir_p_accum = load ptr, ptr addrspace(1) %Sy_llvm_tmp_3
    %Sy_oir_rst = call i64 %Sy_oir_p_accum(i64 %Sy_oir_x0, i64 %Sy_oir_x1, ptr addrspace(1) %Sy_oir_p_clos, i64 %Sy_oir_dp_id)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__partial_closure_accum.dispatch.clos0_arg2_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_oir_dp_clos = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_oir_accum_dp_id = add i64 %Sy_oir_dp_id, %Sy_oir_dp_clos
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i64 2
    %Sy_rir_raw_tmp_0 = load ptr addrspace(1), ptr addrspace(1) %Sy_llvm_tmp_3
    %Sy_oir_p_clos = call ptr addrspace(1) @syli_inlinable_ownership_share(ptr addrspace(1) %Sy_rir_raw_tmp_0)
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_4 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_p_clos)
    %Sy_llvm_tmp_5 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_4, i32 0, i32 2, i64 0
    %Sy_oir_p_accum = load ptr, ptr addrspace(1) %Sy_llvm_tmp_5
    %Sy_oir_rst = call i64 %Sy_oir_p_accum(i64 %Sy_oir_x0, i64 %Sy_oir_x1, ptr addrspace(1) %Sy_oir_p_clos, i64 %Sy_oir_accum_dp_id)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__wrapper.syliTest_multi.add.i64_i64_i64_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, i64 %Sy_oir_x2) gc "statepoint-example" {
  bb0:
    %Sy_oir_rst = call i64 @syliTest_multi.add__i64__i64__i64_ret_i64(i64 %Sy_oir_x2)
    ret i64 %Sy_oir_rst
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %p) {
  bb0:
    %i = ptrtoint ptr addrspace(1) %p to i64
    %u = and i64 %i, -4
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
    %tag = and i64 %pi, 3
    %is_own = icmp eq i64 %tag, 1
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
    %tag = and i64 %pi, 3
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
  
  define ptr addrspace(1) @syli_inlinable_ownership_share(ptr addrspace(1) %p) {
  bb0:
    %pi = ptrtoint ptr addrspace(1) %p to i64
    %tag = and i64 %pi, 2
    %is_always = icmp ne i64 %tag, 0
    br i1 %is_always, label %done, label %promote
  promote:
    %r = or i64 %pi, 1
    %rp = inttoptr i64 %r to ptr addrspace(1)
    call void @syli_rt_ownership_incr(ptr addrspace(1) %rp)
    ret ptr addrspace(1) %rp
  done:
    ret ptr addrspace(1) %p
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_make_always_borrow(ptr addrspace(1) %p) {
  bb0:
    %i = ptrtoint ptr addrspace(1) %p to i64
    %u = and i64 %i, -4
    %r = or i64 %u, 2
    %rp = inttoptr i64 %r to ptr addrspace(1)
    ret ptr addrspace(1) %rp
  }
  
