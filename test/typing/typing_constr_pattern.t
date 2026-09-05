pattern match with variant constructors
  $ cat >test_pattern.sy <<'EOF'
  > type option = None | Some of i64
  > let opt = Some 3
  > let m =
  >   match opt with
  >   | None -> 2
  >   | Some _ -> 3
  > EOF
  $ dune exec sylic typing test_pattern.sy
  Typed test_pattern.sy successfully: module Test_pattern with 3 top-level typed items
  Type Environment:
  {
    m : i64
    opt : option
  }

constructor as a value
TODO: we must forbid this 'let f = Some' when 'Some' is defined with a argument.
  $ cat >test_ctor_value.sy <<'EOF'
  > type option = None | Some of i64
  > let f = Some
  > let none = None
  > EOF
  $ dune exec sylic typing test_ctor_value.sy
  Typed test_ctor_value.sy successfully: module Test_ctor_value with 3 top-level typed items
  Type Environment:
  {
    f : i64 -> option
    none : option
  }

nested variant constructors
  $ cat >test_nested.sy <<'EOF'
  > type opt = None | Some of i64
  > type wrapper = Simple of wrapper | Other of opt
  > let w = Simple (Other (Some 3))
  > EOF
  $ dune exec sylic typing test_nested.sy
  Typed test_nested.sy successfully: module Test_nested with 3 top-level typed items
  Type Environment:
  {
    w : wrapper
  }

nested constructors require parentheses
  $ cat >test_nested_reject.sy <<'EOF'
  > type opt = None | Some of i64
  > type wrapper = Simple of wrapper | Other of opt
  > let w = Simple Other Some 3
  > EOF
  $ dune exec sylic typing test_nested_reject.sy
  Typed test_nested_reject.sy successfully: module Test_nested_reject with 3 top-level typed items
  Type Environment:
  {
    w : wrapper
  }

  $ cat >test_nested_reject2.sy <<'EOF'
  > type opt = None | Some of i64
  > type wrapper = Simple of wrapper | Other of opt
  > let w = Simple Other (Some 3)
  > EOF
  $ dune exec sylic typing test_nested_reject2.sy
  Typed test_nested_reject2.sy successfully: module Test_nested_reject2 with 3 top-level typed items
  Type Environment:
  {
    w : wrapper
  }

constructor with a record argument
  $ cat >test_constr_record.sy <<'EOF'
  > type shape = Circle of { radius: f64 } | Rect of { w: f64; h: f64 }
  > let c = Circle { radius = 1.0 }
  > EOF
  $ dune exec sylic typing test_constr_record.sy
  Typed test_constr_record.sy successfully: module Test_constr_record with 2 top-level typed items
  Type Environment:
  {
    c : shape
  }

unknown variant constructor
  $ cat >test_unknown_ctor.sy <<'EOF'
  > let x = Foo 3
  > EOF
  $ dune exec sylic typing test_unknown_ctor.sy
  Fatal error: exception Syli_typing__Env.Type_error("unknown variant constructor 'Foo'")
  [2]

nullary constructor applied to an argument
  $ cat >test_nullary_ctor.sy <<'EOF'
  > type option = None | Some of i64
  > let x = None 3
  > EOF
  $ dune exec sylic typing test_nullary_ctor.sy
  Fatal error: exception Syli_typing__Env.Type_error("variant constructor 'None' takes no argument")
  [2]

constructor argument type mismatch
  $ cat >test_ctor_mismatch.sy <<'EOF'
  > type option = None | Some of i64
  > let x = Some "hi"
  > EOF
  $ dune exec sylic typing test_ctor_mismatch.sy
  Fatal error: exception Syli_typing__Env.Type_error("type mismatch: string vs i64")
  [2]

applying a constructed variant value
  $ cat >test_ctor_apply.sy <<'EOF'
  > type option = None | Some of i64
  > let x = (Some 3) 4
  > EOF
  $ dune exec sylic typing test_ctor_apply.sy
  Fatal error: exception Syli_typing__Env.Type_error("variant constructor 'Some' is not a function")
  [2]
