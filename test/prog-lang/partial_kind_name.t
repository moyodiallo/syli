Partial-apply nodes with the same shape but different stored kinds get distinct accum names:
  $ cat >pk.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let add x y z = x + z
  > let inc x = x + 1
  > let main () =
  >   let add1 = add 1
  >   let p = add1 inc
  >   let q = add1 7
  >   syli_print_i64 ((p 2) + (q 3))
  > let _ = main ()
  > EOF
  $ dune exec sylic -- oir pk.sy | grep -E 'private fn __partial_closure_accum'
  private fn __partial_closure_accum.clos1_arg1_ret_i64(%Sy_x0:i64, %Sy_clos:obj_ptr, %Sy_dp_id:i64) -> i64:
  private fn __partial_closure_accum.dispatch.clos1_ko_arg1_ret_i64(%Sy_x0:i64, %Sy_clos:obj_ptr, %Sy_dp_id:i64) -> i64:
  $ dune exec sylic -- build pk.sy
  $ ./pk.exe
  7
