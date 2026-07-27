Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > let apply f x y = f x y
  > let add x y z = y
  > fn main () =
  >   let add1 = add 1
  >   let result =
  >     if false then
  >       apply add1 3 4
  >     else apply add1 7 2.0
  >   syli_print_i64 result
  > EOF
  $ dune exec sylic -- build test_multi.sy
  $ ./test_multi.exe
  7

Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > let apply f x y = f x y
  > let add x y z = x
  > fn main () =
  >   let add1 = add 1
  >   let result = apply add1 3 4
  >   let result2 = apply add1 1.0 2.0
  >   syli_print_i64 result
  > EOF
  $ dune exec sylic -- build test_multi.sy
  $ ./test_multi.exe
  1

Closure with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > let add x y = x + y
  > let apply f x y = f x y
  > fn main () = 
  >   let result = apply add 3 4
  >   syli_print_i64(result)
  > EOF
  $ dune exec sylic -- build test_multi.sy test_multi.opt.exe
  $ ./test_multi.opt.exe
  7

Complex test combining closures, dispatch, casts, partial application, and if-then-else:
  $ cat >complex_dispatch.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > let add x y z = x
  > let apply f x y = f x y
  > fn main () =
  >   let add1 = add 1
  >   let r1 = apply add1 10 20
  >   syli_print_i64 r1
  >   let r2 = apply add1 1.0 2.0
  >   syli_print_i64 r2
  >   let add1and2 = add1 2
  >   let r3 = add1and2 30
  >   syli_print_i64 r3
  >   let r4 = add1and2 3.0
  >   syli_print_i64 r4
  >   let r5 =
  >     if true then
  >       apply add1 100 200
  >     else
  >       apply add1 1.0 2.0
  >   syli_print_i64 r5
  > EOF

  $ dune exec sylic -- oir complex_dispatch.sy
  module Complex_dispatch :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Complex_dispatch() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliComplex_dispatch.main() -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_var0:*void = object_create{size=2:i32 record{fields=2 tag=0 [fn_ptr; i64]}}
      
      %Sy_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.dispatch.66_ret_i64)
      obj_set(%Sy_var0:*void, 0:i32, %Sy_accum_fn_0:fn_ptr):fn_ptr
      obj_set(%Sy_var0:*void, 1:i32, 1:i64):i64
      
      gc_cycle
      %Sy_var1:*void = object_create{size=3:i32 record{fields=3 tag=0 [fn_ptr; i64; *void]}}
      
      %Sy_accum_fn_1:fn_ptr = addr_fn(__partial_closure_accum.dispatch.clos0_arg2_ret_i64)
      obj_set(%Sy_var1:*void, 0:i32, %Sy_accum_fn_1:fn_ptr):fn_ptr
      obj_set(%Sy_var1:*void, 1:i32, 5:i64):i64
      %Sy_release_tmp_1:*void = @transfer obj_get(%Sy_var1:*void, 2:i32):*void
      release(%Sy_release_tmp_1:*void)
      obj_set(%Sy_var1:*void, 2:i32, @share %Sy_var0:*void):*void
      
      %Sy_var2:i64 = #call_direct syliComplex_dispatch.apply__fn_i64_i64_i64__i64__i64_ret_i64 (@transfer %Sy_var1:*void, 10:i64, 20:i64)
      %Sy_var3:void = #call_direct syliComplex_dispatch.syli_print_i64 (%Sy_var2:i64)
      gc_cycle
      %Sy_var4:*void = object_create{size=3:i32 record{fields=3 tag=0 [fn_ptr; i64; *void]}}
      
      %Sy_accum_fn_2:fn_ptr = addr_fn(__partial_closure_accum.dispatch.clos0_arg2_ret_i64)
      obj_set(%Sy_var4:*void, 0:i32, %Sy_accum_fn_2:fn_ptr):fn_ptr
      obj_set(%Sy_var4:*void, 1:i32, 4:i64):i64
      %Sy_release_tmp_2:*void = @transfer obj_get(%Sy_var4:*void, 2:i32):*void
      release(%Sy_release_tmp_2:*void)
      obj_set(%Sy_var4:*void, 2:i32, @share %Sy_var0:*void):*void
      
      %Sy_var5:i64 = #call_direct syliComplex_dispatch.apply__fn_f64_f64_i64__f64__f64_ret_i64 (@transfer %Sy_var4:*void, 1.0f:f64, 2.0f:f64)
      %Sy_var6:void = #call_direct syliComplex_dispatch.syli_print_i64 (%Sy_var5:i64)
      gc_cycle
      %Sy_var7:*void = object_create{size=4:i32 record{fields=4 tag=0 [fn_ptr; i64; *void; i64]}}
      
      %Sy_accum_fn_3:fn_ptr = addr_fn(__partial_closure_accum.dispatch.clos1_arg1_ret_i64)
      obj_set(%Sy_var7:*void, 0:i32, %Sy_accum_fn_3:fn_ptr):fn_ptr
      obj_set(%Sy_var7:*void, 1:i32, 2:i64):i64
      %Sy_release_tmp_3:*void = @transfer obj_get(%Sy_var7:*void, 2:i32):*void
      release(%Sy_release_tmp_3:*void)
      obj_set(%Sy_var7:*void, 2:i32, @share %Sy_var0:*void):*void
      obj_set(%Sy_var7:*void, 3:i32, 2:i64):i64
      
      %Sy_accum_ptr_4:fn_ptr = obj_get(%Sy_var7:*void, 0:i32):fn_ptr
      %Sy_var8:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_4:fn_ptr)  (30:i64, @borrow %Sy_var7:*void, 1:i64)
      
      %Sy_var9:void = #call_direct syliComplex_dispatch.syli_print_i64 (%Sy_var8:i64)
      %Sy_accum_ptr_5:fn_ptr = obj_get(%Sy_var7:*void, 0:i32):fn_ptr
      %Sy_apply_cast_6:i64 = cast(3.0f:f64 as i64)
      %Sy_var10:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_5:fn_ptr)  (%Sy_apply_cast_6:i64, @transfer %Sy_var7:*void, 0:i64)
      
      %Sy_var11:void = #call_direct syliComplex_dispatch.syli_print_i64 (%Sy_var10:i64)
      %Sy_var12:bool = cast(true:bool as bool)
      cond_br %Sy_var12:bool, bb1, bb2
  
    bb2:
      gc_cycle
      %Sy_var16:*void = object_create{size=3:i32 record{fields=3 tag=0 [fn_ptr; i64; *void]}}
      
      %Sy_accum_fn_7:fn_ptr = addr_fn(__partial_closure_accum.dispatch.clos0_arg2_ret_i64)
      obj_set(%Sy_var16:*void, 0:i32, %Sy_accum_fn_7:fn_ptr):fn_ptr
      obj_set(%Sy_var16:*void, 1:i32, 1:i64):i64
      %Sy_release_tmp_4:*void = @transfer obj_get(%Sy_var16:*void, 2:i32):*void
      release(%Sy_release_tmp_4:*void)
      obj_set(%Sy_var16:*void, 2:i32, @own %Sy_var0:*void):*void
      
      %Sy_var17:i64 = #call_direct syliComplex_dispatch.apply__fn_f64_f64_i64__f64__f64_ret_i64 (@transfer %Sy_var16:*void, 1.0f:f64, 2.0f:f64)
      %Sy_var13:i64 = move(%Sy_var17:i64)
      goto bb3
  
    bb1:
      gc_cycle
      %Sy_var14:*void = object_create{size=2:i32 record{fields=2 tag=0 [fn_ptr; *void]}}
      
      %Sy_accum_fn_8:fn_ptr = addr_fn(__partial_closure_accum.clos0_arg2_ret_i64)
      obj_set(%Sy_var14:*void, 0:i32, %Sy_accum_fn_8:fn_ptr):fn_ptr
      %Sy_release_tmp_5:*void = @transfer obj_get(%Sy_var14:*void, 1:i32):*void
      release(%Sy_release_tmp_5:*void)
      obj_set(%Sy_var14:*void, 1:i32, @own %Sy_var0:*void):*void
      
      %Sy_var15:i64 = #call_direct syliComplex_dispatch.apply__fn_i64_i64_i64__i64__i64_ret_i64 (@transfer %Sy_var14:*void, 100:i64, 200:i64)
      %Sy_var13:i64 = move(%Sy_var15:i64)
      goto bb3
  
    bb3:
      %Sy_var18:void = #call_direct syliComplex_dispatch.syli_print_i64 (%Sy_var13:i64)
      return
  end
  
  public fn syliComplex_dispatch.apply__fn_f64_f64_i64__f64__f64_ret_i64(%f:*void, %x:f64, %y:f64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_accum_ptr_9:fn_ptr = obj_get(%f:*void, 0:i32):fn_ptr
      %Sy_apply_cast_10:i64 = cast(%x:f64 as i64)
      %Sy_apply_cast_11:i64 = cast(%y:f64 as i64)
      %Sy_var0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_9:fn_ptr)  (%Sy_apply_cast_10:i64, %Sy_apply_cast_11:i64, @transfer %f:*void, 0:i64)
      
      return %Sy_var0:i64
  end
  
  public fn syliComplex_dispatch.apply__fn_i64_i64_i64__i64__i64_ret_i64(%f:*void, %x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_accum_ptr_12:fn_ptr = obj_get(%f:*void, 0:i32):fn_ptr
      %Sy_var0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_12:fn_ptr)  (%x:i64, %y:i64, @transfer %f:*void, 0:i64)
      
      return %Sy_var0:i64
  end
  
  public fn syliComplex_dispatch.add__i64__i64__f64_ret_i64(%x:i64, %y:i64, %z:f64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  public fn syliComplex_dispatch.add__i64__i64__i64_ret_i64(%x:i64, %y:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  public fn syliComplex_dispatch.add__i64__f64__f64_ret_i64(%x:i64, %y:f64, %z:f64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  private fn __make_closure_accum.dispatch.66_ret_i64(%Sy_x0:i64, %Sy_x1:i64, %Sy_clos:*void, %Sy_dp_id:i64) -> i64:
    entry: bb-1
  
    bb-1:
      %Sy_val0:i64 = obj_get(%Sy_clos:*void, 1:i64):i64
      release(%Sy_clos:*void)
      switch %Sy_dp_id:i64 [1: bb1, 0: bb0, 2: bb2, 3: bb3, 4: bb4, 5: bb5]
  
    bb1:
      %Sy_case_result1:i64 = #call_direct __wrapper.syliComplex_dispatch.add.i64_f64_f64_ret_i64 (%Sy_val0:i64, %Sy_x0:i64, %Sy_x1:i64)
      return %Sy_case_result1:i64
  
    bb0:
      %Sy_case_result0:i64 = #call_direct __wrapper.syliComplex_dispatch.add.i64_i64_i64_ret_i64 (%Sy_val0:i64, %Sy_x0:i64, %Sy_x1:i64)
      return %Sy_case_result0:i64
  
    bb2:
      %Sy_case_result2:i64 = #call_direct __wrapper.syliComplex_dispatch.add.i64_i64_f64_ret_i64 (%Sy_val0:i64, %Sy_x0:i64, %Sy_x1:i64)
      return %Sy_case_result2:i64
  
    bb3:
      %Sy_case_result3:i64 = #call_direct __wrapper.syliComplex_dispatch.add.i64_i64_i64_ret_i64 (%Sy_val0:i64, %Sy_x0:i64, %Sy_x1:i64)
      return %Sy_case_result3:i64
  
    bb4:
      %Sy_case_result4:i64 = #call_direct __wrapper.syliComplex_dispatch.add.i64_f64_f64_ret_i64 (%Sy_val0:i64, %Sy_x0:i64, %Sy_x1:i64)
      return %Sy_case_result4:i64
  
    bb5:
      %Sy_case_result5:i64 = #call_direct __wrapper.syliComplex_dispatch.add.i64_i64_i64_ret_i64 (%Sy_val0:i64, %Sy_x0:i64, %Sy_x1:i64)
      return %Sy_case_result5:i64
  end
  
  private fn __partial_closure_accum.clos0_arg2_ret_i64(%Sy_x0:i64, %Sy_x1:i64, %Sy_clos:*void, %Sy_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_p_clos:*void = @share obj_get(%Sy_clos:*void, 1:i64):*void
      release(%Sy_clos:*void)
      %Sy_p_accum:fn_ptr = obj_get(%Sy_p_clos:*void, 0:i64):fn_ptr
      %Sy_rst:i64 = #call_direct_fn_ptr(%Sy_p_accum:fn_ptr)  (%Sy_x0:i64, %Sy_x1:i64, @transfer %Sy_p_clos:*void, %Sy_dp_id:i64)
      return %Sy_rst:i64
  end
  
  private fn __partial_closure_accum.dispatch.clos0_arg2_ret_i64(%Sy_x0:i64, %Sy_x1:i64, %Sy_clos:*void, %Sy_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_dp_clos:i64 = obj_get(%Sy_clos:*void, 1:i64):i64
      %Sy_accum_dp_id:i64 = %Sy_dp_id:i64 + %Sy_dp_clos:i64
      %Sy_p_clos:*void = @share obj_get(%Sy_clos:*void, 2:i64):*void
      release(%Sy_clos:*void)
      %Sy_p_accum:fn_ptr = obj_get(%Sy_p_clos:*void, 0:i64):fn_ptr
      %Sy_rst:i64 = #call_direct_fn_ptr(%Sy_p_accum:fn_ptr)  (%Sy_x0:i64, %Sy_x1:i64, @transfer %Sy_p_clos:*void, %Sy_accum_dp_id:i64)
      return %Sy_rst:i64
  end
  
  private fn __partial_closure_accum.dispatch.clos1_arg1_ret_i64(%Sy_x0:i64, %Sy_clos:*void, %Sy_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_dp_clos:i64 = obj_get(%Sy_clos:*void, 1:i64):i64
      %Sy_accum_dp_id:i64 = %Sy_dp_id:i64 + %Sy_dp_clos:i64
      %Sy_p_clos:*void = @share obj_get(%Sy_clos:*void, 2:i64):*void
      %Sy_p_accum:fn_ptr = obj_get(%Sy_p_clos:*void, 0:i64):fn_ptr
      %Sy_val0:i64 = obj_get(%Sy_clos:*void, 3:i64):i64
      release(%Sy_clos:*void)
      %Sy_rst:i64 = #call_direct_fn_ptr(%Sy_p_accum:fn_ptr)  (%Sy_val0:i64, %Sy_x0:i64, @transfer %Sy_p_clos:*void, %Sy_accum_dp_id:i64)
      return %Sy_rst:i64
  end
  
  private fn __wrapper.syliComplex_dispatch.add.i64_f64_f64_ret_i64(%Sy_x0:i64, %Sy_x1:i64, %Sy_x2:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_s0:i64 = cast(%Sy_x0:i64 as i64)
      %Sy_s1:f64 = cast(%Sy_x1:i64 as f64)
      %Sy_s2:f64 = cast(%Sy_x2:i64 as f64)
      %Sy_rst:i64 = #call_direct syliComplex_dispatch.add__i64__f64__f64_ret_i64 (%Sy_s0:i64, %Sy_s1:f64, %Sy_s2:f64)
      return %Sy_rst:i64
  end
  
  private fn __wrapper.syliComplex_dispatch.add.i64_i64_f64_ret_i64(%Sy_x0:i64, %Sy_x1:i64, %Sy_x2:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_s0:i64 = cast(%Sy_x0:i64 as i64)
      %Sy_s1:i64 = cast(%Sy_x1:i64 as i64)
      %Sy_s2:f64 = cast(%Sy_x2:i64 as f64)
      %Sy_rst:i64 = #call_direct syliComplex_dispatch.add__i64__i64__f64_ret_i64 (%Sy_s0:i64, %Sy_s1:i64, %Sy_s2:f64)
      return %Sy_rst:i64
  end
  
  private fn __wrapper.syliComplex_dispatch.add.i64_i64_i64_ret_i64(%Sy_x0:i64, %Sy_x1:i64, %Sy_x2:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_s0:i64 = cast(%Sy_x0:i64 as i64)
      %Sy_s1:i64 = cast(%Sy_x1:i64 as i64)
      %Sy_s2:i64 = cast(%Sy_x2:i64 as i64)
      %Sy_rst:i64 = #call_direct syliComplex_dispatch.add__i64__i64__i64_ret_i64 (%Sy_s0:i64, %Sy_s1:i64, %Sy_s2:i64)
      return %Sy_rst:i64
  end
  
  end

  $ dune exec sylic -- build complex_dispatch.sy
  $ ./complex_dispatch.exe
  11111

  $ cat >test_e2e_print.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > type person = { name: int64; age: int64 }
  > fn main () =
  >     let record = { name = 10; age = 30 }
  >     syli_print_i64(record.age)
  > EOF
  $ dune exec sylic -- build test_e2e_print.sy
  $ ./test_e2e_print.exe && echo
  30

Test 4: Compile, link, and run arithmetic binary
  $ cat >test_e2e_expr.sy <<EOF2
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > fn main () = syli_print_i64(100 + 23)
  > EOF2
  $ dune exec sylic -- build test_e2e_expr.sy
  $ ./test_e2e_expr.exe
  123
