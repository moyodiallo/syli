Store a named polymorphic function in a ref and use it:
TODO: fix when parametric will be supported.
  $ cat >test_ref.sy <<EOF
  > foreign syli_print_i64 : int64 -> unit = "syli_print_i64"
  > let id x = x
  > let main () =
  >   let f = ref id
  >   let g = *f
  >   syli_print_i64(g 21)
  > EOF
  $ dune exec sylic -- oir test_ref.sy
  
  Parse error in test_ref.sy at line 5, column 10
  
    5 |   let g = *f
                   ^
  
  Unexpected token: '*'
  
  ***** UNREACHABLE *****
  $ dune exec sylic -- build test_ref.sy
  ***** UNREACHABLE *****
