Applying a record value as a function through a generic apply is rejected:
  $ cat >test_apply_record.src <<EOF
  > type person = { name: int64; age: int64 }
  > let mk (name : int64) = { name = name; age = 30 }
  > let apply f x = f x
  > fn main () =
  >   let record = apply (mk 42) ()
  >   syli_print_i64 (record.name)
  > EOF
  $ dune exec sylic typing test_apply_record.src
  Fatal error: exception Syli_typing__Env.Type_error("type mismatch: ('76) -> '77 vs person")
  [2]
