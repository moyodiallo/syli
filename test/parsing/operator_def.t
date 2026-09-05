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
