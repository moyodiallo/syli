Monomorphization issue.
  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > let add x y z = y + z
  > let apply () =
  >   let add1 = add 1
  >   let add1and2 = add1 2
  >   let result = add1and2 3
  >   result
  > let main () = 
  >   let result = apply ()
  >   syli_print_i64 result
  > EOF

  $ dune exec sylic -- core test_file.sy > test_file.core
  $ dune exec sylic -- cir_raw test_file.sy
  module Test_file :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_file() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_file.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct syliTest_file.apply (0:i64)
      %Sy_cir_var_1:void = #call_direct syliTest_file.syli_print_i64 (%Sy_cir_var_0:i64)
      return
  end
  
  public fn syliTest_file.apply(%__unit.0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:(i64, i64 -> i64) = #make_closure {syliTest_file.add} () ( captured_args=[1:i64])
      %Sy_cir_var_1:(i64 -> i64) = #partial_apply {%Sy_cir_var_0:(i64, i64 -> i64)} (2:i64)
      %Sy_cir_var_2:i64 = #call_apply {%Sy_cir_var_1:(i64 -> i64)}  (3:i64)
      return %Sy_cir_var_2:i64
  end
  
  public fn syliTest_file.add(%x:?83, %y:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_file.+" (%y:i64, %z:i64)
      return %Sy_cir_var_0:i64
  end
  
  public fn "syliTest_file.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  end

  $ dune exec sylic -- cir test_file.sy > test_file.ir
  $ cat test_file.ir
  module Test_file :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_file() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_file.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct syliTest_file.apply (0:i64)
      %Sy_cir_var_1:void = #call_direct syliTest_file.syli_print_i64 (%Sy_cir_var_0:i64)
      return
  end
  
  public fn syliTest_file.apply(%__unit.0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:(i64, i64 -> i64) = #make_closure {syliTest_file.add} () ( captured_args=[1:i64])
      %Sy_cir_var_1:(i64 -> i64) = #partial_apply {%Sy_cir_var_0:(i64, i64 -> i64)} (2:i64)
      %Sy_cir_var_2:i64 = #call_apply {%Sy_cir_var_1:(i64 -> i64)}  (3:i64)
      return %Sy_cir_var_2:i64
  end
  
  public fn "syliTest_file.+"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 + %y:i64
      return %Sy_prim_result:i64
  end
  
  public fn syliTest_file.add__i64__i64__i64_ret_i64(%x:i64, %y:i64, %z:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_direct "syliTest_file.+" (%y:i64, %z:i64)
      return %Sy_cir_var_0:i64
  end
  
  end
