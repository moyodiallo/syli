Array literal, allocation, and index get/set:
  $ cat >arr.sy <<EOF
  > let a = [| 1; 2; 3 |]
  > let b = a.[0]
  > let _ = a.[1] := 42
  > let c = [| 4: fun i -> i |]
  > EOF
  $ dune exec sylic parse arr.sy
  Parsed arr.sy
  let a = [| 1; 2; 3 |]
  let b = a.[0]
  let _ = a.[1] := 42
  let c = [| 4: lambda(i) {
    i
  } |]
