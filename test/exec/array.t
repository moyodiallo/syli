Array literal + index get:
  $ cat >test_arr.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let main () =
  >   let a = [| 10; 20; 30 |]
  >   syli_print_i64 (a.[1])
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_arr.sy
  $ ./test_arr.exe
  20

Array index set:
  $ cat >test_arr.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let main () =
  >   let a = [| 1; 2; 3 |]
  >   a.[0] := 99
  >   syli_print_i64 (a.[0])
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_arr.sy
  $ ./test_arr.exe
  99

Array allocation with an initializer function:
  $ cat >test_arr.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > let main () =
  >   let a = [| 4: fun i -> i + 1 |]
  >   syli_print_i64 (a.[2])
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_arr.sy
  $ ./test_arr.exe
  3

Recursively print every element:
  $ cat >test_arr.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (+) : i64 -> i64 -> i64 = "add"
  > primitive (<) : i64 -> i64 -> bool = "lt"
  > let rec print_arr a i n =
  >   if i < n then
  >     syli_print_i64 (a.[i])
  >     print_arr a (i + 1) n
  >   else
  >     ()
  > let main () =
  >   let a = [| 1; 2; 3 |]
  >   print_arr a 0 3
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_arr.sy
  $ ./test_arr.exe
  123

Allocate using a named function as the initializer:
  $ cat >test_arr.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let f i = i
  > let arr = [| 20: f |]
  > let main () =
  >   syli_print_i64 (arr.[7])
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_arr.sy
  $ ./test_arr.exe
  7

Allocation size from a variable:
  $ cat >test_arr.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let f i = i
  > let n = 20
  > let arr = [| n: f |]
  > let main () =
  >   syli_print_i64 (arr.[7])
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_arr.sy
  $ ./test_arr.exe
  7

Array length (`array_len`) and byte size (`array_size`) primitives:
  $ cat >test_arr.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive len : 'a array -> i64 = "array_len"
  > primitive size : 'a array -> i64 = "array_size"
  > let main () =
  >   let a = [| 10; 20; 30 |]
  >   syli_print_i64 (len a)
  >   syli_print_i64 (size a)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_arr.sy
  $ ./test_arr.exe
  324

`array_size` of a packed char array uses the element cell width (1 byte):
  $ cat >test_arr.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive size : 'a array -> i64 = "array_size"
  > let main () =
  >   let a = [| 'a'; 'b'; 'c' |]
  >   syli_print_i64 (size a)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_arr.sy
  $ ./test_arr.exe
  3

`array_len` of an allocated array:
  $ cat >test_arr.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive len : 'a array -> i64 = "array_len"
  > let f i = i
  > let n = 20
  > let main () =
  >   let a = [| n: f |]
  >   syli_print_i64 (len a)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_arr.sy
  $ ./test_arr.exe
  20
