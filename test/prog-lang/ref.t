Store a named function in a ref and use it:
TODO: fix the test
  $ cat >test_ref.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let twice x = x * 2
  > let main () =
  >   let f = ref twice
  >   let g = *f
  >   syli_print_i64(g 21)
  > EOF
  $ dune exec sylic -- cir test_ref.sy
  
  Parse error in test_ref.sy at line 5, column 10
  
    5 |   let g = *f
                   ^
  
  Unexpected token: '*'
  
  ***** UNREACHABLE *****

  $ dune exec sylic -- oir test_ref.sy
  ***** UNREACHABLE *****
