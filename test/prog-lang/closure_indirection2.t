  $ cat >test_file.sy <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > primitive (-)  : i64 -> i64 -> i64 = "sub"
  > primitive (*)  : i64 -> i64 -> i64 = "mul"
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let add x y = x + y
  > let sub x y = x - y
  > let mul x y = x * y
  > let main () =
  >   let add1 = add 1
  >   let sub1 = sub 1
  >   let mul1 = mul 1
  >   let f = if true then add1 else if true then sub1 else mul1
  >   let result = f 2
  >   syli_print_i64 result
  > let _ = main ()
  > EOF

  $ dune exec sylic -- core test_file.sy > test_file.core
  $ dune exec sylic -- cir test_file.sy > test_file.ir
  $ dune exec sylic -- oir test_file.sy > test_file.oir
  $ dune exec sylic -- llvm test_file.sy > test_file.ll
  $ cat test_file.core
  module Test_file
  extern "syliTest_file.+" : (i64) -> (i64) -> i64
  
  extern "syliTest_file.-" : (i64) -> (i64) -> i64
  
  extern "syliTest_file.*" : (i64) -> (i64) -> i64
  
  extern syliTest_file.syli_print_i64 : (i64) -> unit
  
  let syliTest_file.add = fun (x, y) : i64 ->
      "syliTest_file.+"(x : i64, y : i64) : i64
  
  let syliTest_file.sub = fun (x, y) : i64 ->
      "syliTest_file.-"(x : i64, y : i64) : i64
  
  let syliTest_file.mul = fun (x, y) : i64 ->
      "syliTest_file.*"(x : i64, y : i64) : i64
  
  let syliTest_file.main = fun () : unit ->
      {
        let sy1_add1 = syliTest_file.add(1 : i64) : (i64) -> i64
        let sy2_sub1 = syliTest_file.sub(1 : i64) : (i64) -> i64
        let sy3_mul1 = syliTest_file.mul(1 : i64) : (i64) -> i64
        let sy4_f = if true : bool
            sy1_add1 : (i64) -> i64
          else
            if true : bool
              sy2_sub1 : (i64) -> i64
            else
              sy3_mul1 : (i64) -> i64
        let sy5_result = sy4_f(2 : i64) : i64
        syliTest_file.syli_print_i64(sy5_result : i64) : unit
      }
  
  let syliTest_file.sy6_any_pat = syliTest_file.main(() : unit) : unit
  
  $ cat test_file.ir
  module Test_file :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_file() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:void = #call_direct __init_global.syliTest_file.sy6_any_pat ()
      return
  end
  
  private fn __init_global.syliTest_file.sy6_any_pat() -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:void = #call_direct syliTest_file.main (0:i64)
      return
  end
  
  public fn syliTest_file.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:(i64 -> i64) = #make_closure {syliTest_file.add} () ( captured_args=[1:i64])
      %Sy_cir_var_1:(i64 -> i64) = #make_closure {syliTest_file.sub} () ( captured_args=[1:i64])
      %Sy_cir_var_2:(i64 -> i64) = #make_closure {syliTest_file.mul} () ( captured_args=[1:i64])
      %Sy_cir_var_3:bool = cast(true:bool as bool)
      cond_br %Sy_cir_var_3:bool, bb1, bb2
  
    bb2:
      %Sy_cir_var_5:bool = cast(true:bool as bool)
      cond_br %Sy_cir_var_5:bool, bb3, bb4
  
    bb4:
      %Sy_cir_var_6:(i64 -> i64) = move(%Sy_cir_var_2:(i64 -> i64))
      goto bb5
  
    bb3:
      %Sy_cir_var_6:(i64 -> i64) = move(%Sy_cir_var_1:(i64 -> i64))
      goto bb5
  
    bb5:
      %Sy_cir_var_4:(i64 -> i64) = move(%Sy_cir_var_6:(i64 -> i64))
      goto bb6
  
    bb1:
      %Sy_cir_var_4:(i64 -> i64) = move(%Sy_cir_var_0:(i64 -> i64))
      goto bb6
  
    bb6:
      %Sy_cir_var_7:i64 = #call_apply {%Sy_cir_var_4:(i64 -> i64)}  (2:i64)
      %Sy_cir_var_8:void = #call_direct syliTest_file.syli_print_i64 (%Sy_cir_var_7:i64)
      return
  end
  
  public fn syliTest_file.mul(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_file.*" (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn syliTest_file.sub(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_file.-" (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn syliTest_file.add(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_file.+" (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn "syliTest_file.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  public fn "syliTest_file.-"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 - %y:i64
      return %Sy_prim_result:i64
  end
  
  public fn "syliTest_file.*"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 * %y:i64
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
      %__sy_cir_init_tmp_0:void = #call_direct __init_global.syliTest_file.sy6_any_pat ()
      return
  end
  
  private fn __init_global.syliTest_file.sy6_any_pat() -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:void = #call_direct syliTest_file.main (0:i64)
      return
  end
  
  public fn syliTest_file.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.syliTest_file.add.124_ret_i64)
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i32, 1:i64):i64
      
      gc_cycle
      %Sy_cir_var_1:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_1:fn_ptr = addr_fn(__make_closure_accum.syliTest_file.sub.135_ret_i64)
      obj_set(%Sy_cir_var_1:obj_ptr, 0:i32, %Sy_oir_accum_fn_1:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_1:obj_ptr, 1:i32, 1:i64):i64
      
      gc_cycle
      %Sy_cir_var_2:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_2:fn_ptr = addr_fn(__make_closure_accum.syliTest_file.mul.146_ret_i64)
      obj_set(%Sy_cir_var_2:obj_ptr, 0:i32, %Sy_oir_accum_fn_2:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_2:obj_ptr, 1:i32, 1:i64):i64
      
      %Sy_cir_var_3:bool = cast(true:bool as bool)
      cond_br %Sy_cir_var_3:bool, bb1, bb2
  
    bb2:
      release(%Sy_cir_var_0:obj_ptr)
      %Sy_cir_var_5:bool = cast(true:bool as bool)
      cond_br %Sy_cir_var_5:bool, bb3, bb4
  
    bb4:
      release(%Sy_cir_var_1:obj_ptr)
      %Sy_cir_var_6:obj_ptr = move(%Sy_cir_var_2:obj_ptr)
      goto bb5
  
    bb3:
      release(%Sy_cir_var_2:obj_ptr)
      %Sy_cir_var_6:obj_ptr = move(%Sy_cir_var_1:obj_ptr)
      goto bb5
  
    bb5:
      %Sy_cir_var_4:obj_ptr = move(%Sy_cir_var_6:obj_ptr)
      goto bb6
  
    bb1:
      release(%Sy_cir_var_2:obj_ptr)
      release(%Sy_cir_var_1:obj_ptr)
      %Sy_cir_var_4:obj_ptr = move(%Sy_cir_var_0:obj_ptr)
      goto bb6
  
    bb6:
      %Sy_accum_ptr_3:fn_ptr = obj_get(%Sy_cir_var_4:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_7:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_3:fn_ptr)  (2:i64, @transfer %Sy_cir_var_4:obj_ptr, 0:i64)
      
      %Sy_cir_var_8:void = #call_direct syliTest_file.syli_print_i64 (%Sy_cir_var_7:i64)
      return
  end
  
  public fn syliTest_file.mul(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_file.*" (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn syliTest_file.sub(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_file.-" (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn syliTest_file.add(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_file.+" (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn "syliTest_file.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  public fn "syliTest_file.-"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 - %y:i64
      return %Sy_prim_result:i64
  end
  
  public fn "syliTest_file.*"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 * %y:i64
      return %Sy_prim_result:i64
  end
  
  private fn __make_closure_accum.syliTest_file.add.124_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_val0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.syliTest_file.add.i64_i64_ret_i64 (%Sy_val0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __make_closure_accum.syliTest_file.mul.146_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_val0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.syliTest_file.mul.i64_i64_ret_i64 (%Sy_val0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __make_closure_accum.syliTest_file.sub.135_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_val0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.syliTest_file.sub.i64_i64_ret_i64 (%Sy_val0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.syliTest_file.add.i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct syliTest_file.add (%Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.syliTest_file.mul.i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct syliTest_file.mul (%Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.syliTest_file.sub.i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct syliTest_file.sub (%Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  end

  $ cat test_file.ll
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
    call void @__init.Test_file()
    ret void
  }
  
  define void @__init.Test_file() gc "statepoint-example" {
  bb0:
    call void @__init_global.syliTest_file.sy6_any_pat()
    ret void
  }
  
  define void @__init_global.syliTest_file.sy6_any_pat() gc "statepoint-example" {
  bb0:
    call void @syliTest_file.main()
    ret void
  }
  
  define void @syliTest_file.main() gc "statepoint-example" {
  bb0:
    %Sy_cir_var_6 = alloca ptr addrspace(1)
    %Sy_cir_var_4 = alloca ptr addrspace(1)
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_0 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621890, i32 1, i32 2)
    ; nop
    %Sy_oir_accum_fn_0 = bitcast ptr @__make_closure_accum.syliTest_file.add.124_ret_i64 to ptr
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_0, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i32 1
    store i64 1, ptr addrspace(1) %Sy_llvm_tmp_3
    ; nop
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_1 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621890, i32 1, i32 2)
    ; nop
    %Sy_oir_accum_fn_1 = bitcast ptr @__make_closure_accum.syliTest_file.sub.135_ret_i64 to ptr
    %Sy_llvm_tmp_4 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_1)
    %Sy_llvm_tmp_5 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_4, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_1, ptr addrspace(1) %Sy_llvm_tmp_5
    %Sy_llvm_tmp_6 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_1)
    %Sy_llvm_tmp_7 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_6, i32 0, i32 2, i32 1
    store i64 1, ptr addrspace(1) %Sy_llvm_tmp_7
    ; nop
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_2 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621890, i32 1, i32 2)
    ; nop
    %Sy_oir_accum_fn_2 = bitcast ptr @__make_closure_accum.syliTest_file.mul.146_ret_i64 to ptr
    %Sy_llvm_tmp_8 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_2)
    %Sy_llvm_tmp_9 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_8, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_2, ptr addrspace(1) %Sy_llvm_tmp_9
    %Sy_llvm_tmp_10 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_2)
    %Sy_llvm_tmp_11 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_10, i32 0, i32 2, i32 1
    store i64 1, ptr addrspace(1) %Sy_llvm_tmp_11
    ; nop
    br i1 true, label %bb1, label %bb2
  bb2:
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_cir_var_0)
    br i1 true, label %bb3, label %bb4
  bb4:
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_cir_var_1)
    store ptr addrspace(1) %Sy_cir_var_2, ptr %Sy_cir_var_6
    br label %bb5
  bb3:
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_cir_var_2)
    store ptr addrspace(1) %Sy_cir_var_1, ptr %Sy_cir_var_6
    br label %bb5
  bb5:
    %Sy_llvm_tmp_12 = load ptr addrspace(1), ptr %Sy_cir_var_6
    store ptr addrspace(1) %Sy_llvm_tmp_12, ptr %Sy_cir_var_4
    br label %bb6
  bb1:
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_cir_var_2)
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_cir_var_1)
    store ptr addrspace(1) %Sy_cir_var_0, ptr %Sy_cir_var_4
    br label %bb6
  bb6:
    %Sy_llvm_tmp_13 = load ptr addrspace(1), ptr %Sy_cir_var_4
    %Sy_llvm_tmp_14 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_llvm_tmp_13)
    %Sy_llvm_tmp_15 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_14, i32 0, i32 2, i32 0
    %Sy_accum_ptr_3 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_15
    %Sy_llvm_tmp_16 = load ptr addrspace(1), ptr %Sy_cir_var_4
    %Sy_cir_var_7 = call i64 %Sy_accum_ptr_3(i64 2, ptr addrspace(1) %Sy_llvm_tmp_16, i64 0)
    ; nop
    call void @syli_print_i64(i64 %Sy_cir_var_7)
    ret void
  }
  
  define i64 @syliTest_file.mul(i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_cir_var_0 = call i64 @"syliTest_file.*"(i64 %x, i64 %y)
    ret i64 %Sy_cir_var_0
  }
  
  define i64 @syliTest_file.sub(i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_cir_var_0 = call i64 @"syliTest_file.-"(i64 %x, i64 %y)
    ret i64 %Sy_cir_var_0
  }
  
  define i64 @syliTest_file.add(i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_cir_var_0 = call i64 @"syliTest_file.+"(i64 %x, i64 %y)
    ret i64 %Sy_cir_var_0
  }
  
  define i64 @"syliTest_file.+"(i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_prim_result = add i64 %x, %y
    ret i64 %Sy_prim_result
  }
  
  define i64 @"syliTest_file.-"(i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_prim_result = sub i64 %x, %y
    ret i64 %Sy_prim_result
  }
  
  define i64 @"syliTest_file.*"(i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_prim_result = mul i64 %x, %y
    ret i64 %Sy_prim_result
  }
  
  define i64 @__make_closure_accum.syliTest_file.add.124_ret_i64(i64 %Sy_oir_x0, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_val0 = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_oir_rst = call i64 @__wrapper.syliTest_file.add.i64_i64_ret_i64(i64 %Sy_val0, i64 %Sy_oir_x0)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__make_closure_accum.syliTest_file.mul.146_ret_i64(i64 %Sy_oir_x0, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_val0 = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_oir_rst = call i64 @__wrapper.syliTest_file.mul.i64_i64_ret_i64(i64 %Sy_val0, i64 %Sy_oir_x0)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__make_closure_accum.syliTest_file.sub.135_ret_i64(i64 %Sy_oir_x0, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_val0 = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_oir_rst = call i64 @__wrapper.syliTest_file.sub.i64_i64_ret_i64(i64 %Sy_val0, i64 %Sy_oir_x0)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__wrapper.syliTest_file.add.i64_i64_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1) gc "statepoint-example" {
  bb0:
    %Sy_oir_rst = call i64 @syliTest_file.add(i64 %Sy_oir_x0, i64 %Sy_oir_x1)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__wrapper.syliTest_file.mul.i64_i64_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1) gc "statepoint-example" {
  bb0:
    %Sy_oir_rst = call i64 @syliTest_file.mul(i64 %Sy_oir_x0, i64 %Sy_oir_x1)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__wrapper.syliTest_file.sub.i64_i64_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1) gc "statepoint-example" {
  bb0:
    %Sy_oir_rst = call i64 @syliTest_file.sub(i64 %Sy_oir_x0, i64 %Sy_oir_x1)
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
  

  $ clang -c test_file.ll -o /dev/null 2>/dev/null
