  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > let add x y z = x + y + z
  > let apply () =
  >   let add1 = add 1
  >   let add1and2 = add1 2
  >   let result = add1and2 3
  >   result
  > let main () = 
  >   let result = apply ()
  >   syli_print_i64 result
  > let _ = main ()
  > EOF

  $ dune exec sylic -- core test_file.sy > test_file.core
  $ dune exec sylic -- cir_raw test_file.sy > test_file.ir
  $ dune exec sylic -- oir test_file.sy > test_file.oir
  $ dune exec sylic -- llvm test_file.sy > test_file.ll

  $ cat test_file.ir
  module Test_file :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_file() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:void = #call_direct __init_global.syliTest_file.sy5_any_pat ()
      return
  end
  
  private fn __init_global.syliTest_file.sy5_any_pat() -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:void = #call_direct syliTest_file.main (0:i64)
      return
  end
  
  public fn syliTest_file.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct syliTest_file.apply (0:i64)
      %Sy_cir_var_1:void = #call_direct syliTest_file.syli_print_i64 (%Sy_cir_var_0:i64)
      return
  end
  
  public fn syliTest_file.apply(%__unit.0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:(i64, i64 -> i64) = #make_closure {syliTest_file.add} () ( captured_args=[1:i64])
      %Sy_cir_var_1:(i64 -> i64) = #partial_apply {%Sy_cir_var_0:(i64, i64 -> i64)} (2:i64)
      %Sy_cir_var_2:i64 = #call_apply {%Sy_cir_var_1:(i64 -> i64)}  (3:i64)
      return %Sy_cir_var_2:i64
  end
  
  public fn syliTest_file.add(%x:i64, %y:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_file.+" (%x:i64, %y:i64)
      %Sy_cir_var_1:i64 = #call_direct "syliTest_file.+" (%Sy_cir_var_0:i64, %z:i64)
      return %Sy_cir_var_1:i64
  end
  
  public fn "syliTest_file.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  end
  $ cat test_file.core
  module Test_file
  extern syliTest_file.syli_print_i64 : (i64) -> unit
  
  extern "syliTest_file.+" : (i64) -> (i64) -> i64
  
  let syliTest_file.add = fun (x, y, z) : i64 ->
      "syliTest_file.+"("syliTest_file.+"(x : i64, y : i64) : i64, z : i64) : i64
  
  let syliTest_file.apply = fun () : i64 ->
      {
        let sy1_add1 = syliTest_file.add(1 : i64) : (i64) -> (i64) -> i64
        let sy2_add1and2 = sy1_add1(2 : i64) : (i64) -> i64
        let sy3_result = sy2_add1and2(3 : i64) : i64
        sy3_result : i64
      }
  
  let syliTest_file.main = fun () : unit ->
      {
        let sy4_result = syliTest_file.apply(() : unit) : i64
        syliTest_file.syli_print_i64(sy4_result : i64) : unit
      }
  
  let syliTest_file.sy5_any_pat = syliTest_file.main(() : unit) : unit
  
  $ cat test_file.ir
  module Test_file :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_file() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:void = #call_direct __init_global.syliTest_file.sy5_any_pat ()
      return
  end
  
  private fn __init_global.syliTest_file.sy5_any_pat() -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:void = #call_direct syliTest_file.main (0:i64)
      return
  end
  
  public fn syliTest_file.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct syliTest_file.apply (0:i64)
      %Sy_cir_var_1:void = #call_direct syliTest_file.syli_print_i64 (%Sy_cir_var_0:i64)
      return
  end
  
  public fn syliTest_file.apply(%__unit.0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:(i64, i64 -> i64) = #make_closure {syliTest_file.add} () ( captured_args=[1:i64])
      %Sy_cir_var_1:(i64 -> i64) = #partial_apply {%Sy_cir_var_0:(i64, i64 -> i64)} (2:i64)
      %Sy_cir_var_2:i64 = #call_apply {%Sy_cir_var_1:(i64 -> i64)}  (3:i64)
      return %Sy_cir_var_2:i64
  end
  
  public fn syliTest_file.add(%x:i64, %y:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_file.+" (%x:i64, %y:i64)
      %Sy_cir_var_1:i64 = #call_direct "syliTest_file.+" (%Sy_cir_var_0:i64, %z:i64)
      return %Sy_cir_var_1:i64
  end
  
  public fn "syliTest_file.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  end

  $ cat test_file.oir
  module Test_file :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_file() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:void = #call_direct __init_global.syliTest_file.sy5_any_pat ()
      return
  end
  
  private fn __init_global.syliTest_file.sy5_any_pat() -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:void = #call_direct syliTest_file.main (0:i64)
      return
  end
  
  public fn syliTest_file.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct syliTest_file.apply (0:i64)
      %Sy_cir_var_1:void = #call_direct syliTest_file.syli_print_i64 (%Sy_cir_var_0:i64)
      return
  end
  
  public fn syliTest_file.apply(%__unit.0:i64) -> i64:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.syliTest_file.add.62_ret_i64)
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i32, 1:i64):i64
      
      gc_cycle
      %Sy_cir_var_1:obj{{card=3 [0:fn_ptr; 1:obj_ptr; 2:i64]} tag=0 unknow_cyclic} = object_create{size=3:i32}
      
      %Sy_accum_fn_1:fn_ptr = addr_fn(__partial_closure_accum.clos1_arg1_ret_i64)
      obj_set(%Sy_cir_var_1:obj_ptr, 0:i32, %Sy_accum_fn_1:fn_ptr):fn_ptr
      %Sy_release_tmp_1:obj_ptr = @transfer obj_get(%Sy_cir_var_1:obj_ptr, 1:i32):obj_ptr
      release(%Sy_release_tmp_1:obj_ptr)
      obj_set(%Sy_cir_var_1:obj_ptr, 1:i32, @own %Sy_cir_var_0:obj_ptr):obj_ptr
      obj_set(%Sy_cir_var_1:obj_ptr, 2:i32, 2:i64):i64
      
      %Sy_accum_ptr_2:fn_ptr = obj_get(%Sy_cir_var_1:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_2:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_2:fn_ptr)  (3:i64, @transfer %Sy_cir_var_1:obj_ptr, 0:i64)
      
      return %Sy_cir_var_2:i64
  end
  
  public fn syliTest_file.add(%x:i64, %y:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_file.+" (%x:i64, %y:i64)
      %Sy_cir_var_1:i64 = #call_direct "syliTest_file.+" (%Sy_cir_var_0:i64, %z:i64)
      return %Sy_cir_var_1:i64
  end
  
  public fn "syliTest_file.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  private fn __make_closure_accum.syliTest_file.add.62_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_val0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.syliTest_file.add.i64_i64_i64_ret_i64 (%Sy_val0:i64, %Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __partial_closure_accum.clos1_arg1_ret_i64(%Sy_x0:i64, %Sy_clos:obj_ptr, %Sy_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_p_clos:obj_ptr = @share obj_get(%Sy_clos:obj_ptr, 1:i64):obj_ptr
      %Sy_p_accum:fn_ptr = obj_get(%Sy_p_clos:obj_ptr, 0:i64):fn_ptr
      %Sy_val0:i64 = obj_get(%Sy_clos:obj_ptr, 2:i64):i64
      release(%Sy_clos:obj_ptr)
      %Sy_rst:i64 = #call_direct_fn_ptr(%Sy_p_accum:fn_ptr)  (%Sy_val0:i64, %Sy_x0:i64, @transfer %Sy_p_clos:obj_ptr, %Sy_dp_id:i64)
      return %Sy_rst:i64
  end
  
  private fn __wrapper.syliTest_file.add.i64_i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_x2:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct syliTest_file.add (%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_x2:i64)
      return %Sy_oir_rst:i64
  end
  
  end

  $ cat test_file.ll
  declare void @syli_print_i64(i64)
  declare void @syli_rt_gc_cycle()
  declare ptr addrspace(1) @syli_rt_ownership_alloc_object(i64, i32, i32)
  declare void @syli_rt_ownership_decr(ptr addrspace(1))
  declare void @syli_rt_ownership_incr(ptr addrspace(1))
  declare void @syli_rt_ownership_notify_mutation(ptr addrspace(1), ptr addrspace(1))
  declare ptr addrspace(1) @syli_rt_ownership_share(ptr addrspace(1))
  
  define i32 @syli_startup_program() gc "statepoint-example" {
  bb0:
    call void @syli_modules_init()
    ret i32 0
  }
  
  define void @syli_modules_init() gc "statepoint-example" {
  bb0:
    call void @__init.Test_file()
    ret void
  }
  
  define void @__init.Test_file() gc "statepoint-example" {
  bb0:
    call void @__init_global.syliTest_file.sy5_any_pat()
    ret void
  }
  
  define void @__init_global.syliTest_file.sy5_any_pat() gc "statepoint-example" {
  bb0:
    call void @syliTest_file.main()
    ret void
  }
  
  define void @syliTest_file.main() gc "statepoint-example" {
  bb0:
    %Sy_cir_var_0 = call i64 @syliTest_file.apply()
    call void @syli_print_i64(i64 %Sy_cir_var_0)
    ret void
  }
  
  define i64 @syliTest_file.apply() gc "statepoint-example" {
  bb0:
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_0 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621890, i32 1, i32 2)
    ; nop
    %Sy_oir_accum_fn_0 = bitcast ptr @__make_closure_accum.syliTest_file.add.62_ret_i64 to ptr
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_0, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i32 1
    store i64 1, ptr addrspace(1) %Sy_llvm_tmp_3
    ; nop
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_1 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 4251398048237748291, i32 1, i32 3)
    ; nop
    %Sy_accum_fn_1 = bitcast ptr @__partial_closure_accum.clos1_arg1_ret_i64 to ptr
    %Sy_llvm_tmp_4 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_1)
    %Sy_llvm_tmp_5 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_4, i32 0, i32 2, i32 0
    store ptr %Sy_accum_fn_1, ptr addrspace(1) %Sy_llvm_tmp_5
    %Sy_llvm_tmp_6 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_1)
    %Sy_llvm_tmp_7 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_6, i32 0, i32 2, i32 1
    %Sy_release_tmp_1 = load ptr addrspace(1), ptr addrspace(1) %Sy_llvm_tmp_7
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_release_tmp_1)
    %Sy_rir_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_own(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_8 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_1)
    %Sy_llvm_tmp_9 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_8, i32 0, i32 2, i32 1
    store ptr addrspace(1) %Sy_rir_tmp_0, ptr addrspace(1) %Sy_llvm_tmp_9
    call void @syli_rt_ownership_notify_mutation(ptr addrspace(1) %Sy_cir_var_1, ptr addrspace(1) %Sy_rir_tmp_0)
    %Sy_llvm_tmp_10 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_1)
    %Sy_llvm_tmp_11 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_10, i32 0, i32 2, i32 2
    store i64 2, ptr addrspace(1) %Sy_llvm_tmp_11
    ; nop
    %Sy_llvm_tmp_12 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_1)
    %Sy_llvm_tmp_13 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_12, i32 0, i32 2, i32 0
    %Sy_accum_ptr_2 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_13
    %Sy_cir_var_2 = call i64 %Sy_accum_ptr_2(i64 3, ptr addrspace(1) %Sy_cir_var_1, i64 0)
    ; nop
    ret i64 %Sy_cir_var_2
  }
  
  define i64 @syliTest_file.add(i64 %x, i64 %y, i64 %z) gc "statepoint-example" {
  bb0:
    %Sy_cir_var_0 = call i64 @"syliTest_file.+"(i64 %x, i64 %y)
    %Sy_cir_var_1 = call i64 @"syliTest_file.+"(i64 %Sy_cir_var_0, i64 %z)
    ret i64 %Sy_cir_var_1
  }
  
  define i64 @"syliTest_file.+"(i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_prim_result = add i64 %x, %y
    ret i64 %Sy_prim_result
  }
  
  define i64 @__make_closure_accum.syliTest_file.add.62_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_val0 = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_oir_rst = call i64 @__wrapper.syliTest_file.add.i64_i64_i64_ret_i64(i64 %Sy_val0, i64 %Sy_oir_x0, i64 %Sy_oir_x1)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__partial_closure_accum.clos1_arg1_ret_i64(i64 %Sy_x0, ptr addrspace(1) %Sy_clos, i64 %Sy_dp_id) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_rir_raw_tmp_0 = load ptr addrspace(1), ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_p_clos = call ptr addrspace(1) @syli_rt_ownership_share(ptr addrspace(1) %Sy_rir_raw_tmp_0)
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_p_clos)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i64 0
    %Sy_p_accum = load ptr, ptr addrspace(1) %Sy_llvm_tmp_3
    %Sy_llvm_tmp_4 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_clos)
    %Sy_llvm_tmp_5 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_4, i32 0, i32 2, i64 2
    %Sy_val0 = load i64, ptr addrspace(1) %Sy_llvm_tmp_5
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_clos)
    %Sy_rst = call i64 %Sy_p_accum(i64 %Sy_val0, i64 %Sy_x0, ptr addrspace(1) %Sy_p_clos, i64 %Sy_dp_id)
    ret i64 %Sy_rst
  }
  
  define i64 @__wrapper.syliTest_file.add.i64_i64_i64_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, i64 %Sy_oir_x2) gc "statepoint-example" {
  bb0:
    %Sy_oir_rst = call i64 @syliTest_file.add(i64 %Sy_oir_x0, i64 %Sy_oir_x1, i64 %Sy_oir_x2)
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
  
