Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > let apply f x y = f x y
  > let add x y z = y
  > fn main () =
  >   let add1 = add 1
  >   let result =
  >     if false then
  >       apply add1 3 4
  >     else apply add1 7 2.0
  >   syli_print_i64 result
  > EOF
  $ dune exec sylic -- build test_multi.sy
  $ ./test_multi.exe
  Segmentation fault (core dumped)
  ***** UNREACHABLE *****

Closure as an argument with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > let apply f x y = f x y
  > let add x y z = x
  > fn main () =
  >   let add1 = add 1
  >   let result = apply add1 3 4
  >   let result2 = apply add1 1.0 2.0
  >   syli_print_i64 result
  > EOF
  ***** UNREACHABLE *****
  $ dune exec sylic -- build test_multi.sy
  ***** UNREACHABLE *****
  $ ./test_multi.exe
  ***** UNREACHABLE *****

Closure with multiple captured variables:
  $ cat >test_multi.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > let add x y = x + y
  > let apply f x y = f x y
  > fn main () = 
  >   let result = apply add 3 4
  >   syli_print_i64(result)
  > EOF
  ***** UNREACHABLE *****
  $ dune exec sylic -- build test_multi.sy test_multi.opt.exe
  ***** UNREACHABLE *****
  $ ./test_multi.opt.exe
  ***** UNREACHABLE *****

Complex test combining closures, dispatch, casts, partial application, and if-then-else:
  $ cat >complex_dispatch.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > let add x y z = x
  > let apply f x y = f x y
  > fn main () =
  >   let add1 = add 1
  >   let r1 = apply add1 10 20
  >   syli_print_i64 r1
  >   let r2 = apply add1 1.0 2.0
  >   syli_print_i64 r2
  >   let add1and2 = add1 2
  >   let r3 = add1and2 30
  >   syli_print_i64 r3
  >   let r4 = add1and2 3.0
  >   syli_print_i64 r4
  >   let r5 =
  >     if true then
  >       apply add1 100 200
  >     else
  >       apply add1 1.0 2.0
  >   syli_print_i64 r5
  > EOF
  ***** UNREACHABLE *****
  $ dune exec sylic -- build complex_dispatch.sy
  ***** UNREACHABLE *****
  $ ./complex_dispatch.exe
  ***** UNREACHABLE *****

  $ cat >test_e2e_print.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > type person = { name: int64; age: int64 }
  > fn main () =
  >     let record = { name = 10; age = 30 }
  >     syli_print_i64(record.age)
  > EOF
  ***** UNREACHABLE *****
  $ dune exec sylic -- build test_e2e_print.sy
  ***** UNREACHABLE *****
  $ ./test_e2e_print.exe && echo
  ***** UNREACHABLE *****

Test 4: Compile, link, and run arithmetic binary
  $ cat >test_e2e_expr.sy <<EOF2
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > fn main () = syli_print_i64(100 + 23)
  > EOF2
  ***** UNREACHABLE *****
  $ dune exec sylic -- build test_e2e_expr.sy
  ***** UNREACHABLE *****
  $ ./test_e2e_expr.exe
  ***** UNREACHABLE *****
