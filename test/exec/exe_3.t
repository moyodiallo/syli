End-to-end runtime binary tests

Test 1: Compile, link, and run binary directly
  $ cat >test_binary.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let main () = syli_print_i64(42)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_binary.sy
  $ ./test_binary.exe && echo
  42

Test 3: Compile, link, and run another binary
  $ cat >startup_check.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let main () = syli_print_i64(1)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build startup_check.sy
  $ ./startup_check.exe && echo
  1

Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let apply f x y = f x y
  > let add x y z = x
  > let main () =
  >   let add1 = add 1
  >   let result = apply add1 3 4
  >   let result2 = apply add1 1.0 2.0
  >   syli_print_i64 result
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_multi.sy
  $ ./test_multi.exe
  1

Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let apply f x y = f x y
  > let add x y z = y
  > let main () =
  >   let add1 = add 1
  >   let result =
  >     if false then
  >       apply add1 3 4
  >     else apply add1 7 2.0
  >   syli_print_i64 result
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_multi.sy
  $ ./test_multi.exe
  7

String literal prints via syli_print_string:
  $ cat >test_str.sy <<EOF
  > foreign syli_print_string : string -> unit = "syli_print_string"
  > let s = "hello"
  > let main () = syli_print_string s
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_str.sy
  $ ./test_str.exe
  hello

Empty string literal compiles and runs:
  $ cat >test_empty.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let s = ""
  > let main () =
  >   syli_print_i64 42
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_empty.sy
  $ ./test_empty.exe
  42

Empty string printed via syli_print_string:
  $ cat >test_empty2.sy <<EOF
  > foreign syli_print_string : string -> unit = "syli_print_string"
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let s = ""
  > let main () =
  >   syli_print_string s
  >   syli_print_i64 42
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_empty2.sy
  $ ./test_empty2.exe
  42

Global int64 value read inside a function body:
  $ cat >test_global.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let x = 42
  > let main () = syli_print_i64 x
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_global.sy
  $ ./test_global.exe
  42

Global str value read inside a function body:
  $ cat >test_global_str.sy <<EOF
  > foreign syli_print_string : string -> unit = "syli_print_string"
  > let s = "global str"
  > let main () = syli_print_string s
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_global_str.sy
  $ ./test_global_str.exe
  global str

String escape sequences:
  $ cat >test_esc_str.sy <<EOF
  > foreign syli_print_string : string -> unit = "syli_print_string"
  > let main () =
  >   syli_print_string "hello\nworld"
  >   syli_print_string "\x41\x42\x43"
  >   syli_print_string "quot\"here"
  >   syli_print_string "back\\\\slash"
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_esc_str.sy
  $ ./test_esc_str.exe
  hello
  worldABCquot"hereback\slash

Char literal printed via syli_print_char:
  $ cat >test_char.sy <<EOF
  > foreign syli_print_char : char -> unit = "syli_print_char"
  > let main () = syli_print_char 'A'
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_char.sy
  $ ./test_char.exe
  A

String passed to a function parameter and returned:
  $ cat >test_str_fn.sy <<EOF
  > foreign syli_print_string : string -> unit = "syli_print_string"
  > let id (s: string) = s
  > let main () =
  >   let s = "hello"
  >   let r = id s
  >   syli_print_string r
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_str_fn.sy
  $ ./test_str_fn.exe
  hello

String returned from a closure capturing it:
  $ cat >test_str_closure.sy <<EOF
  > foreign syli_print_string : string -> unit = "syli_print_string"
  > let main () =
  >   let s = "hi"
  >   let f () = s
  >   let r = f ()
  >   syli_print_string r
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_str_closure.sy
  $ ./test_str_closure.exe
  hi

