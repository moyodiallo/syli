Applying a record value directly as a function hits an internal error:
  $ cat >test_apply_direct.src <<EOF
  > type person = { name: int64; age: int64 }
  > let mk (name : int64) = { name = name; age = 30 }
  > fn main () =
  >   let mk42 = mk 42
  >   let record = mk42 ()
  >   syli_print_i64 (record.name)
  > EOF
  $ dune exec sylic typing test_apply_direct.src
  Fatal error: exception Syli_typing__Env.Type_error("internal error: expected function type after unification")
  [2]
