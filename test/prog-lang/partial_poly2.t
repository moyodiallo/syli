Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let add2 =
  >     if true then
  >       add1 3
  >     else add1 1.0
  >   let result = add2 1.0
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
  
  public fn syliTest_multi.main(%__unit.0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:(?64, ?65 -> i64) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_cir_var_1:bool = cast(true:bool as bool)
      cond_br %Sy_cir_var_1:bool, bb1, bb2
  
    bb1:
      %Sy_cir_var_3:(?70 -> i64) = #partial_apply {%Sy_cir_var_0:(?64, ?65 -> i64)} (3:i64)
      %Sy_cir_var_2:(?70 -> i64) = move(%Sy_cir_var_3:(?70 -> i64))
      goto bb3
  
    bb2:
      %Sy_cir_var_4:(?70 -> i64) = #partial_apply {%Sy_cir_var_0:(?64, ?65 -> i64)} (1.0f:f64)
      %Sy_cir_var_2:(?70 -> i64) = move(%Sy_cir_var_4:(?70 -> i64))
      goto bb3
  
    bb3:
      %Sy_cir_var_5:i64 = #call_apply {%Sy_cir_var_2:(?70 -> i64) as (f64 -> i64)}  (1.0f:f64)
      return 0:i64
  end
  
  public fn syliTest_multi.add(%x:?55, %y:?57, %z:?59) -> ?55:
    entry: bb0
  
    bb0:
  
      return %x:?55
  end
  
  end

  $ dune exec sylic -- typing test_multi.sy
  Typed test_multi.sy successfully: module Test_multi with 2 top-level typed items
  Type Environment:
  {
    add : forall '55 '57 '59. '55 -> '57 -> '59 -> '55
    main : unit -> i64
  }
