Object returned through a generic closure and reused by the caller:
  $ cat >gen_ret.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > type box = { mutable value: i64 }
  > let id v = v
  > let main () =
  >   let b = { value = 7 }
  >   let g = id b
  >   syli_print_i64 (g.value + b.value)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build gen_ret.sy
  $ ./gen_ret.exe
  14
