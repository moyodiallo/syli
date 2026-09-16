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
  Type error in parse0.src at line 11, column 4
  
    11 |     record2.something
             ^^^^^^^^^^^^^^^^^
  
  no record has field_name 'something'
  [1]

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
  Type error in parse0.src at line 10, column 36
  
    10 |     let record2 = { name = "test2"; age = 10.0 }
                                             ^^^^^^^^^^
  
  type mismatch: f64 vs i64
  [1]
