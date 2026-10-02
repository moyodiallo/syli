Variant constructor lowering — SIR.

An anonymous record payload is flattened into the constructor block:
  $ cat >test_ctor_anonrec.sy <<EOF
  > type shape = Rect of { w: i64; h: i64 }
  > let r = Rect { w = 7; h = 8 }
  > EOF
  $ dune exec sylic -- cir test_ctor_anonrec.sy
  module Test_ctor_anonrec :
  globals:
  global public syliTest_ctor_anonrec.r : obj_ptr = null init=__init_global.syliTest_ctor_anonrec.r
  
  
  functions:
  public fn __init.Test_ctor_anonrec() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:obj_ptr = #call_direct __init_global.syliTest_ctor_anonrec.r ()
      store_global syliTest_ctor_anonrec.r = %__sy_cir_init_tmp_0:obj_ptr
      return
  end
  
  private fn __init_global.syliTest_ctor_anonrec.r() -> obj_ptr:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:syliTest_ctor_anonrec.shape{{variant [0{0:i64; 1:i64}]} tag=0 acyclic} = object_create{size=2:i64}
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i64, 7:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, 1:i64, 8:i64):i64
      return %Sy_cir_var_0:obj_ptr
  end
  
  end

A mixed variant: the payload constructor is a tagged heap object, the constant
one is an immediate with the reserved `11` tag (`(tag << 2) | 3` = `3` for
tag 0):
  $ cat >test_ctor_mixed.sy <<EOF
  > type option = None | Some of i64
  > let a = Some 3
  > let b = None
  > EOF
  $ dune exec sylic -- cir test_ctor_mixed.sy
  module Test_ctor_mixed :
  globals:
  global public syliTest_ctor_mixed.a : obj_ptr = null init=__init_global.syliTest_ctor_mixed.a
  global public syliTest_ctor_mixed.b : obj_ptr = null init=__init_global.syliTest_ctor_mixed.b
  
  
  functions:
  public fn __init.Test_ctor_mixed() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:obj_ptr = #call_direct __init_global.syliTest_ctor_mixed.a ()
      store_global syliTest_ctor_mixed.a = %__sy_cir_init_tmp_0:obj_ptr
      %__sy_cir_init_tmp_1:obj_ptr = #call_direct __init_global.syliTest_ctor_mixed.b ()
      store_global syliTest_ctor_mixed.b = %__sy_cir_init_tmp_1:obj_ptr
      return
  end
  
  private fn __init_global.syliTest_ctor_mixed.b() -> obj_ptr:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:obj_ptr = cast(3:i64 as obj_ptr)
      return %Sy_cir_var_0:obj_ptr
  end
  
  private fn __init_global.syliTest_ctor_mixed.a() -> obj_ptr:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:syliTest_ctor_mixed.option{{variant [1{0:i64}]} tag=1 acyclic} = object_create{size=1:i64}
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i64, 3:i64):i64
      return %Sy_cir_var_0:obj_ptr
  end
  
  end
