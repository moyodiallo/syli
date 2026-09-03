  $ cat >test_multi.sy <<EOF
  > let add x y z = z
  > let main () =
  >   let add1 = add 1
  >   let a0 = add1 1.0
  >   let b0 = add1 1
  >   let a1 = a0 1

  $ dune exec sylic -- cir_raw test_multi.sy
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
      %Sy_var0:(?62, ?63 -> ?63) = #make_closure {syliTest_multi.add} () ( captured_args=[1:i64])
      %Sy_var1:(?66 -> ?66) = #partial_apply {%Sy_var0:(?62, ?63 -> ?63)} (1.0f:f64)
      %Sy_var2:(?69 -> ?69) = #partial_apply {%Sy_var0:(?62, ?63 -> ?63)} (1:i64)
      %Sy_var3:i64 = #call_apply {%Sy_var1:(?66 -> ?66) as (i64 -> i64)}  (1:i64)
      return
  end
  
  public fn syliTest_multi.add(%x:?53, %y:?55, %z:?57) -> ?57:
    entry: bb0
  
    bb0:
  
      return %z:?57
  end
  
  end

  $ dune exec sylic -- typing test_multi.sy
  Typed test_multi.sy successfully: module Test_multi with 2 top-level typed items
  Type Environment:
  {
    add : forall '53 '55 '57. '53 -> '55 -> '57 -> '57
    main : unit -> unit
  }

  $ dune exec sylic -- oir test_multi.sy
  Fatal error: exception Failure("Cir.CR_GenericTyp should be monomorphized before lowering to OIR")
  ***** UNREACHABLE *****

