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
  $ dune exec sylic -- build test_ref.sy
  $ ./test_ref.exe
  42

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
  $ dune exec sylic -- build test_ref.sy
  $ ./test_ref.exe
  42


