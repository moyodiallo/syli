Closure with free variables:
  $ cat >test_multi.sy <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > let apply () =
  >   let free = 1
  >   let add x y = free + y
  >   let result = add 1 2
  >   result
  > EOF
  $ dune exec sylic -- cir_raw test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.apply() -> i64:
    entry: bb0
  
    bb0:
      %sy1_free:void = cast(1:i64 as void)
      %sy2_add:void = #make_closure {sy2_add} (%sy1_free:void) ()
      %Sy_var0:i64 = #call_apply {%sy2_add:void as (i64, i64 -> i64)}  (1:i64, 2:i64)
      return %Sy_var0:i64
  end
  
  private fn sy2_add(%sy1_free:void, %x:?50, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = cast(%sy1_free:void as i64)
      %Sy_var1:i64 = #call_direct "syliTest_multi.+" (%Sy_var0:i64, %y:i64)
      return %Sy_var1:i64
  end
  
  public fn "syliTest_multi.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  end

