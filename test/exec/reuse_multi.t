Object reused as an applied argument across several closure applications:
  $ cat >reuse_multi.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > type box = { mutable value: i64 }
  > let go f b = f b
  > let main () =
  >   let b = { value = 1 }
  >   let r1 = go (fun (x : box) -> x.value) b
  >   let r2 = go (fun (x : box) -> x.value) b
  >   syli_print_i64 ((r1 + r2) + b.value)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build reuse_multi.sy
  $ ./reuse_multi.exe
  3
