  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (==) : i64 -> i64 -> bool = "eq"
  > primitive (*) : i64 -> i64 -> i64 = "mul"
  > primitive (-) : i64 -> i64 -> i64 = "sub"
  > let rec factorial n =
  >   if n == 0 then
  >     1
  >   else
  >     n * factorial (n - 1)
  > let main () = syli_print_i64 (factorial 5)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_file.sy
  $ ./test_file.exe
  120

  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type person = { name: i64; age: i64 }
  > let main () =
  >     let record = { name = 10; age = 30 }
  >     syli_print_i64(record.age)
  >     syli_print_i64(record.name)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_file.sy
  $ ./test_file.exe && echo
  3010

  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > primitive (-)  : i64 -> i64 -> i64 = "sub"
  > let add x y = x + y
  > let sub x y = x - y
  > let main () =
  >   let add1 = add 1
  >   let sub1 = sub 1
  >   let f = if false then add1 else sub1
  >   let result = f 2
  >   syli_print_i64 result
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_file.sy
  $ ./test_file.exe
  -1

  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let id x = x
  > let apply_twice f x = f (f x)
  > let main () =
  >   let result_1 = apply_twice id 10
  >   syli_print_i64 result_1
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_file.sy
  $ ./test_file.exe
  10

  $ cat >test_multi.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > foreign syli_print_f64 : f64 -> unit = "syli_print_f64"
  > let add x z = z
  > let main () =
  >   let add1 = add 1
  >   let d = add1 1.0
  >   let i = add1 1
  >   syli_print_i64 i
  >   syli_print_f64 d
  >   i
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_multi.sy
  $ ./test_multi.exe
  11.000000

  $ cat >test_multi.sy <<EOF
  > let add x y z = z
  > let main () =
  >   let add1 = add 1
  >   let d = add1 1.0 2
  >   let i = add1 1 2
  >   i
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_multi.sy
  $ ./test_multi.exe

Monomorphization issue.
  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > let add x y z = y + z
  > let apply () =
  >   let add1 = add 1
  >   let add1and2 = add1 2
  >   let result = add1and2 3
  >   result
  > let main () = 
  >   let result = apply ()
  >   syli_print_i64 result
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_file.sy
  $ ./test_file.exe
  5

  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > let add x y z = x + y + z
  > let apply () =
  >   let add1 = add 1
  >   let add1and2 = add1 2
  >   let result = add1and2 3
  >   result
  > let main () = 
  >   let result = apply ()
  >   syli_print_i64 result
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_file.sy
  $ ./test_file.exe
  6
