Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y = x
  > let main () = 
  >   let result = apply add  3 4
  > EOF
  $ dune exec sylic -- cir_raw test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_var0:(i64, i64 -> i64) = #make_closure {syliTest_multi.add} () ()
      %Sy_var1:i64 = #call_direct syliTest_multi.apply (%Sy_var0:(i64, i64 -> i64), 3:i64, 4:i64)
      return
  end
  
  public fn syliTest_multi.add(%x:?57, %y:?59) -> ?57:
    entry: bb0
  
    bb0:
  
      return %x:?57
  end
  
  public fn syliTest_multi.apply(%f:(?49, ?51 -> ?55), %x:?49, %y:?51) -> ?55:
    entry: bb0
  
    bb0:
      %Sy_var0:?55 = #call_apply {%f:(?49, ?51 -> ?55)}  (%x:?49, %y:?51)
      return %Sy_var0:?55
  end
  
  end

Closure as an argument with partial polymorphic closure:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let result = apply add1 3 4
  >   let result2 = apply add1 1.0 2.0
  > EOF
  $ dune exec sylic -- cir_raw test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_var0:(?89, ?90 -> i64) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_var1:(i64, i64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (i64, i64 -> i64))
      %Sy_var2:i64 = #call_direct syliTest_multi.apply (%Sy_var1:(i64, i64 -> i64), 3:i64, 4:i64)
      %Sy_var3:(f64, f64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (f64, f64 -> i64))
      %Sy_var4:i64 = #call_direct syliTest_multi.apply (%Sy_var3:(f64, f64 -> i64), 1.0f:f64, 2.0f:f64)
      return
  end
  
  public fn syliTest_multi.add(%x:?80, %y:?82, %z:?84) -> ?80:
    entry: bb0
  
    bb0:
  
      return %x:?80
  end
  
  public fn syliTest_multi.apply(%f:(?72, ?74 -> ?78), %x:?72, %y:?74) -> ?78:
    entry: bb0
  
    bb0:
      %Sy_var0:?78 = #call_apply {%f:(?72, ?74 -> ?78)}  (%x:?72, %y:?74)
      return %Sy_var0:?78
  end
  
  end

Closure as an argument with partial polymorphic closure:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let result = apply add1 3 4
  >   let result2 = apply add1 1.0 2.0
  > EOF
  $ dune exec sylic -- cir_mono test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_var0:(?89, ?90 -> i64) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_var1:(i64, i64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (i64, i64 -> i64))
      %Sy_var2:i64 = #call_direct syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64 (%Sy_var1:(i64, i64 -> i64), 3:i64, 4:i64)
      %Sy_var3:(f64, f64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (f64, f64 -> i64))
      %Sy_var4:i64 = #call_direct syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64 (%Sy_var3:(f64, f64 -> i64), 1.0f:f64, 2.0f:f64)
      return
  end
  
  public fn syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64(%f:(f64, f64 -> i64), %x:f64, %y:f64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = #call_apply {%f:(f64, f64 -> i64)}  (%x:f64, %y:f64)
      return %Sy_var0:i64
  end
  
  public fn syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(%f:(i64, i64 -> i64), %x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = #call_apply {%f:(i64, i64 -> i64)}  (%x:i64, %y:i64)
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
  >   let result = apply add1 3 4
  >   let result2 = apply add1 1.0 2.0
  > EOF
  $ dune exec sylic -- cir_raw test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_var0:(?89, ?90 -> i64) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_var1:(i64, i64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (i64, i64 -> i64))
      %Sy_var2:i64 = #call_direct syliTest_multi.apply (%Sy_var1:(i64, i64 -> i64), 3:i64, 4:i64)
      %Sy_var3:(f64, f64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (f64, f64 -> i64))
      %Sy_var4:i64 = #call_direct syliTest_multi.apply (%Sy_var3:(f64, f64 -> i64), 1.0f:f64, 2.0f:f64)
      return
  end
  
  public fn syliTest_multi.add(%x:?80, %y:?82, %z:?84) -> ?80:
    entry: bb0
  
    bb0:
  
      return %x:?80
  end
  
  public fn syliTest_multi.apply(%f:(?72, ?74 -> ?78), %x:?72, %y:?74) -> ?78:
    entry: bb0
  
    bb0:
      %Sy_var0:?78 = #call_apply {%f:(?72, ?74 -> ?78)}  (%x:?72, %y:?74)
      return %Sy_var0:?78
  end
  
  end

Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let result = apply add1 3 4
  >   let result2 = apply add1 1.0 2.0
  > EOF
  $ dune exec sylic -- core test_multi.sy
  module Test_multi
  let syliTest_multi.apply = fun (f, x, y) : 'a78 ->
      f(x : 'a72, y : 'a74) : 'a78
  
  let syliTest_multi.add = fun (x, y, z) : 'a80 ->
      x : 'a80
  
  let syliTest_multi.main = fun () : unit ->
      {
        let sy1_add1 = syliTest_multi.add(1 : i64) : ('a89) -> ('a90) -> i64
        let sy2_result = syliTest_multi.apply(sy1_add1 : (i64) -> (i64) -> i64, 3 : i64, 4 : i64) : i64
        let sy3_result2 = syliTest_multi.apply(sy1_add1 : (f64) -> (f64) -> i64, 1.0 : f64, 2.0 : f64) : i64
      }
  
Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let result = apply add1 3 4
  >   let result2 = apply add1 1.0 2.0
  > EOF
  $ dune exec sylic -- cir_raw test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_var0:(?89, ?90 -> i64) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_var1:(i64, i64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (i64, i64 -> i64))
      %Sy_var2:i64 = #call_direct syliTest_multi.apply (%Sy_var1:(i64, i64 -> i64), 3:i64, 4:i64)
      %Sy_var3:(f64, f64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (f64, f64 -> i64))
      %Sy_var4:i64 = #call_direct syliTest_multi.apply (%Sy_var3:(f64, f64 -> i64), 1.0f:f64, 2.0f:f64)
      return
  end
  
  public fn syliTest_multi.add(%x:?80, %y:?82, %z:?84) -> ?80:
    entry: bb0
  
    bb0:
  
      return %x:?80
  end
  
  public fn syliTest_multi.apply(%f:(?72, ?74 -> ?78), %x:?72, %y:?74) -> ?78:
    entry: bb0
  
    bb0:
      %Sy_var0:?78 = #call_apply {%f:(?72, ?74 -> ?78)}  (%x:?72, %y:?74)
      return %Sy_var0:?78
  end
  
  end


Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let result = apply add1 3 4
  >   let result2 = apply add1 1.0 2.0
  > EOF
  $ dune exec sylic -- cir test_multi.sy
  module Test_multi :
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_var0:(?89, ?90 -> i64) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_var1:(i64, i64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (i64, i64 -> i64))
      %Sy_var2:i64 = #call_direct syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64 (%Sy_var1:(i64, i64 -> i64), 3:i64, 4:i64)
      %Sy_var3:(f64, f64 -> i64) = cast(%Sy_var0:(?89, ?90 -> i64) as (f64, f64 -> i64))
      %Sy_var4:i64 = #call_direct syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64 (%Sy_var3:(f64, f64 -> i64), 1.0f:f64, 2.0f:f64)
      return
  end
  
  public fn syliTest_multi.apply__fn_f64_f64_i64__f64__f64_ret_i64(%f:(f64, f64 -> i64), %x:f64, %y:f64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = #call_apply {%f:(f64, f64 -> i64)}  (%x:f64, %y:f64)
      return %Sy_var0:i64
  end
  
  public fn syliTest_multi.apply__fn_i64_i64_i64__i64__i64_ret_i64(%f:(i64, i64 -> i64), %x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = #call_apply {%f:(i64, i64 -> i64)}  (%x:i64, %y:i64)
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
