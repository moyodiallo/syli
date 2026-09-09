OIR with RC insertion

Record object with ref variable death:
  $ cat >test_rc1.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type person = { name: i64; age: i64 }
  > let main () =
  >     let record = { name = 10; age = 30 }
  >     syli_print_i64(record.age)
  > EOF
  $ dune exec sylic -- oir test_rc1.sy
  module Test_rc1 :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_rc1() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_rc1.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:syliTest_rc1.person{{card=2 [0:i64; 1:i64]} tag=- unknow_cyclic} = object_create{size=2:i64}
      
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i64, 10:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i64, 30:i64):i64
      %Sy_cir_var_1:i64 = obj_get(%Sy_cir_var_0:obj_ptr, 1:i64):i64
      release(%Sy_cir_var_0:obj_ptr)
      %Sy_cir_var_2:void = #call_direct syliTest_rc1.syli_print_i64 (%Sy_cir_var_1:i64)
      return
  end
  
  end

Multiple ref variables with independent lifetimes:
  $ cat >test_rc2.sy <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > type box = { value: i64 }
  > let main () =
  >     let a = { value = 1 }
  >     let b = { value = 2 }
  >     let r = a.value + b.value
  > EOF
  $ dune exec sylic -- oir test_rc2.sy
  module Test_rc2 :
  functions:
  public fn __init.Test_rc2() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_rc2.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:syliTest_rc2.box{{card=1 [0:i64]} tag=- unknow_cyclic} = object_create{size=1:i64}
      
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i64, 1:i64):i64
      gc_cycle
      %Sy_cir_var_1:syliTest_rc2.box{{card=1 [0:i64]} tag=- unknow_cyclic} = object_create{size=1:i64}
      
      obj_set(%Sy_cir_var_1:obj_ptr, 0:i64, 2:i64):i64
      %Sy_cir_var_2:i64 = obj_get(%Sy_cir_var_0:obj_ptr, 0:i64):i64
      release(%Sy_cir_var_0:obj_ptr)
      %Sy_cir_var_3:i64 = obj_get(%Sy_cir_var_1:obj_ptr, 0:i64):i64
      release(%Sy_cir_var_1:obj_ptr)
      %Sy_cir_var_4:i64 = #call_direct "syliTest_rc2.+" (%Sy_cir_var_2:i64, %Sy_cir_var_3:i64)
      return
  end
  
  public fn "syliTest_rc2.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  end

Closure with captured variable:
  $ cat >test_rc3.sy <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > let add x y = x + y
  > let apply f x = f x
  > let main () =
  >     let r = apply (add 10) 20
  > EOF
  $ dune exec sylic -- oir test_rc3.sy
  module Test_rc3 :
  functions:
  public fn __init.Test_rc3() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_rc3.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.syliTest_rc3.add.75_ret_i64)
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i32, 10:i64):i64
      
      %Sy_cir_var_1:i64 = #call_direct syliTest_rc3.apply__fn_i64_i64__i64_ret_i64 (@transfer %Sy_cir_var_0:obj_ptr, 20:i64)
      return
  end
  
  public fn syliTest_rc3.add(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_rc3.+" (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn "syliTest_rc3.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  public fn syliTest_rc3.apply__fn_i64_i64__i64_ret_i64(%f:obj_ptr, %x:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_accum_ptr_0:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_0:fn_ptr)  (%x:i64, @transfer %f:obj_ptr, 0:i64)
      
      return %Sy_cir_var_0:i64
  end
  
  private fn __make_closure_accum.syliTest_rc3.add.75_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_imm0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.syliTest_rc3.add.i64_i64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.syliTest_rc3.add.i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct syliTest_rc3.add (%Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  end

Closure returned from function — verifies the returned closure is NOT released before the return:
  $ cat >test_rc_returned.sy <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > let add x y = x + y
  > let make_adder n = add n
  > let main () =
  >     let f = make_adder 10
  >     let r = f 5
  > EOF
  $ dune exec sylic -- oir test_rc_returned.sy
  module Test_rc_returned :
  functions:
  public fn __init.Test_rc_returned() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_rc_returned.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:obj_ptr = #call_direct syliTest_rc_returned.make_adder (10:i64)
      %Sy_accum_ptr_0:fn_ptr = obj_get(%Sy_cir_var_0:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_1:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_0:fn_ptr)  (5:i64, @transfer %Sy_cir_var_0:obj_ptr, 0:i64)
      
      return
  end
  
  public fn syliTest_rc_returned.make_adder(%n:i64) -> obj_ptr:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.syliTest_rc_returned.add.44_ret_i64)
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i32, %n:i64):i64
      
      return @own %Sy_cir_var_0:obj_ptr
  end
  
  public fn syliTest_rc_returned.add(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_rc_returned.+" (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn "syliTest_rc_returned.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  private fn __make_closure_accum.syliTest_rc_returned.add.44_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_imm0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.syliTest_rc_returned.add.i64_i64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.syliTest_rc_returned.add.i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct syliTest_rc_returned.add (%Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  end

Closure compose — two closures passed as borrowed parameters, released in caller after call:
  $ cat >test_rc_compose.sy <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > let add x y = x + y
  > let compose f g x = f (g x)
  > let main () =
  >     let r = compose (add 10) (add 20) 5
  > EOF
  $ dune exec sylic -- oir test_rc_compose.sy
  module Test_rc_compose :
  functions:
  public fn __init.Test_rc_compose() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_rc_compose.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.syliTest_rc_compose.add.92_ret_i64)
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i32, 10:i64):i64
      
      gc_cycle
      %Sy_cir_var_1:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_1:fn_ptr = addr_fn(__make_closure_accum.syliTest_rc_compose.add.99_ret_i64)
      obj_set(%Sy_cir_var_1:obj_ptr, 0:i32, %Sy_oir_accum_fn_1:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_1:obj_ptr, 1:i32, 20:i64):i64
      
      %Sy_cir_var_2:i64 = #call_direct syliTest_rc_compose.compose__fn_i64_i64__fn_i64_i64__i64_ret_i64 (@transfer %Sy_cir_var_0:obj_ptr, @transfer %Sy_cir_var_1:obj_ptr, 5:i64)
      return
  end
  
  public fn syliTest_rc_compose.add(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_rc_compose.+" (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn "syliTest_rc_compose.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  public fn syliTest_rc_compose.compose__fn_i64_i64__fn_i64_i64__i64_ret_i64(%f:obj_ptr, %g:obj_ptr, %x:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_accum_ptr_0:fn_ptr = obj_get(%g:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_0:fn_ptr)  (%x:i64, @transfer %g:obj_ptr, 0:i64)
      
      %Sy_accum_ptr_1:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_1:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_1:fn_ptr)  (%Sy_cir_var_0:i64, @transfer %f:obj_ptr, 0:i64)
      
      return %Sy_cir_var_1:i64
  end
  
  private fn __make_closure_accum.syliTest_rc_compose.add.92_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_imm0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.syliTest_rc_compose.add.i64_i64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __make_closure_accum.syliTest_rc_compose.add.99_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_imm0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.syliTest_rc_compose.add.i64_i64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.syliTest_rc_compose.add.i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct syliTest_rc_compose.add (%Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  end

Closure apply_twice — borrowed closure applied twice, still only released in caller:
  $ cat >test_rc_twice.sy <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > let add x y = x + y
  > let apply f x = f x
  > let apply_twice f x = f (f x)
  > let main () =
  >     let r = apply_twice (add 1) 10
  > EOF
  $ dune exec sylic -- oir test_rc_twice.sy
  module Test_rc_twice :
  functions:
  public fn __init.Test_rc_twice() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_rc_twice.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.syliTest_rc_twice.add.107_ret_i64)
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i32, 1:i64):i64
      
      %Sy_cir_var_1:i64 = #call_direct syliTest_rc_twice.apply_twice__fn_i64_i64__i64_ret_i64 (@transfer %Sy_cir_var_0:obj_ptr, 10:i64)
      return
  end
  
  public fn syliTest_rc_twice.add(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_rc_twice.+" (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn "syliTest_rc_twice.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  public fn syliTest_rc_twice.apply_twice__fn_i64_i64__i64_ret_i64(%f:obj_ptr, %x:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_accum_ptr_0:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_0:fn_ptr)  (%x:i64, @borrow %f:obj_ptr, 0:i64)
      
      %Sy_accum_ptr_1:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_1:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_1:fn_ptr)  (%Sy_cir_var_0:i64, @transfer %f:obj_ptr, 0:i64)
      
      return %Sy_cir_var_1:i64
  end
  
  private fn __make_closure_accum.syliTest_rc_twice.add.107_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_imm0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.syliTest_rc_twice.add.i64_i64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.syliTest_rc_twice.add.i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct syliTest_rc_twice.add (%Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  end
