Returning a record from a function:
  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type person = { name: i64; age: i64 }
  > let make_person () = { name = 10; age = 30 }
  > let main () =
  >   let record = make_person ()
  >   syli_print_i64 (record.age)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_file.sy
  $ ./test_file.exe
  30

Returning a record through a function constructing it with its param:
  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type person = { name: i64; age: i64 }
  > let mk (name : i64) = { name = name; age = 30 }
  > let main () =
  >   let record = mk 42
  >   syli_print_i64 (record.name)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_file.sy
  $ ./test_file.exe
  42
