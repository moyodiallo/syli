Basic type checking and inference

Integer literals and operations:
  $ cat >test_int.sy <<EOF
  > primitive add_int: i64 -> i64 -> i64 = "add"
  > let x = 42
  > let y = add_int x 10
  > EOF
  $ dune exec sylic typing test_int.sy
  Typed test_int.sy successfully: module Test_int with 3 top-level typed items
  Type Environment:
  {
    add_int : i64 -> i64 -> i64
    x : i64
    y : i64
  }

  $ dune exec sylic parse test_int.sy
  Parsed test_int.sy
  extern add_int : i64 -> i64 -> i64
  let x = 42
  let y = add_int x 10

Boolean literals and operations:
  $ cat >test_bool.sy <<EOF
  > let p = true
  > let q = false
  > EOF
  $ dune exec sylic typing test_bool.sy
  Typed test_bool.sy successfully: module Test_bool with 2 top-level typed items
  Type Environment:
  {
    p : bool
    q : bool
  }

String literals:
  $ cat >test_string.sy <<EOF
  > let s = "hello"
  > let t = "world"
  > EOF
  $ dune exec sylic typing test_string.sy
  Typed test_string.sy successfully: module Test_string with 2 top-level typed items
  Type Environment:
  {
    s : string
    t : string
  }

Arithmetic operations result in integers:
  $ cat >test_arith.sy <<EOF
  > let a = 5 + 3
  > let b = 10 - 2
  > let c = 4 * 6
  > let d = 20 / 4
  > EOF
  $ dune exec sylic typing test_arith.sy
  Fatal error: exception Syli_typing__Env.Type_error("Unbound identifier '+'")
  [2]

  $ cat >test_arith.sy <<EOF
  > let a = 5.0 + 3.0
  > let b = 10. - 2.0
  > let c = 4. * 6.
  > let d = 20. / 4.
  > EOF
  $ dune exec sylic typing test_arith.sy
  Fatal error: exception Syli_typing__Env.Type_error("Unbound identifier '+'")
  [2]

Comparison operations result in booleans:
  $ cat >test_cmp.sy <<EOF
  > let eq = 5 == 5
  > let ne = 3 != 4
  > let lt = 2 < 5
  > let le = 5 <= 5
  > let gt = 10 > 3
  > let ge = 5 >= 5
  > EOF
  $ dune exec sylic typing test_cmp.sy
  Fatal error: exception Syli_typing__Env.Type_error("Unbound identifier '=='")
  [2]

Tuple types:
  $ cat >test_tuple.sy <<EOF
  > let pair = (1, 2)
  > let triple = (true, 42, "test")
  > EOF
  $ dune exec sylic typing test_tuple.sy
  Typed test_tuple.sy successfully: module Test_tuple with 2 top-level typed items
  Type Environment:
  {
    pair : (i64 * i64)
    triple : (bool * i64 * string)
  }

Tuple types:
  $ cat >test_tuple.sy <<EOF
  > let pair x y = (x, y)
  > let triple x y z = (x, y, z)
  > let pair_int = pair 1
  > let one_int = pair_int 42
  > let one_str = pair_int "hello"
  > EOF
  $ dune exec sylic typing test_tuple.sy
  Typed test_tuple.sy successfully: module Test_tuple with 5 top-level typed items
  Type Environment:
  {
    one_int : (i64 * i64)
    one_str : (i64 * string)
    pair : forall '57 '59. '57 -> '59 -> ('57 * '59)
    pair_int : forall '70. '70 -> (i64 * '70)
    triple : forall '62 '64 '66. '62 -> '64 -> '66 -> ('62 * '64 * '66)
  }

Lambda expressions:
  $ cat >test_lambda.sy <<EOF
  > let id = fun x -> x
  > let double = fun x -> x + x
  > EOF
  $ dune exec sylic typing test_lambda.sy
  Fatal error: exception Syli_typing__Env.Type_error("Unbound identifier '+'")
  [2]

Curried lambda expressions:
  $ cat >test_curried.sy <<EOF
  > let add = fun x y -> x + y
  > EOF
  $ dune exec sylic typing test_curried.sy
  Fatal error: exception Syli_typing__Env.Type_error("Unbound identifier '+'")
  [2]


Multiple bindings:
  $ cat >test_multi.sy <<EOF
  > let x = 1
  > let y = 2
  > let z = x + y
  > EOF
  $ dune exec sylic typing test_multi.sy
  Fatal error: exception Syli_typing__Env.Type_error("Unbound identifier '+'")
  [2]

  $ cat >array_list.t <<EOF
  > let arr = [1, 2, 3, 4]
  > let lst = [true, false, true]
  > EOF
  $ dune exec sylic typing array_list.t
  
  Parse error in array_list.t at line 1, column 10
  
    1 | let arr = [1, 2, 3, 4]
                   ^
  
  Unexpected token: '['
  
  [1]


Identity function and partial application:
  $ cat >test_id.sy <<EOF
  > let id x = x
  > let id_int = id 42
  > let id_str = id "hello"
  > let id_float = id 3.14
  > EOF
  $ dune exec sylic typing test_id.sy
  Typed test_id.sy successfully: module Test_id with 4 top-level typed items
  Type Environment:
  {
    id : forall '35. '35 -> '35
    id_float : f64
    id_int : i64
    id_str : string
  }


Closures as an argument:
  $ cat >test_closure.sy <<EOF
  > let apply_twice f x = f (f x)
  > let double_x x = x + x
  > let result = apply_twice double_x 10
  > EOF
  $ dune exec sylic typing test_closure.sy
  Fatal error: exception Syli_typing__Env.Type_error("Unbound identifier '+'")
  [2]

main function test with FFI and record types:
  $ cat >test_e2e_print.sy <<EOF
  > signature Sig_ex
  >   foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > end
  > type person = { name: i64; age: i64 }
  > let record0 = { name = 10; age = 30 }
  > let main () =
  >     let record1 = { name = 10; age = 30 }
  >     syli_print_i64(record1.age)
  > EOF
  $ dune exec sylic typing test_e2e_print.sy
  Fatal error: exception Syli_typing__Env.Type_error("Unbound identifier 'syli_print_i64'")
  [2]

Polymorpic Closures as an argument:
  $ cat >test_closure.sy <<EOF
  > let id x = x
  > let apply_twice f x = f (f x)
  > let result_1 = apply_twice id 10
  > let result_2 = apply_twice id "hello"
  > EOF
  $ dune exec sylic typing test_closure.sy
  Typed test_closure.sy successfully: module Test_closure with 4 top-level typed items
  Type Environment:
  {
    apply_twice : forall '55. '55 -> '55 -> '55 -> '55
    id : forall '47. '47 -> '47
    result_1 : i64
    result_2 : string
  }

To support higher rank like rank 2 here: we need to annotate f,
type a. like OCaml did or forall a. like Haskell.
It could be supported easily by the type system but for the runtime support, we 
need more work to do, extend closure_graph or adapt it.
  $ cat >test_closure.sy <<EOF
  > let id x = x
  > let apply_both f = (f 10, f "hello")
  > let result = apply_both id
  > EOF
  $ dune exec sylic typing test_closure.sy
  Fatal error: exception Syli_typing__Env.Type_error("type mismatch: i64 vs string")
  [2]


  $ cat >test_closure.sy <<EOF
  > let id x = x
  > let apply_twice f x = f (f x)
  > let result = apply_twice id id
  > EOF
  $ dune exec sylic typing test_closure.sy
  Typed test_closure.sy successfully: module Test_closure with 3 top-level typed items
  Type Environment:
  {
    apply_twice : forall '45. '45 -> '45 -> '45 -> '45
    id : forall '37. '37 -> '37
    result : forall '49. '49 -> '49
  }


