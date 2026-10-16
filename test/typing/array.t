Array typing: literal infers element type, index get/set, allocation:
  $ cat >arr.sy <<EOF
  > primitive (#index_get) : 'a array -> i64 -> 'a = "array_index_get"
  > primitive (#index_set) : 'a array -> i64 -> 'a -> unit = "array_index_set"
  > let a = [| 1; 2; 3 |]
  > let b = a.[0]
  > let _ = a.[1] := 42
  > let c = [| 4: fun i -> i |]
  > EOF
  $ dune exec sylic typing arr.sy
  Typed arr.sy successfully: module Arr with 6 top-level typed items
  Type Environment:
  {
    (#index_get) : forall '64. '64 array -> i64 -> '64
    (#index_set) : forall '65. '65 array -> i64 -> '65 -> unit
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
  > primitive (#index_get) : 'a array -> i64 -> 'a = "array_index_get"
  > let a = [| 1; 2 |]
  > let b = a.[true]
  > EOF
  $ dune exec sylic typing arr_index_ty.sy
  Type error in arr_index_ty.sy at line 3, column 11
  
    3 | let b = a.[true]
                   ^^^^
  
  type mismatch: i64 vs bool
  [1]

Index-set value must match the element type:
  $ cat >arr_indexset_ty.sy <<EOF
  > primitive (#index_set) : 'a array -> i64 -> 'a -> unit = "array_index_set"
  > let a = [| 1; 2 |]
  > let _ = a.[0] := true
  > EOF
  $ dune exec sylic typing arr_indexset_ty.sy
  Type error in arr_indexset_ty.sy at line 3, column 17
  
    3 | let _ = a.[0] := true
                         ^^^^
  
  type mismatch: i64 vs bool
  [1]

Indexing a non-array is a type error:
  $ cat >arr_index_nonarray.sy <<EOF
  > primitive (#index_get) : 'a array -> i64 -> 'a = "array_index_get"
  > let x = 1
  > let y = x.[0]
  > EOF
  $ dune exec sylic typing arr_index_nonarray.sy
  Type error in arr_index_nonarray.sy at line 3, column 8
  
    3 | let y = x.[0]
                ^
  
  type mismatch: '28 array vs i64
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
