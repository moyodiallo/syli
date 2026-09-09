Local lambda without captures runs end-to-end:
  $ cat >loc.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let main () =
  >   let f x = x + 1
  >   syli_print_i64 (f 6)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build loc.sy
  $ ./loc.exe
  7

Local lambda capturing a free variable runs end-to-end:
  $ cat >cap.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let main () =
  >   let n = 5
  >   let f x = n + x
  >   syli_print_i64 (f 7)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build cap.sy
  $ ./cap.exe
  12

Local lambda passed to a higher-order function:
  $ cat >ho.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let apply2 f x = f x
  > let main () =
  >   let inc x = x + 1
  >   syli_print_i64 (apply2 inc 10)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build ho.sy
  $ ./ho.exe
  11

Sole-unit function used as a value (0-arg closure, dispatch-only apply):
  $ cat >unit_value.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let g () = 42
  > let call f = f ()
  > let main () =
  >   let r = call g
  >   syli_print_i64 r
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build unit_value.sy
  $ ./unit_value.exe
  42

Partial application with a trailing unit argument:
  $ cat >trailing_unit.sy <<EOF
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
  $ dune exec sylic -- build trailing_unit.sy
  $ ./trailing_unit.exe
  2

Local closure capturing another local closure:
  $ cat >capture_closure.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let main () =
  >   let a = 3
  >   let f x = x + a
  >   let g x = f (f x)
  >   syli_print_i64 (g 1)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build capture_closure.sy
  $ ./capture_closure.exe
  7
  $ dune exec sylic -- oir capture_closure.sy
  module Capture_closure :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Capture_closure() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:void = #call_direct __init_global.syliCapture_closure.sy4_any_pat ()
      return
  end
  
  private fn __init_global.syliCapture_closure.sy4_any_pat() -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:void = #call_direct syliCapture_closure.main (0:i64)
      return
  end
  
  public fn syliCapture_closure.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %sy1_a:i64 = cast(3:i64 as i64)
      gc_cycle
      %sy2_f:obj{{card=2 [0:fn_ptr; 1:i64]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.dispatch.48_ret_i64)
      obj_set(%sy2_f:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      obj_set(%sy2_f:obj_ptr, 1:i32, %sy1_a:i64):i64
      
      gc_cycle
      %sy3_g:obj{{card=2 [0:fn_ptr; 1:obj_ptr]} tag=0 unknow_cyclic} = object_create{size=2:i32}
      
      %Sy_oir_accum_fn_1:fn_ptr = addr_fn(__make_closure_accum.sy3_g.75_ret_i64)
      obj_set(%sy3_g:obj_ptr, 0:i32, %Sy_oir_accum_fn_1:fn_ptr):fn_ptr
      %Sy_oir_release_tmp_1:obj_ptr = @transfer obj_get(%sy3_g:obj_ptr, 1:i32):obj_ptr
      release(%Sy_oir_release_tmp_1:obj_ptr)
      obj_set(%sy3_g:obj_ptr, 1:i32, @own %sy2_f:obj_ptr):obj_ptr
      
      %Sy_accum_ptr_2:fn_ptr = obj_get(%sy3_g:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_2:fn_ptr)  (1:i64, @transfer %sy3_g:obj_ptr, 0:i64)
      
      %Sy_cir_var_1:void = #call_direct syliCapture_closure.syli_print_i64 (%Sy_cir_var_0:i64)
      return
  end
  
  private fn sy2_f(%sy1_a:i64, %x:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliCapture_closure.+" (%x:i64, %sy1_a:i64)
      return %Sy_cir_var_0:i64
  end
  
  private fn sy3_g(%sy2_f:obj_ptr, %x:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_accum_ptr_0:fn_ptr = obj_get(%sy2_f:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_0:fn_ptr)  (%x:i64, @borrow %sy2_f:obj_ptr, 1:i64)
      
      %Sy_accum_ptr_1:fn_ptr = obj_get(%sy2_f:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_1:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_1:fn_ptr)  (%Sy_cir_var_0:i64, @transfer %sy2_f:obj_ptr, 0:i64)
      
      return %Sy_cir_var_1:i64
  end
  
  public fn "syliCapture_closure.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  private fn __make_closure_accum.dispatch.48_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb-1
  
    bb-1:
      %Sy_oir_imm0:i64 = obj_get(%Sy_oir_clos:obj_ptr, 1:i64):i64
      release(%Sy_oir_clos:obj_ptr)
      switch %Sy_oir_dp_id:i64 [0: bb0, 1: bb1]
  
    bb0:
      %Sy_oir_case_result0:i64 = #call_direct __wrapper.sy2_f.i64_i64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_case_result0:i64
  
    bb1:
      %Sy_oir_case_result1:i64 = #call_direct __wrapper.sy2_f.i64_i64_ret_i64 (%Sy_oir_imm0:i64, %Sy_oir_x0:i64)
      return %Sy_oir_case_result1:i64
  end
  
  private fn __make_closure_accum.sy3_g.75_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_obj0:obj_ptr = @share obj_get(%Sy_oir_clos:obj_ptr, 1:i64):obj_ptr
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.sy3_g.obj_ptr_i64_ret_i64 (@transfer %Sy_oir_obj0:obj_ptr, %Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.sy2_f.i64_i64_ret_i64(%Sy_oir_x0:i64, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct sy2_f (%Sy_oir_x0:i64, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.sy3_g.obj_ptr_i64_ret_i64(%Sy_oir_x0:obj_ptr, %Sy_oir_x1:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct sy3_g (@transfer %Sy_oir_x0:obj_ptr, %Sy_oir_x1:i64)
      return %Sy_oir_rst:i64
  end
  
  end
