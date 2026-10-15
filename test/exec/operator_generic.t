Generic/curried user-defined operator mangles to an invalid LLVM symbol:
TODO: fix operator-name quoting vs monomorphization/closure naming.
  $ cat >test_op_generic.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let (+) x y z = z
  > let main () =
  >   syli_print_i64 ((+) 2 3 4)
  >   syli_print_i64 ((2 + 3) 4)
  >   let p = 2 + 3
  >   syli_print_i64 (p 7)
  > let _ = main ()
  > EOF

  $ dune exec sylic -- cir test_op_generic.sy
  module Test_op_generic :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_op_generic() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:void = #call_direct __init_global.syliTest_op_generic.sy2_any_pat ()
      return
  end
  
  private fn __init_global.syliTest_op_generic.sy2_any_pat() -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:void = #call_direct syliTest_op_generic.main (0:i64)
      return
  end
  
  public fn syliTest_op_generic.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_op_generic.+"__i64__i64__i64_ret_i64 (2:i64, 3:i64, 4:i64)
      %Sy_cir_var_1:void = #call_direct syliTest_op_generic.syli_print_i64 (%Sy_cir_var_0:i64)
      %Sy_cir_var_2:(i64 -> i64) = #make_closure {"syliTest_op_generic.+"} () ( captured_args=[2:i64, 3:i64])
      %Sy_cir_var_3:i64 = #call_apply {%Sy_cir_var_2:(i64 -> i64)}  (4:i64)
      %Sy_cir_var_4:void = #call_direct syliTest_op_generic.syli_print_i64 (%Sy_cir_var_3:i64)
      %Sy_cir_var_5:(?93 -> ?93) = #make_closure {"syliTest_op_generic.+"} () ( captured_args=[2:i64, 3:i64])
      %Sy_cir_var_6:i64 = #call_apply {%Sy_cir_var_5:(?93 -> ?93) as (i64 -> i64)}  (7:i64)
      %Sy_cir_var_7:void = #call_direct syliTest_op_generic.syli_print_i64 (%Sy_cir_var_6:i64)
      return
  end
  
  public fn "syliTest_op_generic.+"__i64__i64__i64_ret_i64(%x:i64, %y:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %z:i64
  end
  
  end

  $ dune exec sylic -- llvm test_op_generic.sy
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
    call void @__init.Test_op_generic()
    ret void
  }
  
  define void @__init.Test_op_generic() gc "statepoint-example" {
  bb0:
    call void @__init_global.syliTest_op_generic.sy2_any_pat()
    ret void
  }
  
  define void @__init_global.syliTest_op_generic.sy2_any_pat() gc "statepoint-example" {
  bb0:
    call void @syliTest_op_generic.main()
    ret void
  }
  
  define void @syliTest_op_generic.main() gc "statepoint-example" {
  bb0:
    %Sy_cir_var_0 = call i64 @"syliTest_op_generic.+"__i64__i64__i64_ret_i64(i64 2, i64 3, i64 4)
    call void @syli_print_i64(i64 %Sy_cir_var_0)
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_2 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377926991530688515, i32 1, i32 3)
    ; nop
    %Sy_oir_accum_fn_0 = bitcast ptr @__make_closure_accum."syliTest_op_generic.+".50_ret_i64 to ptr
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_2)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 0
    store ptr %Sy_oir_accum_fn_0, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_2)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i64 1
    store i64 2, ptr addrspace(1) %Sy_llvm_tmp_3
    %Sy_llvm_tmp_4 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_2)
    %Sy_llvm_tmp_5 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_4, i32 0, i32 2, i64 2
    store i64 3, ptr addrspace(1) %Sy_llvm_tmp_5
    ; nop
    %Sy_llvm_tmp_6 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_2)
    %Sy_llvm_tmp_7 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_6, i32 0, i32 2, i64 0
    %Sy_accum_ptr_1 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_7
    %Sy_cir_var_3 = call i64 %Sy_accum_ptr_1(i64 4, ptr addrspace(1) %Sy_cir_var_2, i64 0)
    ; nop
    call void @syli_print_i64(i64 %Sy_cir_var_3)
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_5 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377926991530688515, i32 1, i32 3)
    ; nop
    %Sy_oir_accum_fn_2 = bitcast ptr @__make_closure_accum."syliTest_op_generic.+".66_ret_i64 to ptr
    %Sy_llvm_tmp_8 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_5)
    %Sy_llvm_tmp_9 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_8, i32 0, i32 2, i64 0
    store ptr %Sy_oir_accum_fn_2, ptr addrspace(1) %Sy_llvm_tmp_9
    %Sy_llvm_tmp_10 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_5)
    %Sy_llvm_tmp_11 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_10, i32 0, i32 2, i64 1
    store i64 2, ptr addrspace(1) %Sy_llvm_tmp_11
    %Sy_llvm_tmp_12 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_5)
    %Sy_llvm_tmp_13 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_12, i32 0, i32 2, i64 2
    store i64 3, ptr addrspace(1) %Sy_llvm_tmp_13
    ; nop
    %Sy_llvm_tmp_14 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_5)
    %Sy_llvm_tmp_15 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_14, i32 0, i32 2, i64 0
    %Sy_accum_ptr_3 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_15
    %Sy_cir_var_6 = call i64 %Sy_accum_ptr_3(i64 7, ptr addrspace(1) %Sy_cir_var_5, i64 0)
    ; nop
    call void @syli_print_i64(i64 %Sy_cir_var_6)
    ret void
  }
  
  define i64 @"syliTest_op_generic.+"__i64__i64__i64_ret_i64(i64 %x, i64 %y, i64 %z) gc "statepoint-example" {
  bb0:
    ret i64 %z
  }
  
  define i64 @__make_closure_accum."syliTest_op_generic.+".50_ret_i64(i64 %Sy_oir_x0, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_oir_imm0 = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i64 2
    %Sy_oir_imm1 = load i64, ptr addrspace(1) %Sy_llvm_tmp_3
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_oir_rst = call i64 @__wrapper."syliTest_op_generic.+".i64_i64_i64_ret_i64(i64 %Sy_oir_imm0, i64 %Sy_oir_imm1, i64 %Sy_oir_x0)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__make_closure_accum."syliTest_op_generic.+".66_ret_i64(i64 %Sy_oir_x0, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_oir_imm0 = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i64 2
    %Sy_oir_imm1 = load i64, ptr addrspace(1) %Sy_llvm_tmp_3
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_oir_rst = call i64 @__wrapper."syliTest_op_generic.+".i64_i64_i64_ret_i64(i64 %Sy_oir_imm0, i64 %Sy_oir_imm1, i64 %Sy_oir_x0)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__wrapper."syliTest_op_generic.+".i64_i64_i64_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, i64 %Sy_oir_x2) gc "statepoint-example" {
  bb0:
    %Sy_oir_rst = call i64 @"syliTest_op_generic.+"__i64__i64__i64_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, i64 %Sy_oir_x2)
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
    %b1 = lshr i64 %i, 1
    %b1m = and i64 %b1, 1
    %m = or i64 %b1m, -2
    %u = and i64 %i, %m
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
  
  $ dune exec sylic -- build test_op_generic.sy
  /usr/lib/llvm-18/bin/opt: ./test_op_generic.ll:33:52: error: expected '(' in call
    %Sy_cir_var_0 = call i64 @"syliTest_op_generic.+"__i64__i64__i64_ret_i64(i64 2, i64 3, i64 4)
                                                     ^
  error: opt (rewrite-statepoints-for-gc) failed
  ***** UNREACHABLE *****
