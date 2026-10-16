Generic/curried user-defined operator lowers to a valid LLVM symbol:
  $ cat >test_op_generic.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let (+) x y z = z
  > let main () =
  >   syli_print_i64 ((+) 2 3 4)
  >   syli_print_i64 ((2 + 3) 4)
  >   let p = 2 + 3
  >   syli_print_i64 (p 7)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_op_generic.sy
  $ ./test_op_generic.exe
  447
