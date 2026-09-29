Pattern match on integer literals:
  $ cat >test_match_int.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let describe (x : i64) =
  >   match x with
  >   | 0 -> 100
  >   | 1 -> 200
  >   | _ -> 300
  > let main () =
  >   syli_print_i64 (describe 0)
  >   syli_print_i64 (describe 1)
  >   syli_print_i64 (describe 7)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_match_int.sy
  $ ./test_match_int.exe
  100200300

Pattern match on a record:
  $ cat >test_match_record.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type person = { name: i64; age: i64 }
  > let main () =
  >   let p = { name = 10; age = 30 }
  >   let v = match p with { name = x; age = y } -> x
  >   syli_print_i64 v
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_match_record.sy
  $ ./test_match_record.exe
  10

Pattern match with a guard:
  $ cat >test_match_guard.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (==) : i64 -> i64 -> bool = "eq"
  > let main () =
  >   let x = 5
  >   let v =
  >     match x with
  >     | n when n == 3 -> 10
  >     | n -> n
  >   syli_print_i64 v
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_match_guard.sy
  $ ./test_match_guard.exe
  5

Pattern match with a guard containing a nested match:
  $ cat >test_match_guard_nested.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type color = Red | Green | Blue
  > let f (c : color) (d : color) =
  >   match c with
  >   | _ when (match d with Red -> true | _ -> false) -> 1
  >   | x -> (match x with Red -> 10 | Green -> 20 | Blue -> 30)
  > let main () = syli_print_i64 (f Blue Green)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_match_guard_nested.sy
  $ ./test_match_guard_nested.exe
  30

A non-exhaustive match aborts:
  $ cat >test_match_fail.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let main () =
  >   let x = 5
  >   let v = match x with 0 -> 10
  >   syli_print_i64 v
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_match_fail.sy
  $ { if (./test_match_fail.exe 2>msg.txt); then st=0; else st=$?; fi; cat msg.txt; echo "exit=$st"; } 2>/dev/null
  match failure
  exit=134
