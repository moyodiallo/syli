  $ cat >test_multi.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > foreign syli_print_f64 : f64 -> unit = "syli_print_f64"
  > let add x z = z
  > let main () =
  >   let add1 = add 1
  >   let d = add1 1.0
  >   let i = add1 1
  >   syli_print_i64 i
  >   syli_print_f64 d
  >   i
  > EOF

  $ dune exec sylic -- cir_raw test_multi.sy
  module Test_multi :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  extern fn syli_print_f64(f64) -> void
  
  
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:(?72 -> ?72) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_cir_var_1:f64 = #call_apply {%Sy_cir_var_0:(?72 -> ?72) as (f64 -> f64)}  (1.0f:f64)
      %Sy_cir_var_2:i64 = #call_apply {%Sy_cir_var_0:(?72 -> ?72) as (i64 -> i64)}  (1:i64)
      %Sy_cir_var_3:void = #call_direct syliTest_multi.syli_print_i64 (%Sy_cir_var_2:i64)
      %Sy_cir_var_4:void = #call_direct syliTest_multi.syli_print_f64 (%Sy_cir_var_1:f64)
      return %Sy_cir_var_2:i64
  end
  
  public fn syliTest_multi.add(%x:?65, %z:?67) -> ?67:
    entry: bb0
  
    bb0:
  
      return %z:?67
  end
  
  end

  $ dune exec sylic -- typing test_multi.sy
  Typed test_multi.sy successfully: module Test_multi with 4 top-level typed items
  Type Environment:
  {
    add : forall '65 '67. '65 -> '67 -> '67
    main : unit -> i64
    syli_print_f64 : f64 -> unit
    syli_print_i64 : i64 -> unit
  }

  $ dune exec sylic -- oir test_multi.sy
  module Test_multi :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  extern fn syli_print_f64(f64) -> void
  
  
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> i64:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.dispatch.36_ret_i64)
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i32, 1:i64):i64
      
      %Sy_accum_ptr_1:fn_ptr = obj_get(%Sy_cir_var_0:obj_ptr, 0:i32):fn_ptr
      %Sy_apply_cast_2:i64 = cast(1.0f:f64 as i64)
      %Sy_apply_tmp_3:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_1:fn_ptr)  (%Sy_apply_cast_2:i64, @borrow %Sy_cir_var_0:obj_ptr, 1:i64)
      %Sy_cir_var_1:f64 = cast(%Sy_apply_tmp_3:i64 as f64)
      
      %Sy_accum_ptr_4:fn_ptr = obj_get(%Sy_cir_var_0:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_2:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_4:fn_ptr)  (1:i64, @transfer %Sy_cir_var_0:obj_ptr, 0:i64)
      
      %Sy_cir_var_3:void = #call_direct syliTest_multi.syli_print_i64 (%Sy_cir_var_2:i64)
      %Sy_cir_var_4:void = #call_direct syliTest_multi.syli_print_f64 (%Sy_cir_var_1:f64)
      return %Sy_cir_var_2:i64
  end
  
  public fn syliTest_multi.add__i64__f64_ret_f64(%x:i64, %z:f64) -> f64:
    entry: bb0
  
    bb0:
  
      return %z:f64
  end
  
  public fn syliTest_multi.add__i64__i64_ret_i64(%x:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %z:i64
  end
  
  private fn __make_closure_accum.dispatch.36_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb-1
  
    bb-1:
      %Sy_val0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      switch %Sy_oir_dp_id:i64 [0: bb0, 1: bb1]
  
    bb0:
      %Sy_oir_case_result0:i64 = #call_direct __wrapper.syliTest_multi.add.i64_i64_ret_i64 (%Sy_val0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_case_result0:i64
  
    bb1:
      %Sy_oir_case_result1:i64 = #call_direct __wrapper.syliTest_multi.add.i64_f64_cast_f64_ret_i64 (%Sy_val0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_case_result1:i64
  end
  
  private fn __wrapper.syliTest_multi.add.i64_f64_cast_f64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_s1:f64 = cast(%Sy_oir_x1:i64 as f64)
      %Sy_oir_rst:f64 = #call_direct syliTest_multi.add__i64__f64_ret_f64 (%Sy_oir_x0:i64, %Sy_oir_s1:f64)
      %Sy_oir_result:i64 = cast(%Sy_oir_rst:f64 as i64)
      return %Sy_oir_result:i64
  end
  
  private fn __wrapper.syliTest_multi.add.i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct syliTest_multi.add__i64__i64_ret_i64 (%Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  end

