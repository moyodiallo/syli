Array typing: literal infers element type, index get/set, allocation:
  $ cat >arr.sy <<EOF
  > let a = [| 1; 2; 3 |]
  > let b = a.[0]
  > let _ = a.[1] := 42
  > let c = [| 4: fun i -> i |]
  > EOF
  $ dune exec sylic typing arr.sy
  Typed arr.sy successfully: module Arr with 4 top-level typed items
  Type Environment:
  {
    a : i64 array
    b : i64
    c : i64 array
  }

Array literal element type mismatch is a type error:
  $ cat >arr_lit_mismatch.sy <<EOF
  > let a = [| 1; true |]
  > EOF
  $ dune exec sylic typing arr_lit_mismatch.sy
  Type error in arr_lit_mismatch.sy at line 1, column 14
  
    1 | let a = [| 1; true |]
                      ^^^^
  
  type mismatch: bool vs i64
  [1]

Index expression must be i64:
  $ cat >arr_index_ty.sy <<EOF
  > let a = [| 1; 2 |]
  > let b = a.[true]
  > EOF
  $ dune exec sylic typing arr_index_ty.sy
  Type error in arr_index_ty.sy at line 2, column 11
  
    2 | let b = a.[true]
                   ^^^^
  
  type mismatch: bool vs i64
  [1]

Index-set value must match the element type:
  $ cat >arr_indexset_ty.sy <<EOF
  > let a = [| 1; 2 |]
  > let _ = a.[0] := true
  > EOF
  $ dune exec sylic typing arr_indexset_ty.sy
  Type error in arr_indexset_ty.sy at line 2, column 17
  
    2 | let _ = a.[0] := true
                         ^^^^
  
  type mismatch: bool vs i64
  [1]

Indexing a non-array is a type error:
  $ cat >arr_index_nonarray.sy <<EOF
  > let x = 1
  > let y = x.[0]
  > EOF
  $ dune exec sylic typing arr_index_nonarray.sy
  Type error in arr_index_nonarray.sy at line 2, column 8
  
    2 | let y = x.[0]
                ^
  
  type mismatch: i64 vs '17 array
  [1]

Allocation size must be i64:
  $ cat >arr_alloc_size.sy <<EOF
  > let c = [| true: fun i -> i |]
  > EOF
  $ dune exec sylic typing arr_alloc_size.sy
  Type error in arr_alloc_size.sy at line 1, column 11
  
    1 | let c = [| true: fun i -> i |]
                   ^^^^
  
  type mismatch: bool vs i64
  [1]

Allocation initializer must be a function:
  $ cat >arr_alloc_init.sy <<EOF
  > let c = [| 4: 5 |]
  > EOF
  $ dune exec sylic typing arr_alloc_init.sy
  Type error in arr_alloc_init.sy at line 1, column 14
  
    1 | let c = [| 4: 5 |]
                      ^
  
  type mismatch: i64 vs i64 -> '11
  [1]
