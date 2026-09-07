Object reused after being passed as an applied argument to a closure:
  $ cat >live_after.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > type box = { mutable value: i64 }
  > let mk v f = f v
  > let main () =
  >   let b = { value = 40 }
  >   let go v f = mk v f
  >   let r = go b (fun (x : box) -> x.value)
  >   syli_print_i64 (r + b.value)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build live_after.sy
  $ ./live_after.exe
  80

  $ dune exec sylic -- oir live_after.sy
  module Live_after :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Live_after() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:void = #call_direct __init_global.syliLive_after.sy4_any_pat ()
      return
  end
  
  private fn __init_global.syliLive_after.sy4_any_pat() -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:void = #call_direct syliLive_after.main (0:i64)
      return
  end
  
  public fn syliLive_after.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:syliLive_after.box{{card=1 [0:i64]} tag=- unknow_cyclic} = object_create{size=1:i64}
      
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i64, 40:i64):i64
      gc_cycle
      %sy2_go:obj{{card=1 [0:fn_ptr]} tag=0 unknow_cyclic} = object_create{size=1:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.sy2_go.91_ret_i64)
      obj_set(%sy2_go:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      
      gc_cycle
      %__sy_cir_lambda_115:obj{{card=1 [0:fn_ptr]} tag=0 unknow_cyclic} = object_create{size=1:i32}
      
      %Sy_oir_accum_fn_1:fn_ptr = addr_fn(__make_closure_accum.__sy_cir_lambda_115.128_ret_i64)
      obj_set(%__sy_cir_lambda_115:obj_ptr, 0:i32, %Sy_oir_accum_fn_1:fn_ptr):fn_ptr
      
      %Sy_accum_ptr_2:fn_ptr = obj_get(%sy2_go:obj_ptr, 0:i32):fn_ptr
      %Sy_apply_cast_3:i64 = @borrow cast(%Sy_cir_var_0:obj_ptr as i64)
      %Sy_apply_cast_4:i64 = @transfer cast(%__sy_cir_lambda_115:obj_ptr as i64)
      %Sy_cir_var_1:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_2:fn_ptr)  (%Sy_apply_cast_3:i64, %Sy_apply_cast_4:i64, @transfer %sy2_go:obj_ptr, 0:i64)
      
      %Sy_cir_var_2:i64 = obj_get(%Sy_cir_var_0:obj_ptr, 0:i64):i64
      release(%Sy_cir_var_0:obj_ptr)
      %Sy_cir_var_3:i64 = #call_direct "syliLive_after.+" (%Sy_cir_var_1:i64, %Sy_cir_var_2:i64)
      %Sy_cir_var_4:void = #call_direct syliLive_after.syli_print_i64 (%Sy_cir_var_3:i64)
      return
  end
  
  public fn __sy_cir_lambda_115(%x:obj_ptr) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = obj_get(%x:obj_ptr, 0:i64):i64
      release(%x:obj_ptr)
      return %Sy_cir_var_0:i64
  end
  
  public fn "syliLive_after.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  private fn sy2_go__obj_syliLive_after.box__fn_obj_syliLive_after.box_i64_ret_i64(%v:obj_ptr, %f:obj_ptr) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct syliLive_after.mk__obj_syliLive_after.box__fn_obj_syliLive_after.box_i64_ret_i64 (@transfer %v:obj_ptr, @transfer %f:obj_ptr)
      return %Sy_cir_var_0:i64
  end
  
  public fn syliLive_after.mk__obj_syliLive_after.box__fn_obj_syliLive_after.box_i64_ret_i64(%v:obj_ptr, %f:obj_ptr) -> i64:
    entry: bb0
  
    bb0:
      %Sy_accum_ptr_0:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
      %Sy_apply_cast_1:i64 = @transfer cast(%v:obj_ptr as i64)
      %Sy_cir_var_0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_0:fn_ptr)  (%Sy_apply_cast_1:i64, @transfer %f:obj_ptr, 0:i64)
      
      return %Sy_cir_var_0:i64
  end
  
  private fn __make_closure_accum.__sy_cir_lambda_115.128_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.__sy_cir_lambda_115.obj_syliLive_after.box_i64_ret_i64 (%Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __make_closure_accum.sy2_go.91_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.sy2_go.obj_syliLive_after.box_i64_obj_ptr_ret_i64 (%Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.__sy_cir_lambda_115.obj_syliLive_after.box_i64_ret_i64(%Sy_oir_x0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_s0:obj_ptr = cast(%Sy_oir_x0:i64 as obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __sy_cir_lambda_115 (@transfer %Sy_oir_s0:obj_ptr)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.sy2_go.obj_syliLive_after.box_i64_obj_ptr_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_s0:obj_ptr = cast(%Sy_oir_x0:i64 as obj_ptr)
      %Sy_oir_s1:obj_ptr = cast(%Sy_oir_x1:i64 as obj_ptr)
      %Sy_oir_rst:i64 = #call_direct sy2_go__obj_syliLive_after.box__fn_obj_syliLive_after.box_i64_ret_i64 (@transfer %Sy_oir_s0:obj_ptr, @transfer %Sy_oir_s1:obj_ptr)
      return %Sy_oir_rst:i64
  end
  
  end
