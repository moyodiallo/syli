Nested closures capturing closures with multiple application levels:
  $ cat >triple.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let main () =
  >   let a = 3
  >   let f x = x + a
  >   let g x = f (f x)
  >   let h y = g (g y)
  >   syli_print_i64 (h 1)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build triple.sy
  $ ./triple.exe
  13

