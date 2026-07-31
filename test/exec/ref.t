Basic ref create, deref, and assign:
  $ cat >test_ref.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > fn main () =
  >   let counter = ref 0
  >   counter := 3
  >   let x = *counter
  >   syli_print_i64(x + *counter)
  > EOF
  $ dune exec sylic -- build test_ref.sy
  $ ./test_ref.exe
  6

Ref passed to a function with explicit ref type annotation:
  $ cat >test_ref.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > fn incr (r : ref int64) =
  >   r := *r + 1
  > fn main () =
  >   let counter : ref int64 = ref 0
  >   incr(counter)
  >   incr(counter)
  >   let a = *counter
  >   counter := 100
  >   syli_print_i64(a + *counter)
  > EOF
  $ dune exec sylic -- build test_ref.sy
  $ ./test_ref.exe
  102

Store a named function in a ref and use it:
  $ cat >test_ref.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > fn twice x = x * 2
  > fn main () =
  >   let f = ref twice
  >   let g = *f
  >   syli_print_i64(g 21)
  > EOF
  $ dune exec sylic -- oir test_ref.sy
  module Test_ref :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_ref() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_ref.main() -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_var0:obj = object_create{size=1:i64 record{fields=1 tag=0 [*void]}}
      
      gc_cycle
      %Sy_var1:*void = object_create{size=1:i32 record{fields=1 tag=0 [fn_ptr]}}
      
      %Sy_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.syliTest_ref.twice.32_ret_i64)
      obj_set(%Sy_var1:*void, 0:i32, %Sy_accum_fn_0:fn_ptr):fn_ptr
      
      %Sy_release_tmp_1:*void = @transfer obj_get(%Sy_var0:obj, 0:i64):*void
      release(%Sy_release_tmp_1:*void)
      obj_set(%Sy_var0:obj, 0:i64, @own %Sy_var1:*void):*void
      %Sy_var2:*void = @share obj_get(%Sy_var0:obj, 0:i64):*void
      release(%Sy_var0:obj)
      %Sy_accum_ptr_1:fn_ptr = obj_get(%Sy_var2:*void, 0:i32):fn_ptr
      %Sy_var3:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_1:fn_ptr)  (21:i64, @transfer %Sy_var2:*void, 0:i64)
      
      %Sy_var4:void = #call_direct syliTest_ref.syli_print_i64 (%Sy_var3:i64)
      return
  end
  
  public fn syliTest_ref.twice(%x:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_var0:i64 = %x:i64 * 2:i64
      return %Sy_var0:i64
  end
  
  private fn __make_closure_accum.syliTest_ref.twice.32_ret_i64(%Sy_x0:i64, %Sy_clos:*void, %Sy_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      release(%Sy_clos:*void)
      %Sy_rst:i64 = #call_direct __wrapper.syliTest_ref.twice.i64_ret_i64 (%Sy_x0:i64)
      return %Sy_rst:i64
  end
  
  private fn __wrapper.syliTest_ref.twice.i64_ret_i64(%Sy_x0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_s0:i64 = cast(%Sy_x0:i64 as i64)
      %Sy_rst:i64 = #call_direct syliTest_ref.twice__i64_ret_i64 (%Sy_s0:i64)
      return %Sy_rst:i64
  end
  
  end

  $ dune exec sylic -- build test_ref.sy
  ./test_ref.ll:76:22: error: use of undefined value '@syliTest_ref.twice__i64_ret_i64'
     76 |   %Sy_rst = call i64 @syliTest_ref.twice__i64_ret_i64(i64 %Sy_x0)
        |                      ^
  1 error generated.
  error: compilation failed (clang exit code 1)
  ***** UNREACHABLE *****
  $ ./test_ref.exe
  ***** UNREACHABLE *****

Reassign a different named function into a ref:
  $ cat >test_ref.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > fn twice x = x * 2
  > fn add_one x = x + 1
  > fn main () =
  >   let f = ref twice
  >   f := add_one
  >   let g = *f
  >   syli_print_i64(g 41)
  > EOF
  ***** UNREACHABLE *****
  $ dune exec sylic -- build test_ref.sy
  ***** UNREACHABLE *****
  $ ./test_ref.exe
  ***** UNREACHABLE *****


