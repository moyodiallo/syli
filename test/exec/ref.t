Basic ref create, deref, and assign:
  $ cat >test_ref.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let main () =
  >   let counter = ref 0
  >   counter := 3
  >   let x = *counter
  >   syli_print_i64(x + *counter)
  > EOF
  $ dune exec sylic -- build test_ref.sy
  
  Parse error in test_ref.sy at line 5, column 10
  
    5 |   let x = *counter
                   ^
  
  Unexpected token: '*'
  
  ***** UNREACHABLE *****
  $ ./test_ref.exe
  ***** UNREACHABLE *****

Ref passed to a function with explicit ref type annotation:
  $ cat >test_ref.sy <<EOF
  > foreign syli_print_i64 : int64 -> unit = "syli_print_i64"
  > let incr (r : ref int64) =
  >   r := *r + 1
  > let main () =
  >   let counter : ref int64 = ref 0
  >   incr(counter)
  >   incr(counter)
  >   let a = *counter
  >   counter := 100
  >   syli_print_i64(a + *counter)
  > EOF
  ***** UNREACHABLE *****
  $ dune exec sylic -- build test_ref.sy
  ***** UNREACHABLE *****
  $ ./test_ref.exe
  ***** UNREACHABLE *****

Store a named function in a ref and use it:
  $ cat >test_ref.sy <<EOF
  > foreign syli_print_i64 : int64 -> unit = "syli_print_i64"
  > let twice x = x * 2
  > let main () =
  >   let f = ref twice
  >   let g = *f
  >   syli_print_i64(g 21)
  > EOF
  ***** UNREACHABLE *****
  $ dune exec sylic -- build test_ref.sy
  ***** UNREACHABLE *****
  $ ./test_ref.exe
  ***** UNREACHABLE *****

Reassign a different named function into a ref:
  $ cat >test_ref.sy <<EOF
  > foreign syli_print_i64 : int64 -> unit = "syli_print_i64"
  > let twice x = x * 2
  > let add_one x = x + 1
  > let main () =
  >   let f = ref twice
  >   f := add_one
  >   let g = *f
  >   syli_print_i64(g 40)
  > EOF
  ***** UNREACHABLE *****
  $ dune exec sylic -- build test_ref.sy
  ***** UNREACHABLE *****
  $ ./test_ref.exe
  ***** UNREACHABLE *****


