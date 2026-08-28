  $ cat >parse0.src <<EOF
  > type person = { name: string; age: i64 }
  > let add () =
  >     let record =
  >     {
  >         name = "test";
  >         age = 5
  >     }
  >     2
  > end
  > EOF
  $ dune exec sylic typing parse0.src
  Typed parse0.src successfully: module Parse0 with 2 top-level typed items
  Type Environment:
  {
    add : unit -> i64
  }

  $ cat >parse0.src <<EOF
  > type person = { name: string; age: i64 }
  > let add () =
  >     let record =
  >     {
  >         name = "test";
  >         age = 5
  >     }
  >     2
  > end
  > EOF
  $ dune exec sylic typing parse0.src
  Typed parse0.src successfully: module Parse0 with 2 top-level typed items
  Type Environment:
  {
    add : unit -> i64
  }

  $ cat >parse0.src <<EOF
  > type grown_person = { name: string; age: i64; grown: bool }
  > type person = { name: string; age: i64 }
  > let add () =
  >     let record =
  >     {
  >         name = "test";
  >         age = 5 ;
  >         grown = true
  >     }
  >     let record2 = { name = "test2"; age = 10 }
  >     2
  > end
  > EOF
  $ dune exec sylic typing parse0.src
  Typed parse0.src successfully: module Parse0 with 3 top-level typed items
  Type Environment:
  {
    add : unit -> i64
  }

  $ cat >parse0.src <<EOF
  > type grown_person = { name: string; age: i64; grown: bool }
  > type person = { name: string; age: i64 }
  > let add () =
  >     let record =
  >     {
  >         name = "test";
  >         age = 5 ;
  >         grown = true
  >     }
  >     let record2 = { name = "test2"; age = 10 }
  >     record2.something
  > end
  > EOF
  $ dune exec sylic typing parse0.src
  Fatal error: exception Syli_typing__Env.Type_error("no record has field_name 'something'")
  [2]

  $ cat >parse0.src <<EOF
  > type grown_person = { name: string; age: i64; grown: bool }
  > type person = { name: string; age: i64 }
  > let add () =
  >     let record =
  >     {
  >         name = "test";
  >         age = 5 ;
  >         grown = true
  >     }
  >     let record2 = { name = "test2"; age = 10.0 }
  >     record2.something
  > end
  > EOF
  $ dune exec sylic typing parse0.src
  Fatal error: exception Syli_typing__Env.Type_error("type mismatch: f64 vs i64")
  [2]
