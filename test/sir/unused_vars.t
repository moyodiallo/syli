Closure with free variables:
  $ cat >test_multi.sy <<EOF
  > let apply () =
  >   let free = 1
  >   let add x y = y
  >   let result = add 1 2
  >   result
  > EOF
  $ dune exec sylic -- cir_mono test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.apply(%__unit.0:i64) -> i64:
    entry: bb0
  
    bb0:
      %sy1_free:i64 = cast(1:i64 as i64)
      %sy2_add:(?38, ?40 -> ?40) = #make_closure {sy2_add} () ()
      %Sy_cir_var_0:i64 = #call_apply {%sy2_add:(?38, ?40 -> ?40) as (i64, i64 -> i64)}  (1:i64, 2:i64)
      return %Sy_cir_var_0:i64
  end
  
  private fn sy2_add__i64__i64_ret_i64(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %y:i64
  end
  
  end
