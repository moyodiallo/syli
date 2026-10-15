Array literal/alloc/index get/set lower to CIR:
  $ cat >arr.sy <<EOF
  > primitive (index_get) : 'a array -> i64 -> 'a = "array_index_get"
  > primitive (index_set) : 'a array -> i64 -> 'a -> unit = "array_index_set"
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
      %__sy_cir_lambda_101:(i64 -> i64) = #make_closure {__sy_cir_lambda_101} () ()
      %Sy_cir_var_0:obj{[array_elt=i64] acyclic} = object_create{length=4:i64}
      %Sy_cir_var_1:i64 = move(0:i64)
      goto bb1
  
    bb1:
      %Sy_cir_var_2:bool = %Sy_cir_var_1:i64 < 4:i64
      cond_br %Sy_cir_var_2:bool, bb2, bb3
  
    bb3:
  
      return %Sy_cir_var_0:obj_ptr
  
    bb2:
      %Sy_cir_var_3:i64 = #call_apply {%__sy_cir_lambda_101:(i64 -> i64)}  (%Sy_cir_var_1:i64)
      obj_set(%Sy_cir_var_0:obj_ptr, array[%Sy_cir_var_1:i64], %Sy_cir_var_3:i64):i64
      %Sy_cir_var_4:i64 = %Sy_cir_var_1:i64 + 1:i64
      %Sy_cir_var_1:i64 = move(%Sy_cir_var_4:i64)
      goto bb1
  end
  
  private fn __init_global.syliArr.sy1_any_pat() -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:void = #call_direct syliArr.index_set__obj_obj_i64__i64__i64_ret_void (%syliArr.a:obj_ptr, 1:i64, 42:i64)
      return
  end
  
  private fn __init_global.syliArr.b() -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct syliArr.index_get__obj_obj_i64__i64_ret_i64 (%syliArr.a:obj_ptr, 0:i64)
      return %Sy_cir_var_0:i64
  end
  
  private fn __init_global.syliArr.a() -> obj_ptr:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:obj{[array_elt=i64] acyclic} = object_create{length=3:i64}
      obj_set(%Sy_cir_var_0:obj_ptr, array[0:i64], 1:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, array[1:i64], 2:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, array[2:i64], 3:i64):i64
      return %Sy_cir_var_0:obj_ptr
  end
  
  public fn __sy_cir_lambda_101(%i:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %i:i64
  end
  
  public fn syliArr.index_get__obj_obj_i64__i64_ret_i64(%x:obj_ptr, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = obj_get(%x:obj_ptr, array[%y:i64]):i64
      return %Sy_prim_result:i64
  end
  
  public fn syliArr.index_set__obj_obj_i64__i64__i64_ret_void(%x:obj_ptr, %y:i64, %z:i64) -> void:
    entry: bb0
  
    bb0:
      obj_set(%x:obj_ptr, array[%y:i64], %z:i64):i64
      return
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
      %__sy_cir_lambda_101:obj{{card=1 [0:fn_ptr]} unknown_cyclic} = object_create{length=1:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.__sy_cir_lambda_101.109_ret_i64)
      obj_set(%__sy_cir_lambda_101:obj_ptr, field[0], %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      
      gc_cycle
      %Sy_cir_var_0:obj{[array_elt=i64] acyclic} = object_create{length=4:i64}
      
      %Sy_cir_var_1:i64 = move(0:i64)
      goto bb1
  
    bb1:
      %Sy_cir_var_2:bool = %Sy_cir_var_1:i64 < 4:i64
      cond_br %Sy_cir_var_2:bool, bb2, bb3
  
    bb3:
      release(%__sy_cir_lambda_101:obj_ptr)
      return @own %Sy_cir_var_0:obj_ptr
  
    bb2:
      %Sy_accum_ptr_1:fn_ptr = obj_get(%__sy_cir_lambda_101:obj_ptr, field[0]):fn_ptr
      %Sy_cir_var_3:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_1:fn_ptr)  (%Sy_cir_var_1:i64, @borrow %__sy_cir_lambda_101:obj_ptr, 0:i64)
      
      obj_set(%Sy_cir_var_0:obj_ptr, array[%Sy_cir_var_1:i64], %Sy_cir_var_3:i64):i64
      %Sy_cir_var_4:i64 = %Sy_cir_var_1:i64 + 1:i64
      %Sy_cir_var_1:i64 = move(%Sy_cir_var_4:i64)
      goto bb1
  end
  
  private fn __init_global.syliArr.sy1_any_pat() -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:void = #call_direct syliArr.index_set__obj_obj_i64__i64__i64_ret_void (@transfer %syliArr.a:obj_ptr, 1:i64, 42:i64)
      return
  end
  
  private fn __init_global.syliArr.b() -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct syliArr.index_get__obj_obj_i64__i64_ret_i64 (@transfer %syliArr.a:obj_ptr, 0:i64)
      return %Sy_cir_var_0:i64
  end
  
  private fn __init_global.syliArr.a() -> obj_ptr:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:obj{[array_elt=i64] acyclic} = object_create{length=3:i64}
      
      obj_set(%Sy_cir_var_0:obj_ptr, array[0:i64], 1:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, array[1:i64], 2:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, array[2:i64], 3:i64):i64
      return @own %Sy_cir_var_0:obj_ptr
  end
  
  public fn __sy_cir_lambda_101(%i:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %i:i64
  end
  
  public fn syliArr.index_get__obj_obj_i64__i64_ret_i64(%x:obj_ptr, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = obj_get(%x:obj_ptr, array[%y:i64]):i64
      release(%x:obj_ptr)
      return %Sy_prim_result:i64
  end
  
  public fn syliArr.index_set__obj_obj_i64__i64__i64_ret_void(%x:obj_ptr, %y:i64, %z:i64) -> void:
    entry: bb0
  
    bb0:
      obj_set(%x:obj_ptr, array[%y:i64], %z:i64):i64
      release(%x:obj_ptr)
      return
  end
  
  private fn __make_closure_accum.__sy_cir_lambda_101.109_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.__sy_cir_lambda_101.i64_ret_i64 (%Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.__sy_cir_lambda_101.i64_ret_i64(%Sy_oir_x0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct __sy_cir_lambda_101 (%Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  end
