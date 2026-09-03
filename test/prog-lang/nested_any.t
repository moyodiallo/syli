  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let id x = x
  > let apply_twice f x = f (f x)
  > let main () =
  >   let _ = apply_twice id 10
  >   syli_print_i64 2
  > EOF
  $ dune exec sylic -- core test_file.sy
  module Test_file
  extern syliTest_file.syli_print_i64 : (i64) -> unit
  
  let syliTest_file.id = fun (x) : 'a53 ->
      x : 'a53
  
  let syliTest_file.apply_twice = fun (f, x) : 'a61 ->
      f(f(x : 'a61) : 'a61) : 'a61
  
  let syliTest_file.main = fun () : unit ->
      {
        let sy1_any_pat = syliTest_file.apply_twice(syliTest_file.id : (i64) -> i64, 10 : i64) : i64
        syliTest_file.syli_print_i64(2 : i64) : unit
      }
  
  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let id x = x
  > let apply_twice f x = f (f x)
  > let main () =
  >   let () = apply_twice id 10
  >   syli_print_i64 2
  > EOF
  $ dune exec sylic -- core test_file.sy
  
  Parse error in test_file.sy at line 5, column 7
  
    5 |   let () = apply_twice id 10
                ^
  
  Unexpected token: ')'
  
  ***** UNREACHABLE *****
