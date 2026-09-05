  $ cat >parse0.src <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > type person = { name: str; age: i64 }
  > let add x y = x + y
  > let add10 = add 10
  > let add20 = add10 20
  > EOF
  $ dune exec sylic typing parse0.src
  Typed parse0.src successfully: module Parse0 with 5 top-level typed items
  Type Environment:
  {
    + : i64 -> i64 -> i64
    add : i64 -> i64 -> i64
    add10 : i64 -> i64
    add20 : i64
  }


  $ cat >parse0.src <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > type person = { name: str; age: i64 }
  > let add x y = x + y
  > let z = add 10 20
  > EOF
  $ dune exec sylic typing parse0.src
  Typed parse0.src successfully: module Parse0 with 4 top-level typed items
  Type Environment:
  {
    + : i64 -> i64 -> i64
    add : i64 -> i64 -> i64
    z : i64
  }


  $ cat >parse0.src <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > type person = { name: str; age: i64 }
  > let add x y = x + y
  > let z = add 10 20.
  > EOF
  $ dune exec sylic typing parse0.src
  Fatal error: exception Syli_typing__Env.Type_error("type mismatch: i64 vs f64")
  [2]


  $ cat >parse0.src <<EOF
  > let add x y = (x, y)
  > let add10 = add 10
  > let add20 = add10 20
  > EOF
  $ dune exec sylic typing parse0.src
  Typed parse0.src successfully: module Parse0 with 3 top-level typed items
  Type Environment:
  {
    add : forall '32 '34. '32 -> '34 -> ('32 * '34)
    add10 : forall '38. '38 -> (i64 * '38)
    add20 : (i64 * i64)
  }

  $ cat >parse0.src <<EOF
  > let add x y = (x, y)
  > let add10 = add 10
  > let add20 = add10 20
  > let add_float = add 10.0
  > EOF
  $ dune exec sylic typing parse0.src
  Typed parse0.src successfully: module Parse0 with 4 top-level typed items
  Type Environment:
  {
    add : forall '40 '42. '40 -> '42 -> ('40 * '42)
    add10 : forall '46. '46 -> (i64 * '46)
    add20 : (i64 * i64)
    add_float : forall '51. '51 -> (f64 * '51)
  }

Capturing partial application.
  $ cat >parse0.src <<EOF
  > let add x y = (x, y)
  > let add10 = add 10
  > let add_let () = add10
  > let add20 = add10 20
  > let add_float = add 10.0
  > let let_r = add_let ()
  > let let_v = let_r 20
  > EOF
  $ dune exec sylic typing parse0.src
  Typed parse0.src successfully: module Parse0 with 7 top-level typed items
  Type Environment:
  {
    add : forall '63 '65. '63 -> '65 -> ('63 * '65)
    add10 : forall '69. '69 -> (i64 * '69)
    add20 : (i64 * i64)
    add_float : forall '77. '77 -> (f64 * '77)
    add_let : forall '72. unit -> '72 -> (i64 * '72)
    let_r : forall '79. '79 -> (i64 * '79)
    let_v : (i64 * i64)
  }
