SIR lowering tests — if-then-else expressions with multi-block SIR

If-then-else with i64 result:
  $ cat >test_if_i64.sy <<EOF
  > let x = if true then 1 else 0
  > EOF
  $ dune exec sylic -- cir test_if_i64.sy
  module Test_if_i64 :
  globals:
  global public syliTest_if_i64.x : i64 = null init=__init_global.syliTest_if_i64.x
  
  
  functions:
  public fn __init.Test_if_i64() -> void:
    entry: bb0
  
    bb0:
      %__init_tmp_0:i64 = #call_direct __init_global.syliTest_if_i64.x ()
      store_global syliTest_if_i64.x = %__init_tmp_0:i64
      return
  end
  
  private fn __init_global.syliTest_if_i64.x() -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:bool = cast(true:bool as bool)
      cond_br %Sy_var0:bool, bb1, bb2
  
    bb2:
      %Sy_var1:i64 = move(0:i64)
      goto bb3
  
    bb1:
      %Sy_var1:i64 = move(1:i64)
      goto bb3
  
    bb3:
  
      return %Sy_var1:i64
  end
  
  end

If-then-else with bool comparison:
  $ cat >test_if_cmp.sy <<EOF
  > let x = 10
  > let y = if x > 5 then 1 else 0
  > EOF
  $ dune exec sylic -- cir test_if_cmp.sy
  Fatal error: exception Syli_typing__Env.Type_error("Unbound identifier '>'")
  [2]

If-then-else without else (unit):
  $ cat >test_if_unit.sy <<EOF
  > let x = if true then () else ()
  > EOF
  $ dune exec sylic -- cir test_if_unit.sy
  module Test_if_unit :
  globals:
  global public syliTest_if_unit.x : void = null init=__init_global.syliTest_if_unit.x
  
  
  functions:
  public fn __init.Test_if_unit() -> void:
    entry: bb0
  
    bb0:
      %__init_tmp_0:void = #call_direct __init_global.syliTest_if_unit.x ()
      store_global syliTest_if_unit.x = %__init_tmp_0:void
      return
  end
  
  private fn __init_global.syliTest_if_unit.x() -> void:
    entry: bb0
  
    bb0:
      %Sy_var0:bool = cast(true:bool as bool)
      cond_br %Sy_var0:bool, bb1, bb2
  
    bb2:
      %Sy_var1:void = move(null:void)
      goto bb3
  
    bb1:
      %Sy_var1:void = move(null:void)
      goto bb3
  
    bb3:
  
      return %Sy_var1:void
  end
  
  end

Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let result =
  >     if true then
  >       apply add1 3 4
  >     else apply add1 1.0 2.0
  > EOF
  $ dune exec sylic -- cir test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main() -> void:
    entry: bb0
  
    bb0:
      %Sy_var0:(?89, ?90 -> i64) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_var1:bool = cast(true:bool as bool)
      cond_br %Sy_var1:bool, bb1, bb2
  
    bb2:
      %Sy_var5:(f64, f64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (f64, f64 -> i64))
      %Sy_var6:i64 = #call_direct syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64 (%Sy_var5:(f64, f64 -> i64), 1.0f:f64, 2.0f:f64)
      %Sy_var2:i64 = move(%Sy_var6:i64)
      goto bb3
  
    bb1:
      %Sy_var3:(i64, i64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (i64, i64 -> i64))
      %Sy_var4:i64 = #call_direct syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64 (%Sy_var3:(i64, i64 -> i64), 3:i64, 4:i64)
      %Sy_var2:i64 = move(%Sy_var4:i64)
      goto bb3
  
    bb3:
  
      return
  end
  
  public fn syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(%f:(i64, i64 -> i64), %x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = #call_apply {%f:(i64, i64 -> i64)}  (%x:i64, %y:i64)
      return %Sy_var0:i64
  end
  
  public fn syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64(%f:(f64, f64 -> i64), %x:f64, %y:f64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = #call_apply {%f:(f64, f64 -> i64)}  (%x:f64, %y:f64)
      return %Sy_var0:i64
  end
  
  public fn syliTest_multi.add__i64__i64__i64_ret_i64(%x:i64, %y:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  public fn syliTest_multi.add__i64__f64__f64_ret_i64(%x:i64, %y:f64, %z:f64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  end

Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let result =
  >     if true then
  >       let m = 4
  >       apply add1 3 m
  >     else
  >       let m = 2.0
  >       apply add1 1.0 m
  > EOF
  $ dune exec sylic -- core test_multi.sy
  module Test_multi
  let syliTest_multi.apply = fun (f, x, y) : 'a90 ->
      f(x : 'a84, y : 'a86) : 'a90
  
  let syliTest_multi.add = fun (x, y, z) : 'a92 ->
      x : 'a92
  
  let syliTest_multi.main = fun () : unit ->
      {
        let sy1_add1 = syliTest_multi.add(1 : i64) : ('a101) -> ('a102) -> i64
        let sy2_result = if true : bool
            {
              let sy4_m = 4 : i64
              syliTest_multi.apply(sy1_add1 : (i64) -> (i64) -> i64, 3 : i64, sy4_m : i64) : i64
            }
          else
            {
              let sy3_m = 2.0 : f64
              syliTest_multi.apply(sy1_add1 : (f64) -> (f64) -> i64, 1.0 : f64, sy3_m : f64) : i64
            }
      }
  
Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let add2 =
  >     if true then
  >       let x = add1 4
  >       x
  >     else
  >       let x = add1 2.0
  >       x
  >   let result2 = add2 4 
  >   result2
  > EOF
  $ dune exec sylic -- core test_multi.sy
  module Test_multi
  let syliTest_multi.apply = fun (f, x, y) : 'a92 ->
      f(x : 'a86, y : 'a88) : 'a92
  
  let syliTest_multi.add = fun (x, y, z) : 'a94 ->
      x : 'a94
  
  let syliTest_multi.main = fun () : i64 ->
      {
        let sy1_add1 = syliTest_multi.add(1 : i64) : ('a103) -> ('a104) -> i64
        let sy2_add2 = if true : bool
            {
              let sy4_x = sy1_add1(4 : i64) : ('a107) -> i64
              sy4_x : ('a113) -> i64
            }
          else
            {
              let sy3_x = sy1_add1(2.0 : f64) : ('a111) -> i64
              sy3_x : ('a113) -> i64
            }
        let sy5_result2 = sy2_add2(4 : i64) : i64
        sy5_result2 : i64
      }
  

Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let add2 =
  >     if true then
  >       let x = add1 4
  >       x
  >     else
  >       let x = add1 2.0
  >       x
  >   let result2 = add2 4 
  >   result2
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
      %Sy_var0:(?103, ?104 -> i64) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_var1:bool = cast(true:bool as bool)
      cond_br %Sy_var1:bool, bb1, bb2
  
    bb1:
      %Sy_var3:(?107 -> i64) = #partial_apply {%Sy_var0:(?103, ?104 -> i64)} (4:i64)
      %Sy_var2:(?113 -> i64) = move(%Sy_var3:(?107 -> i64))
      goto bb3
  
    bb2:
      %Sy_var4:(?111 -> i64) = #partial_apply {%Sy_var0:(?103, ?104 -> i64)} (2.0f:f64)
      %Sy_var2:(?113 -> i64) = move(%Sy_var4:(?111 -> i64))
      goto bb3
  
    bb3:
      %Sy_var5:i64 = #call_apply {%Sy_var2:(?113 -> i64) as (i64 -> i64)}  (4:i64)
      return %Sy_var5:i64
  end
  
  public fn syliTest_multi.add(%x:?94, %y:?96, %z:?98) -> ?94:
    entry: bb0
  
    bb0:
  
      return %x:?94
  end
  
  public fn syliTest_multi.apply(%f:(?86, ?88 -> ?92), %x:?86, %y:?88) -> ?92:
    entry: bb0
  
    bb0:
      %Sy_var0:?92 = #call_apply {%f:(?86, ?88 -> ?92)}  (%x:?86, %y:?88)
      return %Sy_var0:?92
  end
  
  end
