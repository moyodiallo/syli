Local lambda without captures runs end-to-end:
  $ cat >loc.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let main () =
  >   let f x = x + 1
  >   syli_print_i64 (f 6)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build loc.sy
  $ ./loc.exe
  7

Local lambda capturing a free variable runs end-to-end:
  $ cat >cap.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let main () =
  >   let n = 5
  >   let f x = n + x
  >   syli_print_i64 (f 7)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build cap.sy
  $ ./cap.exe
  12

Local lambda passed to a higher-order function:
  $ cat >ho.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let apply2 f x = f x
  > let main () =
  >   let inc x = x + 1
  >   syli_print_i64 (apply2 inc 10)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build ho.sy
  $ ./ho.exe
  11

Sole-unit function used as a value (0-arg closure, dispatch-only apply):
  $ cat >unit_value.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let g () = 42
  > let call f = f ()
  > let main () =
  >   let r = call g
  >   syli_print_i64 r
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build unit_value.sy
  $ ./unit_value.exe
  42

Partial application with a trailing unit argument:
  $ cat >trailing_unit.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let add x () = x
  > let main () =
  >   let add1 = add 2
  >   let result =
  >     if false then
  >       add1 ()
  >     else add1 ()
  >   syli_print_i64 result
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build trailing_unit.sy
  $ ./trailing_unit.exe
  2

Local closure capturing another local closure:
  $ cat >capture_closure.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let main () =
  >   let a = 3
  >   let f x = x + a
  >   let g x = f (f x)
  >   syli_print_i64 (g 1)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build capture_closure.sy
  $ ./capture_closure.exe
  7
