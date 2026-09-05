Basic ref create, deref, and assign:
  $ cat >test_ref.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > type ref = { mutable value: i64 }
  > let ref x = { value = x }
  > let ( ! ) r = r.value
  > let ( := ) r x = r.value := x
  > let main () =
  >   let counter = ref 0
  >   counter := 3
  >   let x = !counter
  >   syli_print_i64(x + !counter)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_ref.sy
  $ ./test_ref.exe
  6

Ref passed to a function with explicit ref type annotation:
  $ cat >test_ref.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > type ref = { mutable value: i64 }
  > let ref x = { value = x }
  > let ( ! ) r = r.value
  > let ( := ) r x = r.value := x
  > let incr (r : ref) =
  >   r := !r + 1
  > let main () =
  >   let counter : ref = ref 0
  >   incr(counter)
  >   incr(counter)
  >   let a = !counter
  >   counter := 100
  >   syli_print_i64(a + !counter)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_ref.sy
  $ ./test_ref.exe
  102

Store a named function in a ref and use it:
  $ cat >test_ref.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > primitive (*)  : i64 -> i64 -> i64 = "mul"
  > type ref = { mutable value: i64 -> i64 }
  > let ref x = { value = x }
  > let ( ! ) r = r.value
  > let ( := ) r x = r.value := x
  > let twice x = x * 2
  > let main () =
  >   let f = ref twice
  >   let g = !f
  >   syli_print_i64(g 21)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_ref.sy
  $ ./test_ref.exe
  42

Reassign a different named function into a ref:
  $ cat >test_ref.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > primitive (*)  : i64 -> i64 -> i64 = "mul"
  > type ref = { mutable value: i64 -> i64 }
  > let ref x = { value = x }
  > let ( ! ) r = r.value
  > let ( := ) r x = r.value := x
  > let twice x = x * 2
  > let add_one x = x + 1
  > let main () =
  >   let f = ref twice
  >   f := add_one
  >   let g = !f
  >   syli_print_i64(g 40)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_ref.sy
  $ ./test_ref.exe
  41


