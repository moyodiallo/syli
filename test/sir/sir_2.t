A function with let bindings:
  $ cat >test_let.sy <<EOF
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let let_bingings () =
  >   let x = 10
  >   let y = x + 32
  > EOF
  $ dune exec sylic -- cir_raw test_let.sy
  module Test_let :
  functions:
  public fn __init.Test_let() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_let.let_bingings(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %sy1_x:i64 = cast(10:i64 as i64)
      %Sy_var0:i64 = #call_direct "syliTest_let.+" (%sy1_x:i64, 32:i64)
      return
  end
  
  public fn "syliTest_let.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  end


Simple Partial apply (ir_fp — after generate_functions, before monomorphize):
  $ cat >test_partial.sy <<EOF
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let add x y = x + y
  > let m = add 5
  > EOF
  $ dune exec sylic -- cir_raw test_partial.sy
  module Test_partial :
  globals:
  global public syliTest_partial.m : (i64 -> i64) = null init=__init_global.syliTest_partial.m
  
  
  functions:
  public fn __init.Test_partial() -> void:
    entry: bb0
  
    bb0:
      %__init_tmp_0:(i64 -> i64) = #call_direct __init_global.syliTest_partial.m ()
      store_global syliTest_partial.m = %__init_tmp_0:(i64 -> i64)
      return
  end
  
  private fn __init_global.syliTest_partial.m() -> (i64 -> i64):
    entry: bb0
  
    bb0:
      %Sy_var0:(i64 -> i64) = #make_closure {syliTest_partial.add} () ( captured_args=[5:i64])
      return %Sy_var0:(i64 -> i64)
  end
  
  public fn syliTest_partial.add(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = #call_direct "syliTest_partial.+" (%x:i64, %y:i64)
      return %Sy_var0:i64
  end
  
  public fn "syliTest_partial.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  end


Simple Partial apply (ir):
  $ cat >test_partial.sy <<EOF
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let add x y = x + y
  > let m = add 5
  > EOF
  $ dune exec sylic -- cir_raw test_partial.sy
  module Test_partial :
  globals:
  global public syliTest_partial.m : (i64 -> i64) = null init=__init_global.syliTest_partial.m
  
  
  functions:
  public fn __init.Test_partial() -> void:
    entry: bb0
  
    bb0:
      %__init_tmp_0:(i64 -> i64) = #call_direct __init_global.syliTest_partial.m ()
      store_global syliTest_partial.m = %__init_tmp_0:(i64 -> i64)
      return
  end
  
  private fn __init_global.syliTest_partial.m() -> (i64 -> i64):
    entry: bb0
  
    bb0:
      %Sy_var0:(i64 -> i64) = #make_closure {syliTest_partial.add} () ( captured_args=[5:i64])
      return %Sy_var0:(i64 -> i64)
  end
  
  public fn syliTest_partial.add(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = #call_direct "syliTest_partial.+" (%x:i64, %y:i64)
      return %Sy_var0:i64
  end
  
  public fn "syliTest_partial.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  end


Simple Partial apply (ir_mono):
  $ cat >test_partial.sy <<EOF
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let add x y = x + y
  > let m = add 5
  > EOF
  $ dune exec sylic -- cir_mono test_partial.sy | grep "#make_closure"
      %Sy_var0:(i64 -> i64) = #make_closure {syliTest_partial.add} () ( captured_args=[5:i64])


Simple Partial apply (ir_raw):
  $ cat >test_partial.sy <<EOF
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let add x y = x + y
  > let m = add 5
  > EOF
  $ dune exec sylic -- cir_raw test_partial.sy
  module Test_partial :
  globals:
  global public syliTest_partial.m : (i64 -> i64) = null init=__init_global.syliTest_partial.m
  
  
  functions:
  public fn __init.Test_partial() -> void:
    entry: bb0
  
    bb0:
      %__init_tmp_0:(i64 -> i64) = #call_direct __init_global.syliTest_partial.m ()
      store_global syliTest_partial.m = %__init_tmp_0:(i64 -> i64)
      return
  end
  
  private fn __init_global.syliTest_partial.m() -> (i64 -> i64):
    entry: bb0
  
    bb0:
      %Sy_var0:(i64 -> i64) = #make_closure {syliTest_partial.add} () ( captured_args=[5:i64])
      return %Sy_var0:(i64 -> i64)
  end
  
  public fn syliTest_partial.add(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = #call_direct "syliTest_partial.+" (%x:i64, %y:i64)
      return %Sy_var0:i64
  end
  
  public fn "syliTest_partial.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  end


Partial apply from a lambda with captured local value:
  $ cat >_tmp_partial2.sy <<EOF
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let make_partial () = (fun x y -> x + y) 5
  > EOF
  $ dune exec sylic -- cir_raw _tmp_partial2.sy
  module _tmp_partial2 :
  functions:
  public fn __init._tmp_partial2() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syli_tmp_partial2.make_partial(%__unit.0:i64) -> (i64 -> i64):
    entry: bb0
  
    bb0:
      %__lambda_29:(i64, i64 -> i64) = #make_closure {__lambda_29} () ()
      %Sy_var0:(i64 -> i64) = #partial_apply {%__lambda_29:(i64, i64 -> i64)} (5:i64)
      return %Sy_var0:(i64 -> i64)
  end
  
  public fn __lambda_29(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = #call_direct "syli_tmp_partial2.+" (%x:i64, %y:i64)
      return %Sy_var0:i64
  end
  
  public fn "syli_tmp_partial2.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  end
