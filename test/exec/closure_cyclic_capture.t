Create cycle by closure capture
  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > type pair = { mutable f : i64 -> i64; base : i64 }
  > let main () =
  >   let p = { f = fun x -> x; base = 10 }
  >   let g x = x + p.base
  >   p.f := g
  >   syli_print_i64 (p.f 5)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_file.sy
  $ ./test_file.exe
  15

Create cycle by closure capture (this test, if executed will loop until stackoverflow)
  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > type ref = { mutable f : i64 -> i64 -> i64 }
  > type t = { a : ref }
  > let r = { f = fun a b -> a + b }
  > let f a b c = (r.f a b) + c
  > let main () =
  >   let g = f 2
  >   r.f := g 
  >   syli_print_i64 (g 2 3)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_file.sy
