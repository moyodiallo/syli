  $ cat >test_foreign_fn.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let main () = syli_print_i64(42)
  > EOF
  $ dune exec sylic -- core test_foreign_fn.sy
  module Test_foreign_fn
  extern syliTest_foreign_fn.syli_print_i64 : (i64) -> unit
  
  let syliTest_foreign_fn.main = fun () : unit ->
      syliTest_foreign_fn.syli_print_i64(42 : i64) : unit
  
