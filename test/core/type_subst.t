Type name resolution across module boundaries:

  $ cat >type_subst.sy <<EOF
  > type person = { name: i64; age: i64 }
  > structure A
  >     let make () = { name = 1; age = 2 }
  > EOF
  $ dune exec sylic -- core type_subst.sy
  module Type_subst
  type syliType_subst.person = { 0 : i64; 1 : i64 }
  
  let syliType_subst.A.make = fun () : syliType_subst.person ->
      { 0 = 1 : i64; 1 = 2 : i64 } : syliType_subst.person
  

A type declared inside a module stays scoped to that module:

  $ cat >type_subst_scope.sy <<EOF
  > structure B
  >     type point = { x: i64; y: i64 }
  >     let origin () = { x = 0; y = 0 }
  > EOF
  $ dune exec sylic -- core type_subst_scope.sy
  module Type_subst_scope
  type syliType_subst_scope.B.point = { 0 : i64; 1 : i64 }
  
  let syliType_subst_scope.B.origin = fun () : syliType_subst_scope.B.point ->
      { 0 = 0 : i64; 1 = 0 : i64 } : syliType_subst_scope.B.point
  
