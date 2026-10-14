Object reused after being passed as an applied argument to a closure:
  $ cat >live_after.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > type box = { mutable value: i64 }
  > let mk v f = f v
  > let main () =
  >   let b = { value = 40 }
  >   let go v f = mk v f
  >   let r = go b (fun (x : box) -> x.value)
  >   syli_print_i64 (r + b.value)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build live_after.sy
  $ ./live_after.exe
  80
