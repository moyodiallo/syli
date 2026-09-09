Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let result =
  >     if true then
  >       apply add1 3 4
  >     else apply add1 1.0 2.0
  > EOF
  $ dune exec sylic -- cir_raw test_multi.sy
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
      %Sy_cir_var_1:bool = cast(true:bool as bool)
      cond_br %Sy_cir_var_1:bool, bb1, bb2
  
    bb1:
      %Sy_cir_var_3:(i64, i64 -> i64) = cast(%Sy_cir_var_0:(?89, ?90 -> i64) as (i64, i64 -> i64))
      %Sy_cir_var_4:i64 = #call_direct syliTest_multi.apply (%Sy_cir_var_3:(i64, i64 -> i64), 3:i64, 4:i64)
      %Sy_cir_var_2:i64 = move(%Sy_cir_var_4:i64)
      goto bb3
  
    bb2:
      %Sy_cir_var_5:(f64, f64 -> i64) = cast(%Sy_cir_var_0:(?89, ?90 -> i64) as (f64, f64 -> i64))
      %Sy_cir_var_6:i64 = #call_direct syliTest_multi.apply (%Sy_cir_var_5:(f64, f64 -> i64), 1.0f:f64, 2.0f:f64)
      %Sy_cir_var_2:i64 = move(%Sy_cir_var_6:i64)
      goto bb3
  
    bb3:
  
      return
  end
  
  public fn syliTest_multi.add(%x:?80, %y:?82, %z:?84) -> ?80:
    entry: bb0
  
    bb0:
  
      return %x:?80
  end
  
  public fn syliTest_multi.apply(%f:(?72, ?74 -> ?78), %x:?72, %y:?74) -> ?78:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:?78 = #call_apply {%f:(?72, ?74 -> ?78)}  (%x:?72, %y:?74)
      return %Sy_cir_var_0:?78
  end
  
  end

  $ dune exec sylic -- typing test_multi.sy
  Typed test_multi.sy successfully: module Test_multi with 3 top-level typed items
  Type Environment:
  {
    add : forall '80 '82 '84. '80 -> '82 -> '84 -> '80
    apply : forall '72 '74 '78. '72 -> '74 -> '78 -> '72 -> '74 -> '78
    main : unit -> unit
  }

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
      
      %Sy_cir_var_1:bool = cast(true:bool as bool)
      cond_br %Sy_cir_var_1:bool, bb1, bb2
  
    bb2:
      gc_cycle
      %Sy_cir_var_5:obj{{card=3 [0:fn_ptr; 1:i64; 2:obj_ptr]} tag=0 unknow_cyclic} = object_create{size=3:i32}
      
      %Sy_oir_accum_fn_1:fn_ptr = addr_fn(__partial_closure_accum.dispatch.clos0_arg2_ret_i64)
      obj_set(%Sy_cir_var_5:obj_ptr, 0:i32, %Sy_oir_accum_fn_1:fn_ptr):fn_ptr
      obj_set(%Sy_cir_var_5:obj_ptr, 1:i32, 1:i64):i64
      %Sy_oir_release_tmp_1:obj_ptr = @transfer obj_get(%Sy_cir_var_5:obj_ptr, 2:i32):obj_ptr
      release(%Sy_oir_release_tmp_1:obj_ptr)
      obj_set(%Sy_cir_var_5:obj_ptr, 2:i32, @own %Sy_cir_var_0:obj_ptr):obj_ptr
      
      %Sy_cir_var_6:i64 = #call_direct syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64 (@transfer %Sy_cir_var_5:obj_ptr, 1.0f:f64, 2.0f:f64)
      %Sy_cir_var_2:i64 = move(%Sy_cir_var_6:i64)
      goto bb3
  
    bb1:
      gc_cycle
      %Sy_cir_var_3:obj{{card=2 [0:fn_ptr; 1:obj_ptr]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_2:fn_ptr = addr_fn(__partial_closure_accum.clos0_arg2_ret_i64)
      obj_set(%Sy_cir_var_3:obj_ptr, 0:i32, %Sy_oir_accum_fn_2:fn_ptr):fn_ptr
      %Sy_oir_release_tmp_2:obj_ptr = @transfer obj_get(%Sy_cir_var_3:obj_ptr, 1:i32):obj_ptr
      release(%Sy_oir_release_tmp_2:obj_ptr)
      obj_set(%Sy_cir_var_3:obj_ptr, 1:i32, @own %Sy_cir_var_0:obj_ptr):obj_ptr
      
      %Sy_cir_var_4:i64 = #call_direct syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64 (@transfer %Sy_cir_var_3:obj_ptr, 3:i64, 4:i64)
      %Sy_cir_var_2:i64 = move(%Sy_cir_var_4:i64)
      goto bb3
  
    bb3:
  
      return
  end
  
  public fn syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(%f:obj_ptr, %x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_accum_ptr_0:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_0:fn_ptr)  (%x:i64, %y:i64, @transfer %f:obj_ptr, 0:i64)
      
      return %Sy_cir_var_0:i64
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
      switch %Sy_oir_dp_id:i64 [1: bb1, 0: bb0]
  
    bb1:
      %Sy_oir_case_result1:i64 = #call_direct __wrapper.syliTest_multi.add.i64_f64_f64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_case_result1:i64
  
    bb0:
      %Sy_oir_case_result0:i64 = #call_direct __wrapper.syliTest_multi.add.i64_i64_i64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_case_result0:i64
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
