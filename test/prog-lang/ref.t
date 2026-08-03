Store a named function in a ref and use it:
  $ cat >test_ref.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > fn twice x = x * 2
  > fn main () =
  >   let f = ref twice
  >   let g = *f
  >   syli_print_i64(g 21)
  > EOF
  $ dune exec sylic -- cir test_ref.sy
  module Test_ref :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_ref() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_ref.main() -> void:
    entry: bb0
  
    bb0:
      %Sy_var0:ref{{card=1 [0:(i64 -> i64)]} tag=- unknown_cyclic} = object_create{size=1:i64}
      %Sy_var1:(i64 -> i64) = #make_closure {syliTest_ref.twice} () ()
      obj_set(%Sy_var0:obj_ptr, 0:i64, %Sy_var1:(i64 -> i64)):(i64 -> i64)
      %Sy_var2:(i64 -> i64) = obj_get(%Sy_var0:obj_ptr, 0:i64):(i64 -> i64)
      %Sy_var3:i64 = #call_apply {%Sy_var2:(i64 -> i64)}  (21:i64)
      %Sy_var4:void = #call_direct syliTest_ref.syli_print_i64 (%Sy_var3:i64)
      return
  end
  
  public fn syliTest_ref.twice(%x:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = %x:i64 * 2:i64
      return %Sy_var0:i64
  end
  
  end

  $ dune exec sylic -- oir test_ref.sy
  module Test_ref :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_ref() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_ref.main() -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_var0:ref{{card=1 [0:obj_ptr]} tag=- unknow_cyclic} = object_create{size=1:i64}
      
      gc_cycle
      %Sy_var1:obj{{card=1 [0:fn_ptr]} tag=0 unknow_cyclic} = object_create{size=1:i32}
      
      %Sy_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.syliTest_ref.twice.37_ret_i64)
      obj_set(%Sy_var1:obj_ptr, 0:i32, %Sy_accum_fn_0:fn_ptr):fn_ptr
      
      %Sy_release_tmp_1:obj_ptr = @transfer obj_get(%Sy_var0:obj_ptr, 0:i64):obj_ptr
      release(%Sy_release_tmp_1:obj_ptr)
      obj_set(%Sy_var0:obj_ptr, 0:i64, @own %Sy_var1:obj_ptr):obj_ptr
      %Sy_var2:obj_ptr = @share obj_get(%Sy_var0:obj_ptr, 0:i64):obj_ptr
      release(%Sy_var0:obj_ptr)
      %Sy_accum_ptr_1:fn_ptr = obj_get(%Sy_var2:obj_ptr, 0:i32):fn_ptr
      %Sy_var3:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_1:fn_ptr)  (21:i64, @transfer %Sy_var2:obj_ptr, 0:i64)
      
      %Sy_var4:void = #call_direct syliTest_ref.syli_print_i64 (%Sy_var3:i64)
      return
  end
  
  public fn syliTest_ref.twice(%x:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = %x:i64 * 2:i64
      return %Sy_var0:i64
  end
  
  private fn __make_closure_accum.syliTest_ref.twice.37_ret_i64(%Sy_x0:i64, %Sy_clos:obj_ptr, %Sy_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      release(%Sy_clos:obj_ptr)
      %Sy_rst:i64 = #call_direct __wrapper.syliTest_ref.twice.i64_ret_i64 (%Sy_x0:i64)
      return %Sy_rst:i64
  end
  
  private fn __wrapper.syliTest_ref.twice.i64_ret_i64(%Sy_x0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_s0:i64 = cast(%Sy_x0:i64 as i64)
      %Sy_rst:i64 = #call_direct syliTest_ref.twice (%Sy_s0:i64)
      return %Sy_rst:i64
  end
  
  end
