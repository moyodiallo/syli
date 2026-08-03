Ref type inference:
  $ cat >test_ref.sy <<EOF
  > let a = ref 0
  > let b = ref 1.5
  > fn incr (r : ref int64) = r := *r + 1
  > fn main () = 0
  > EOF
  $ dune exec sylic typing test_ref.sy
  Typed test_ref.sy successfully: module Test_ref with 4 top-level typed items
  Type Environment:
  {
    a : ref<int64>
    b : ref<double>
    incr : (ref<int64>) -> unit
    main : (unit) -> int64
  }

Deref must operate on a ref type:
  $ cat >test_ref.sy <<EOF
  > fn main () =
  >   let x = 5
  >   let y = *x
  > EOF
  $ dune exec sylic typing test_ref.sy
  Fatal error: exception Syli_typing__Env.Type_error("type mismatch: int64 vs ref<'21>")
  [2]

Reference must have coherantly typed:
  $ cat >test_ref.sy <<EOF
  > fn main () =
  >   let x = ref 5
  >   x := 3.0
  > EOF
  $ dune exec sylic typing test_ref.sy
  Fatal error: exception Syli_typing__Env.Type_error("type mismatch: int64 vs double")
  [2]
