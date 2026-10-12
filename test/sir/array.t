Array literal/alloc/index get/set lower to CIR:
  $ cat >arr.sy <<EOF
  > let a = [| 1; 2; 3 |]
  > let b = a.[0]
  > let _ = a.[1] := 42
  > let c = [| 4: fun i -> i |]
  > EOF
  $ dune exec sylic cir arr.sy
  module Arr :
  globals:
  global public syliArr.a : obj_ptr = null init=__init_global.syliArr.a
  global public syliArr.b : i64 = null init=__init_global.syliArr.b
  global public syliArr.c : obj_ptr = null init=__init_global.syliArr.c
  
  
  functions:
  public fn __init.Arr() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:obj_ptr = #call_direct __init_global.syliArr.a ()
      store_global syliArr.a = %__sy_cir_init_tmp_0:obj_ptr
      %__sy_cir_init_tmp_1:i64 = #call_direct __init_global.syliArr.b ()
      store_global syliArr.b = %__sy_cir_init_tmp_1:i64
      %__sy_cir_init_tmp_2:void = #call_direct __init_global.syliArr.sy1_any_pat ()
      %__sy_cir_init_tmp_3:obj_ptr = #call_direct __init_global.syliArr.c ()
      store_global syliArr.c = %__sy_cir_init_tmp_3:obj_ptr
      return
  end
  
  private fn __init_global.syliArr.c() -> obj_ptr:
    entry: bb0
  
    bb0:
      %__sy_cir_lambda_57:(i64 -> i64) = #make_closure {__sy_cir_lambda_57} () ()
      %Sy_cir_var_0:obj{[array_elt=i64] tag=- acyclic} = object_create{size=4:i64}
      %Sy_cir_var_1:i64 = move(0:i64)
      goto bb1
  
    bb1:
      %Sy_cir_var_2:bool = %Sy_cir_var_1:i64 < 4:i64
      cond_br %Sy_cir_var_2:bool, bb2, bb3
  
    bb3:
  
      return %Sy_cir_var_0:obj_ptr
  
    bb2:
      %Sy_cir_var_3:i64 = #call_apply {%__sy_cir_lambda_57:(i64 -> i64)}  (%Sy_cir_var_1:i64)
      obj_set(%Sy_cir_var_0:obj_ptr, %Sy_cir_var_1:i64, %Sy_cir_var_3:i64):i64
      %Sy_cir_var_4:i64 = %Sy_cir_var_1:i64 + 1:i64
      %Sy_cir_var_1:i64 = move(%Sy_cir_var_4:i64)
      goto bb1
  end
  
  private fn __init_global.syliArr.sy1_any_pat() -> void:
    entry: bb0
  
    bb0:
      obj_set(%syliArr.a:obj_ptr, 1:i64, 42:i64):i64
      return
  end
  
  private fn __init_global.syliArr.b() -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = obj_get(%syliArr.a:obj_ptr, 0:i64):i64
      return %Sy_cir_var_0:i64
  end
  
  private fn __init_global.syliArr.a() -> obj_ptr:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:obj{[array_elt=i64] tag=- acyclic} = object_create{size=3:i64}
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i64, 1:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i64, 2:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, 2:i64, 3:i64):i64
      return %Sy_cir_var_0:obj_ptr
  end
  
  public fn __sy_cir_lambda_57(%i:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %i:i64
  end
  
  end

  $ dune exec -- sylic oir arr.sy
  module Arr :
  globals:
  global public syliArr.a : obj_ptr = null init=__init_global.syliArr.a
  global public syliArr.b : i64 = null init=__init_global.syliArr.b
  global public syliArr.c : obj_ptr = null init=__init_global.syliArr.c
  
  
  functions:
  public fn __init.Arr() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:obj_ptr = #call_direct __init_global.syliArr.a ()
      store_global syliArr.a = @transfer %__sy_cir_init_tmp_0:obj_ptr
      %__sy_cir_init_tmp_1:i64 = #call_direct __init_global.syliArr.b ()
      store_global syliArr.b = %__sy_cir_init_tmp_1:i64
      %__sy_cir_init_tmp_2:void = #call_direct __init_global.syliArr.sy1_any_pat ()
      %__sy_cir_init_tmp_3:obj_ptr = #call_direct __init_global.syliArr.c ()
      store_global syliArr.c = @transfer %__sy_cir_init_tmp_3:obj_ptr
      return
  end
  
  private fn __init_global.syliArr.c() -> obj_ptr:
    entry: bb0
  
    bb0:
      gc_cycle
      %__sy_cir_lambda_57:obj{{card=1 [0:fn_ptr]} tag=0 unknown_cyclic} = object_create{size=1:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.__sy_cir_lambda_57.65_ret_i64)
      obj_set(%__sy_cir_lambda_57:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      
      gc_cycle
      %Sy_cir_var_0:obj{[array_elt=i64] tag=- acyclic} = object_create{size=4:i64}
      
      %Sy_cir_var_1:i64 = move(0:i64)
      goto bb1
  
    bb1:
      %Sy_cir_var_2:bool = %Sy_cir_var_1:i64 < 4:i64
      cond_br %Sy_cir_var_2:bool, bb2, bb3
  
    bb3:
      release(%__sy_cir_lambda_57:obj_ptr)
      return @own %Sy_cir_var_0:obj_ptr
  
    bb2:
      %Sy_accum_ptr_1:fn_ptr = obj_get(%__sy_cir_lambda_57:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_3:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_1:fn_ptr)  (%Sy_cir_var_1:i64, @borrow %__sy_cir_lambda_57:obj_ptr, 0:i64)
      
      obj_set(%Sy_cir_var_0:obj_ptr, %Sy_cir_var_1:i64, %Sy_cir_var_3:i64):i64
      %Sy_cir_var_4:i64 = %Sy_cir_var_1:i64 + 1:i64
      %Sy_cir_var_1:i64 = move(%Sy_cir_var_4:i64)
      goto bb1
  end
  
  private fn __init_global.syliArr.sy1_any_pat() -> void:
    entry: bb0
  
    bb0:
      obj_set(%syliArr.a:obj_ptr, 1:i64, 42:i64):i64
      release(%syliArr.a:obj_ptr)
      return
  end
  
  private fn __init_global.syliArr.b() -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = obj_get(%syliArr.a:obj_ptr, 0:i64):i64
      return %Sy_cir_var_0:i64
  end
  
  private fn __init_global.syliArr.a() -> obj_ptr:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:obj{[array_elt=i64] tag=- acyclic} = object_create{size=3:i64}
      
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i64, 1:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i64, 2:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, 2:i64, 3:i64):i64
      return @own %Sy_cir_var_0:obj_ptr
  end
  
  public fn __sy_cir_lambda_57(%i:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %i:i64
  end
  
  private fn __make_closure_accum.__sy_cir_lambda_57.65_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.__sy_cir_lambda_57.i64_ret_i64 (%Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.__sy_cir_lambda_57.i64_ret_i64(%Sy_oir_x0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct __sy_cir_lambda_57 (%Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  end
