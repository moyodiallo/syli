Partial application storing an object (function value) as a new argument:
  $ cat >partial_obj.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let apply2 f x = f x
  > let inc x = x + 1
  > let main () =
  >   let p = apply2 inc
  >   syli_print_i64 (p 1)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build partial_obj.sy
  $ ./partial_obj.exe
  2
