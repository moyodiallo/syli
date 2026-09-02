Nested functions:
  $ cat >test_multi.sy <<EOF
  > primitive (+)  : f64 -> f64 -> f64 = "add"
  > let main () =
  >   let apply f x y = f x y
  >   let add x y z = x + z
  >   let add1 = add 1.0
  >   let result = apply add1 3 4.0
  >   let result2 = apply add1 1.0 2.0
  >   0
  > EOF
  $ dune exec sylic -- core test_multi.sy
  module Test_multi
  extern "syliTest_multi.+" : (f64) -> (f64) -> f64
  
  let syliTest_multi.main = fun () : i64 ->
      {
        let sy1_apply = fun (f, x, y) : 'a93 ->
            f(x : 'a87, y : 'a89) : 'a93
        let sy2_add = fun (x, y, z) : f64 ->
            "syliTest_multi.+"(x : f64, z : f64) : f64
        let sy3_add1 = sy2_add(1.0 : f64) : ('a102) -> (f64) -> f64
        let sy4_result = sy1_apply(sy3_add1 : (i64) -> (f64) -> f64, 3 : i64, 4.0 : f64) : f64
        let sy5_result2 = sy1_apply(sy3_add1 : (f64) -> (f64) -> f64, 1.0 : f64, 2.0 : f64) : f64
        0 : i64
      }
  

Nested functions:
  $ cat >test_multi.sy <<EOF
  > primitive (+)  : f64 -> f64 -> f64 = "add"
  > let main () =
  >   let apply f x y = f x y
  >   let add x y z = x + z
  >   let add1 = add 1.0
  >   let result = apply add1 3 4.0
  >   let result2 = apply add1 1.0 2.0
  >   0
  > EOF
  $ dune exec sylic -- cir_raw test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main() -> i64:
    entry: bb0
  
    bb0:
      %sy1_apply:void = #make_closure {sy1_apply} () ()
      %sy2_add:void = #make_closure {sy2_add} () ()
      %Sy_var0:(?102, f64 -> f64) = #partial_apply {%sy2_add:void} (1.0f:f64)
      %Sy_var1:(i64, f64 -> f64) = cast(%Sy_var0:(?102, f64 -> f64) as (i64, f64 -> f64))
      %Sy_var2:f64 = #call_apply {%sy1_apply:void as ((i64, f64 -> f64), i64, f64 -> f64)}  (%Sy_var1:(i64, f64 -> f64), 3:i64, 4.0f:f64)
      %Sy_var3:(f64, f64 -> f64) = cast(%Sy_var0:(?102, f64 -> f64) as (f64, f64 -> f64))
      %Sy_var4:f64 = #call_apply {%sy1_apply:void as ((f64, f64 -> f64), f64, f64 -> f64)}  (%Sy_var3:(f64, f64 -> f64), 1.0f:f64, 2.0f:f64)
      return 0:i64
  end
  
  private fn sy1_apply(%f:(?87, ?89 -> ?93), %x:?87, %y:?89) -> ?93:
    entry: bb0
  
    bb0:
      %Sy_var0:?93 = #call_apply {%f:(?87, ?89 -> ?93)}  (%x:?87, %y:?89)
      return %Sy_var0:?93
  end
  
  private fn sy2_add(%x:f64, %y:?97, %z:f64) -> f64:
    entry: bb0
  
    bb0:
      %Sy_var0:f64 = #call_direct "syliTest_multi.+" (%x:f64, %z:f64)
      return %Sy_var0:f64
  end
  
  public fn "syliTest_multi.+"(%x:f64, %y:f64) -> f64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:f64 = %x:f64 + %y:f64
      return %Sy_prim_result:f64
  end
  
  end

  $ dune exec sylic -- cir_mono test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main() -> i64:
    entry: bb0
  
    bb0:
      %sy1_apply:void = #make_closure {sy1_apply} () ()
      %sy2_add:void = #make_closure {sy2_add} () ()
      %Sy_var0:(?102, f64 -> f64) = #partial_apply {%sy2_add:void} (1.0f:f64)
      %Sy_var1:(i64, f64 -> f64) = cast(%Sy_var0:(?102, f64 -> f64) as (i64, f64 -> f64))
      %Sy_var2:f64 = #call_apply {%sy1_apply:void as ((i64, f64 -> f64), i64, f64 -> f64)}  (%Sy_var1:(i64, f64 -> f64), 3:i64, 4.0f:f64)
      %Sy_var3:(f64, f64 -> f64) = cast(%Sy_var0:(?102, f64 -> f64) as (f64, f64 -> f64))
      %Sy_var4:f64 = #call_apply {%sy1_apply:void as ((f64, f64 -> f64), f64, f64 -> f64)}  (%Sy_var3:(f64, f64 -> f64), 1.0f:f64, 2.0f:f64)
      return 0:i64
  end
  
  public fn "syliTest_multi.+"(%x:f64, %y:f64) -> f64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:f64 = %x:f64 + %y:f64
      return %Sy_prim_result:f64
  end
  
  private fn sy2_add__f64__i64__f64_ret_f64(%x:f64, %y:i64, %z:f64) -> f64:
    entry: bb0
  
    bb0:
      %Sy_var0:f64 = #call_direct "syliTest_multi.+" (%x:f64, %z:f64)
      return %Sy_var0:f64
  end
  
  private fn sy2_add__f64__f64__f64_ret_f64(%x:f64, %y:f64, %z:f64) -> f64:
    entry: bb0
  
    bb0:
      %Sy_var0:f64 = #call_direct "syliTest_multi.+" (%x:f64, %z:f64)
      return %Sy_var0:f64
  end
  
  private fn sy1_apply__fn_i64_f64_f64__i64__f64_ret_f64(%f:(i64, f64 -> f64), %x:i64, %y:f64) -> f64:
    entry: bb0
  
    bb0:
      %Sy_var0:f64 = #call_apply {%f:(i64, f64 -> f64)}  (%x:i64, %y:f64)
      return %Sy_var0:f64
  end
  
  private fn sy1_apply__fn_f64_f64_f64__f64__f64_ret_f64(%f:(f64, f64 -> f64), %x:f64, %y:f64) -> f64:
    entry: bb0
  
    bb0:
      %Sy_var0:f64 = #call_apply {%f:(f64, f64 -> f64)}  (%x:f64, %y:f64)
      return %Sy_var0:f64
  end
  
  end
