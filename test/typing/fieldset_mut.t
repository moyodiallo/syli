Assigning to a mutable record field is allowed:
  $ cat >test_fieldset_mut.sy <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > type counter = { mutable value: i64; id: i64 }
  > let main () =
  >   let c = { value = 0; id = 7 }
  >   c.value := 42
  >   c.value + 1
  > EOF
  $ dune exec sylic typing test_fieldset_mut.sy
  Typed test_fieldset_mut.sy successfully: module Test_fieldset_mut with 3 top-level typed items
  Type Environment:
  {
    + : i64 -> i64 -> i64
    main : unit -> i64
  }

Assigning to an immutable record field is a type error:
  $ cat >test_fieldset_immutable.sy <<EOF
  > type person = { name: i64; age: i64 }
  > let main () =
  >   let p = { name = 1; age = 2 }
  >   p.name := 10
  > EOF
  $ dune exec sylic typing test_fieldset_immutable.sy
  Fatal error: exception Syli_typing__Env.Type_error("field 'name' is immutable")
  [2]
