
Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let result = apply add1 3 4
  >   let result2 = apply add1 1.0 2.0
  > EOF
  $ dune exec sylic -- cir_mono test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:(?89, ?90 -> i64) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_cir_var_1:(i64, i64 -> i64) = cast(%Sy_cir_var_0:(?89, ?90 -> i64) as (i64, i64 -> i64))
      %Sy_cir_var_2:i64 = #call_direct syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64 (%Sy_cir_var_1:(i64, i64 -> i64), 3:i64, 4:i64)
      %Sy_cir_var_3:(f64, f64 -> i64) = cast(%Sy_cir_var_0:(?89, ?90 -> i64) as (f64, f64 -> i64))
      %Sy_cir_var_4:i64 = #call_direct syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64 (%Sy_cir_var_3:(f64, f64 -> i64), 1.0f:f64, 2.0f:f64)
      return
  end
  
  public fn syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64(%f:(f64, f64 -> i64), %x:f64, %y:f64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_apply {%f:(f64, f64 -> i64)}  (%x:f64, %y:f64)
      return %Sy_cir_var_0:i64
  end
  
  public fn syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(%f:(i64, i64 -> i64), %x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_apply {%f:(i64, i64 -> i64)}  (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn syliTest_multi.add__i64__i64__i64_ret_i64(%x:i64, %y:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  public fn syliTest_multi.add__i64__f64__f64_ret_i64(%x:i64, %y:f64, %z:f64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  end

Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let result = apply add1 3 4
  >   let result2 = apply add1 1.0 2.0
  > EOF
  $ dune exec sylic -- cir test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:(?89, ?90 -> i64) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_cir_var_1:(i64, i64 -> i64) = cast(%Sy_cir_var_0:(?89, ?90 -> i64) as (i64, i64 -> i64))
      %Sy_cir_var_2:i64 = #call_direct syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64 (%Sy_cir_var_1:(i64, i64 -> i64), 3:i64, 4:i64)
      %Sy_cir_var_3:(f64, f64 -> i64) = cast(%Sy_cir_var_0:(?89, ?90 -> i64) as (f64, f64 -> i64))
      %Sy_cir_var_4:i64 = #call_direct syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64 (%Sy_cir_var_3:(f64, f64 -> i64), 1.0f:f64, 2.0f:f64)
      return
  end
  
  public fn syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64(%f:(f64, f64 -> i64), %x:f64, %y:f64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_apply {%f:(f64, f64 -> i64)}  (%x:f64, %y:f64)
      return %Sy_cir_var_0:i64
  end
  
  public fn syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(%f:(i64, i64 -> i64), %x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_apply {%f:(i64, i64 -> i64)}  (%x:i64, %y:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn syliTest_multi.add__i64__i64__i64_ret_i64(%x:i64, %y:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  public fn syliTest_multi.add__i64__f64__f64_ret_i64(%x:i64, %y:f64, %z:f64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  end

  $ dune exec sylic -- oir test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.dispatch.61_ret_i64)
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i32, 1:i64):i64
      
      gc_cycle
      %Sy_cir_var_1:obj{{card=3 [0:fn_ptr; 1:i64; 2:obj_ptr]} tag=0 unknow_cyclic} = object_create{size=3:i32}
      
      %Sy_oir_accum_fn_1:fn_ptr = addr_fn(__partial_closure_accum.dispatch.clos0_arg2_ret_i64)
      obj_set(%Sy_cir_var_1:obj_ptr, 0:i32, %Sy_oir_accum_fn_1:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_1:obj_ptr, 1:i32, 1:i64):i64
      %Sy_oir_release_tmp_1:obj_ptr = @transfer obj_get(%Sy_cir_var_1:obj_ptr, 2:i32):obj_ptr
      release(%Sy_oir_release_tmp_1:obj_ptr)
      obj_set(%Sy_cir_var_1:obj_ptr, 2:i32, @share %Sy_cir_var_0:obj_ptr):obj_ptr
      
      %Sy_cir_var_2:i64 = #call_direct syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64 (@transfer %Sy_cir_var_1:obj_ptr, 3:i64, 4:i64)
      gc_cycle
      %Sy_cir_var_3:obj{{card=2 [0:fn_ptr; 1:obj_ptr]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_2:fn_ptr = addr_fn(__partial_closure_accum.clos0_arg2_ret_i64)
      obj_set(%Sy_cir_var_3:obj_ptr, 0:i32, %Sy_oir_accum_fn_2:fn_ptr):fn_ptr
      %Sy_oir_release_tmp_2:obj_ptr = @transfer obj_get(%Sy_cir_var_3:obj_ptr, 1:i32):obj_ptr
      release(%Sy_oir_release_tmp_2:obj_ptr)
      obj_set(%Sy_cir_var_3:obj_ptr, 1:i32, @own %Sy_cir_var_0:obj_ptr):obj_ptr
      
      %Sy_cir_var_4:i64 = #call_direct syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64 (@transfer %Sy_cir_var_3:obj_ptr, 1.0f:f64, 2.0f:f64)
      return
  end
  
  public fn syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64(%f:obj_ptr, %x:f64, %y:f64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_accum_ptr_0:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
      %Sy_apply_cast_1:i64 = cast(%x:f64 as i64)
      %Sy_apply_cast_2:i64 = cast(%y:f64 as i64)
      %Sy_cir_var_0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_0:fn_ptr)  (%Sy_apply_cast_1:i64, %Sy_apply_cast_2:i64, @transfer %f:obj_ptr, 0:i64)
      
      return %Sy_cir_var_0:i64
  end
  
  public fn syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(%f:obj_ptr, %x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_accum_ptr_0:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_0:fn_ptr)  (%x:i64, %y:i64, @transfer %f:obj_ptr, 0:i64)
      
      return %Sy_cir_var_0:i64
  end
  
  public fn syliTest_multi.add__i64__i64__i64_ret_i64(%x:i64, %y:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  public fn syliTest_multi.add__i64__f64__f64_ret_i64(%x:i64, %y:f64, %z:f64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  private fn __make_closure_accum.dispatch.61_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb-1
  
    bb-1:
      %Sy_oir_imm0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      switch %Sy_oir_dp_id:i64 [0: bb0, 1: bb1]
  
    bb0:
      %Sy_oir_case_result0:i64 = #call_direct __wrapper.syliTest_multi.add.i64_f64_f64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_case_result0:i64
  
    bb1:
      %Sy_oir_case_result1:i64 = #call_direct __wrapper.syliTest_multi.add.i64_i64_i64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_case_result1:i64
  end
  
  private fn __partial_closure_accum.clos0_arg2_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_p_clos:obj_ptr = @share obj_get(%Sy_oir_clos:obj_ptr, 1:i64):obj_ptr
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_p_accum:fn_ptr = obj_get(%Sy_oir_p_clos:obj_ptr, 0:i64):fn_ptr
      %Sy_oir_rst:i64 = #call_direct_fn_ptr(%Sy_oir_p_accum:fn_ptr)  (%Sy_oir_x0:i64, %Sy_oir_x1:i64, @transfer %Sy_oir_p_clos:obj_ptr, %Sy_oir_dp_id:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __partial_closure_accum.dispatch.clos0_arg2_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_dp_clos:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      %Sy_oir_accum_dp_id:i64 = %Sy_oir_dp_id:i64 + %Sy_oir_dp_clos:i64
      %Sy_oir_p_clos:obj_ptr = @share obj_get(%Sy_oir_clos:obj_ptr, 2:i64):obj_ptr
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_p_accum:fn_ptr = obj_get(%Sy_oir_p_clos:obj_ptr, 0:i64):fn_ptr
      %Sy_oir_rst:i64 = #call_direct_fn_ptr(%Sy_oir_p_accum:fn_ptr)  (%Sy_oir_x0:i64, %Sy_oir_x1:i64, @transfer %Sy_oir_p_clos:obj_ptr, %Sy_oir_accum_dp_id:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.syliTest_multi.add.i64_f64_f64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_x2:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_s1:f64 = cast(%Sy_oir_x1:i64 as f64)
      %Sy_oir_s2:f64 = cast(%Sy_oir_x2:i64 as f64)
      %Sy_oir_rst:i64 = #call_direct syliTest_multi.add__i64__f64__f64_ret_i64 (%Sy_oir_x0:i64, %Sy_oir_s1:f64, %Sy_oir_s2:f64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.syliTest_multi.add.i64_i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_x2:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct syliTest_multi.add__i64__i64__i64_ret_i64 (%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_x2:i64)
      return %Sy_oir_rst:i64
  end
  
  end

  $ dune exec sylic -- rir test_multi.sy
  module Test_multi :
  type_defs:
    (none)
  ffi_external_functions:
    (none)
  globals:
    (none)
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
  bb0:
  
    return
  end
  
  
  public fn syliTest_multi.main(%__unit.0:i64) -> void:
    entry: bb0
  
  bb0:
    %__sy_void:void = #runtime_call syli_rt_gc_cycle()
    %Sy_cir_var_0:obj_ptr = #runtime_call syli_rt_ownership_alloc_object(2377900603251621890:i64, 1:i32, 2:i32)
  
    %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.dispatch.61_ret_i64)
    obj_set(%Sy_cir_var_0:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
    obj_set(%Sy_cir_var_0:obj_ptr, 1:i32, 1:i64):i64
  
    %__sy_void:void = #runtime_call syli_rt_gc_cycle()
    %Sy_cir_var_1:obj_ptr = #runtime_call syli_rt_ownership_alloc_object(4251398048237748355:i64, 1:i32, 3:i32)
  
    %Sy_oir_accum_fn_1:fn_ptr = addr_fn(__partial_closure_accum.dispatch.clos0_arg2_ret_i64)
    obj_set(%Sy_cir_var_1:obj_ptr, 0:i32, %Sy_oir_accum_fn_1:fn_ptr):fn_ptr
    obj_set(%Sy_cir_var_1:obj_ptr, 1:i32, 1:i64):i64
    %Sy_oir_release_tmp_1:obj_ptr = obj_get(%Sy_cir_var_1:obj_ptr, 2:i32):obj_ptr
    %__sy_void:void = #runtime_call syli_rt_ownership_release(%Sy_oir_release_tmp_1:obj_ptr)
    %Sy_rir_tmp_0:obj_ptr = #runtime_call syli_rt_ownership_share(%Sy_cir_var_0:obj_ptr)
    obj_set(%Sy_cir_var_1:obj_ptr, 2:i32, %Sy_rir_tmp_0:obj_ptr):obj_ptr
    %__sy_void:void = #runtime_call syli_rt_ownership_notify_mutation(%Sy_cir_var_1:obj_ptr, %Sy_rir_tmp_0:obj_ptr)
  
    %Sy_cir_var_2:i64 = #call_direct syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64 (%Sy_cir_var_1:obj_ptr, 3:i64, 4:i64)
    %__sy_void:void = #runtime_call syli_rt_gc_cycle()
    %Sy_cir_var_3:obj_ptr = #runtime_call syli_rt_ownership_alloc_object(4251398048237748290:i64, 1:i32, 2:i32)
  
    %Sy_oir_accum_fn_2:fn_ptr = addr_fn(__partial_closure_accum.clos0_arg2_ret_i64)
    obj_set(%Sy_cir_var_3:obj_ptr, 0:i32, %Sy_oir_accum_fn_2:fn_ptr):fn_ptr
    %Sy_oir_release_tmp_2:obj_ptr = obj_get(%Sy_cir_var_3:obj_ptr, 1:i32):obj_ptr
    %__sy_void:void = #runtime_call syli_rt_ownership_release(%Sy_oir_release_tmp_2:obj_ptr)
    %Sy_rir_tmp_1:obj_ptr = #runtime_call syli_rt_ownership_own(%Sy_cir_var_0:obj_ptr)
    obj_set(%Sy_cir_var_3:obj_ptr, 1:i32, %Sy_rir_tmp_1:obj_ptr):obj_ptr
    %__sy_void:void = #runtime_call syli_rt_ownership_notify_mutation(%Sy_cir_var_3:obj_ptr, %Sy_rir_tmp_1:obj_ptr)
  
    %Sy_cir_var_4:i64 = #call_direct syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64 (%Sy_cir_var_3:obj_ptr, 1.0:f64, 2.0:f64)
    return
  end
  
  
  public fn syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64(%f:obj_ptr, %x:f64, %y:f64) -> i64:
    entry: bb0
  
  bb0:
    %Sy_accum_ptr_0:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
    %Sy_apply_cast_1:i64 = bitcast(%x:f64 as i64)
    %Sy_apply_cast_2:i64 = bitcast(%y:f64 as i64)
    %Sy_cir_var_0:i64 = #call_indirect %Sy_accum_ptr_0:fn_ptr (%Sy_apply_cast_1:i64, %Sy_apply_cast_2:i64, %f:obj_ptr, 0:i64)
  
    return %Sy_cir_var_0:i64
  end
  
  
  public fn syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(%f:obj_ptr, %x:i64, %y:i64) -> i64:
    entry: bb0
  
  bb0:
    %Sy_accum_ptr_0:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
    %Sy_cir_var_0:i64 = #call_indirect %Sy_accum_ptr_0:fn_ptr (%x:i64, %y:i64, %f:obj_ptr, 0:i64)
  
    return %Sy_cir_var_0:i64
  end
  
  
  public fn syliTest_multi.add__i64__i64__i64_ret_i64(%x:i64, %y:i64, %z:i64) -> i64:
    entry: bb0
  
  bb0:
  
    return %x:i64
  end
  
  
  public fn syliTest_multi.add__i64__f64__f64_ret_i64(%x:i64, %y:f64, %z:f64) -> i64:
    entry: bb0
  
  bb0:
  
    return %x:i64
  end
  
  
  private fn __make_closure_accum.dispatch.61_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb-1
  
  bb-1:
    %Sy_oir_imm0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
    %__sy_void:void = #runtime_call syli_rt_ownership_release(%Sy_oir_clos:obj_ptr)
    switch %Sy_oir_dp_id:i64 [0 -> bb256, 1 -> bb257]
  
  bb0:
    %Sy_oir_case_result0:i64 = #call_direct __wrapper.syliTest_multi.add.i64_f64_f64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64, %Sy_oir_x1:i64)
    return %Sy_oir_case_result0:i64
  
  bb1:
    %Sy_oir_case_result1:i64 = #call_direct __wrapper.syliTest_multi.add.i64_i64_i64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64, %Sy_oir_x1:i64)
    return %Sy_oir_case_result1:i64
  end
  
  
  private fn __partial_closure_accum.clos0_arg2_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
  bb0:
    %Sy_rir_raw_tmp_0:obj_ptr = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):obj_ptr
    %Sy_oir_p_clos:obj_ptr = #runtime_call syli_rt_ownership_share(%Sy_rir_raw_tmp_0:obj_ptr)
    %__sy_void:void = #runtime_call syli_rt_ownership_release(%Sy_oir_clos:obj_ptr)
    %Sy_oir_p_accum:fn_ptr = obj_get(%Sy_oir_p_clos:obj_ptr, 0:i64):fn_ptr
    %Sy_oir_rst:i64 = #call_indirect %Sy_oir_p_accum:fn_ptr (%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_p_clos:obj_ptr, %Sy_oir_dp_id:i64)
    return %Sy_oir_rst:i64
  end
  
  
  private fn __partial_closure_accum.dispatch.clos0_arg2_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
  bb0:
    %Sy_oir_dp_clos:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
    %Sy_oir_accum_dp_id:i64 = %Sy_oir_dp_id:i64 + %Sy_oir_dp_clos:i64
    %Sy_rir_raw_tmp_0:obj_ptr = obj_get(%Sy_oir_clos:obj_ptr, 2:i64):obj_ptr
    %Sy_oir_p_clos:obj_ptr = #runtime_call syli_rt_ownership_share(%Sy_rir_raw_tmp_0:obj_ptr)
    %__sy_void:void = #runtime_call syli_rt_ownership_release(%Sy_oir_clos:obj_ptr)
    %Sy_oir_p_accum:fn_ptr = obj_get(%Sy_oir_p_clos:obj_ptr, 0:i64):fn_ptr
    %Sy_oir_rst:i64 = #call_indirect %Sy_oir_p_accum:fn_ptr (%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_p_clos:obj_ptr, %Sy_oir_accum_dp_id:i64)
    return %Sy_oir_rst:i64
  end
  
  
  private fn __wrapper.syliTest_multi.add.i64_f64_f64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_x2:i64) -> i64:
    entry: bb0
  
  bb0:
    %Sy_oir_s1:f64 = bitcast(%Sy_oir_x1:i64 as f64)
    %Sy_oir_s2:f64 = bitcast(%Sy_oir_x2:i64 as f64)
    %Sy_oir_rst:i64 = #call_direct syliTest_multi.add__i64__f64__f64_ret_i64 (%Sy_oir_x0:i64, %Sy_oir_s1:f64, %Sy_oir_s2:f64)
    return %Sy_oir_rst:i64
  end
  
  
  private fn __wrapper.syliTest_multi.add.i64_i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_x2:i64) -> i64:
    entry: bb0
  
  bb0:
    %Sy_oir_rst:i64 = #call_direct syliTest_multi.add__i64__i64__i64_ret_i64 (%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_x2:i64)
    return %Sy_oir_rst:i64
  end
  

  $ dune exec sylic -- llvm test_multi.sy
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
    ret void
  }
  
  define void @syliTest_multi.main() gc "statepoint-example" {
  bb0:
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_0 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621890, i32 1, i32 2)
    ; nop
    %Sy_oir_accum_fn_0 = bitcast ptr @__make_closure_accum.dispatch.61_ret_i64 to ptr
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_0, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i32 1
    store i64 1, ptr addrspace(1) %Sy_llvm_tmp_3
    ; nop
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_1 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 4251398048237748355, i32 1, i32 3)
    ; nop
    %Sy_oir_accum_fn_1 = bitcast ptr @__partial_closure_accum.dispatch.clos0_arg2_ret_i64 to ptr
    %Sy_llvm_tmp_4 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_1)
    %Sy_llvm_tmp_5 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_4, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_1, ptr addrspace(1) %Sy_llvm_tmp_5
    %Sy_llvm_tmp_6 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_1)
    %Sy_llvm_tmp_7 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_6, i32 0, i32 2, i32 1
    store i64 1, ptr addrspace(1) %Sy_llvm_tmp_7
    %Sy_llvm_tmp_8 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_1)
    %Sy_llvm_tmp_9 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_8, i32 0, i32 2, i32 2
    %Sy_oir_release_tmp_1 = load ptr addrspace(1), ptr addrspace(1) %Sy_llvm_tmp_9
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_release_tmp_1)
    %Sy_rir_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_share(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_10 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_1)
    %Sy_llvm_tmp_11 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_10, i32 0, i32 2, i32 2
    store ptr addrspace(1) %Sy_rir_tmp_0, ptr addrspace(1) %Sy_llvm_tmp_11
    call void @syli_rt_ownership_notify_mutation(ptr addrspace(1) %Sy_cir_var_1, ptr addrspace(1) %Sy_rir_tmp_0)
    ; nop
    %Sy_cir_var_2 = call i64 @syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(ptr addrspace(1) %Sy_cir_var_1, i64 3, i64 4)
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
    %Sy_cir_var_4 = call i64 @syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64(ptr addrspace(1) %Sy_cir_var_3, double 1., double 2.)
    ret void
  }
  
  define i64 @syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64(ptr addrspace(1) %f, double %x, double %y) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %f)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i32 0
    %Sy_accum_ptr_0 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_apply_cast_1 = bitcast double %x to i64
    %Sy_apply_cast_2 = bitcast double %y to i64
    %Sy_cir_var_0 = call i64 %Sy_accum_ptr_0(i64 %Sy_apply_cast_1, i64 %Sy_apply_cast_2, ptr addrspace(1) %f, i64 0)
    ; nop
    ret i64 %Sy_cir_var_0
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
  
  define i64 @syliTest_multi.add__i64__i64__i64_ret_i64(i64 %x, i64 %y, i64 %z) gc "statepoint-example" {
  bb0:
    ret i64 %x
  }
  
  define i64 @syliTest_multi.add__i64__f64__f64_ret_i64(i64 %x, double %y, double %z) gc "statepoint-example" {
  bb0:
    ret i64 %x
  }
  
  define i64 @__make_closure_accum.dispatch.61_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb-1:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_oir_imm0 = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    switch i64 %Sy_oir_dp_id, label %switch_default_unreachable [
      i64 0, label %bb0
      i64 1, label %bb1
    ]
  bb0:
    %Sy_oir_case_result0 = call i64 @__wrapper.syliTest_multi.add.i64_f64_f64_ret_i64(i64 %Sy_oir_imm0, i64 %Sy_oir_x0, i64 %Sy_oir_x1)
    ret i64 %Sy_oir_case_result0
  bb1:
    %Sy_oir_case_result1 = call i64 @__wrapper.syliTest_multi.add.i64_i64_i64_ret_i64(i64 %Sy_oir_imm0, i64 %Sy_oir_x0, i64 %Sy_oir_x1)
    ret i64 %Sy_oir_case_result1
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
  
  define i64 @__wrapper.syliTest_multi.add.i64_f64_f64_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, i64 %Sy_oir_x2) gc "statepoint-example" {
  bb0:
    %Sy_oir_s1 = bitcast i64 %Sy_oir_x1 to double
    %Sy_oir_s2 = bitcast i64 %Sy_oir_x2 to double
    %Sy_oir_rst = call i64 @syliTest_multi.add__i64__f64__f64_ret_i64(i64 %Sy_oir_x0, double %Sy_oir_s1, double %Sy_oir_s2)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__wrapper.syliTest_multi.add.i64_i64_i64_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, i64 %Sy_oir_x2) gc "statepoint-example" {
  bb0:
    %Sy_oir_rst = call i64 @syliTest_multi.add__i64__i64__i64_ret_i64(i64 %Sy_oir_x0, i64 %Sy_oir_x1, i64 %Sy_oir_x2)
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
  
