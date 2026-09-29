One polymorphic higher-order function used as a closure over an object and over i64:
  $ cat >two_kinds.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > type box = { mutable value: i64 }
  > let mk v f = f v
  > let main () =
  >   let b = { value = 40 }
  >   let go v f = mk v f
  >   syli_print_i64 ((go b (fun (x : box) -> x.value)) + (go 2 (fun x -> x)))
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build two_kinds.sy
  $ ./two_kinds.exe
  42
