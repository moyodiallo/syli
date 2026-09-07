Closure with unit as arguments:
  $ cat >test_multi.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let apply f x y = f x y
  > let add () () z () = z
  > let main () =
  >   let add1 = add ()
  >   let result =
  >     if false then
  >       (apply add1 () 4) ()
  >     else (apply add1 () 2) ()
  >   syli_print_i64 result
  > let _ = main ()
  > EOF
  $ dune exec sylic -- cir_raw test_multi.sy
  module Test_multi :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_multi() -> void:
    entry: bb0
  
    bb0:
      %__sy_cir_init_tmp_0:void = #call_direct __init_global.syliTest_multi.sy3_any_pat ()
      return
  end
  
  private fn __init_global.syliTest_multi.sy3_any_pat() -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:void = #call_direct syliTest_multi.main (0:i64)
      return
  end
  
  public fn syliTest_multi.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:(i64, ?110, i64 -> ?110) = #make_closure {syliTest_multi.add} () ( captured_args=[0:i64])
      %Sy_cir_var_1:bool = cast(false:bool as bool)
      cond_br %Sy_cir_var_1:bool, bb1, bb2
  
    bb1:
      %Sy_cir_var_3:(i64, i64, i64 -> i64) = cast(%Sy_cir_var_0:(i64, ?110, i64 -> ?110) as (i64, i64, i64 -> i64))
      %Sy_cir_var_4:(i64 -> i64) = #call_direct syliTest_multi.apply (%Sy_cir_var_3:(i64, i64, i64 -> i64), 0:i64, 4:i64)
      %Sy_cir_var_5:i64 = #call_apply {%Sy_cir_var_4:(i64 -> i64)}  (0:i64)
      %Sy_cir_var_2:i64 = move(%Sy_cir_var_5:i64)
      goto bb3
  
    bb2:
      %Sy_cir_var_6:(i64, i64, i64 -> i64) = cast(%Sy_cir_var_0:(i64, ?110, i64 -> ?110) as (i64, i64, i64 -> i64))
      %Sy_cir_var_7:(i64 -> i64) = #call_direct syliTest_multi.apply (%Sy_cir_var_6:(i64, i64, i64 -> i64), 0:i64, 2:i64)
      %Sy_cir_var_8:i64 = #call_apply {%Sy_cir_var_7:(i64 -> i64)}  (0:i64)
      %Sy_cir_var_2:i64 = move(%Sy_cir_var_8:i64)
      goto bb3
  
    bb3:
      %Sy_cir_var_9:void = #call_direct syliTest_multi.syli_print_i64 (%Sy_cir_var_2:i64)
      return
  end
  
  public fn syliTest_multi.add(%__unit.0:i64, %__unit.1:i64, %z:?105, %__unit.3:i64) -> ?105:
    entry: bb0
  
    bb0:
  
      return %z:?105
  end
  
  public fn syliTest_multi.apply(%f:(?95, ?97 -> ?101), %x:?95, %y:?97) -> ?101:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:?101 = #call_apply {%f:(?95, ?97 -> ?101)}  (%x:?95, %y:?97)
      return %Sy_cir_var_0:?101
  end
  
  end


  $ dune exec sylic -- cir_mono test_multi.sy
  Fatal error: exception Invalid_argument("List.iter2")
  [2]
