  $ cat >operators.sy <<EOF
  > let (==) f x =  f x
  > let _ = print_int 8
  > EOF
  $ dune exec sylic -- parse operators.sy
  Parsed operators.sy
  let (==) = lambda(f, x) {
    f x
  }
  let _ = print_int 8

Failing: an alphabetic operator must use the # marker, not be spelled like an identifier
  $ cat >bad_op.sy <<EOF
  > let (index_set) x = x
  > EOF
  $ dune exec sylic -- parse bad_op.sy
  Parse error in bad_op.sy at line 1, column 5
  
    1 | let (index_set) x = x
             ^^^^^^^^^^^^^^^^
  
  Unexpected token: 'IDENT(index_set)'
  [1]

Failing: the operator marker must be inside parens
  $ cat >bad_op.sy <<EOF
  > let #index_set x = x
  > EOF
  $ dune exec sylic -- parse bad_op.sy
  Parse error in bad_op.sy at line 1, column 4
  
    1 | let #index_set x = x
            ^
  
  Unexpected token: '#'
  [1]
