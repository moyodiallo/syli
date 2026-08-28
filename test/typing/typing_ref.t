Ref type inference:
  $ cat >test_ref.sy <<EOF
  > let a = ref 0
  > let b = ref 1.5
  > let incr (r : ref i64) = r := *r + 1
  > let main () = 0
  > EOF
  $ dune exec sylic typing test_ref.sy
  
  Parse error in test_ref.sy at line 3, column 18
  
    3 | let incr (r : ref i64) = r := *r + 1
                           ^^^^^
  
  Unexpected token: 'INT64'
  
  [1]

Deref must operate on a ref type:
  $ cat >test_ref.sy <<EOF
  > let main () =
  >   let x = 5
  >   let y = *x
  > EOF
  $ dune exec sylic typing test_ref.sy
  
  Parse error in test_ref.sy at line 3, column 10
  
    3 |   let y = *x
                   ^
  
  Unexpected token: '*'
  
  [1]

Reference must have coherantly typed:
  $ cat >test_ref.sy <<EOF
  > let main () =
  >   let x = ref 5
  >   x := 3.0
  > EOF
  $ dune exec sylic typing test_ref.sy
  Fatal error: exception Syli_typing__Env.Type_error("Unbound identifier 'ref'")
  [2]
