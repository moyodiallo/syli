Ref type inference:
TODO: add parametric polymorphic test when supported.
  $ cat >test_ref.sy <<EOF
  > primitive (+)  : i64 -> i64 -> i64 = "add"
  > type ref = { mutable value: i64 }
  > let ref x = { value = x }
  > let ( ! ) r = r.value
  > let ( := ) r x = r.value := x
  > let a = ref 0
  > let incr r = r := !r + 1
  > let main () = 0
  > EOF
  $ dune exec sylic typing test_ref.sy
  Typed test_ref.sy successfully: module Test_ref with 8 top-level typed items
  Type Environment:
  {
    ! : ref -> i64
    + : i64 -> i64 -> i64
    := : ref -> i64 -> unit
    a : ref
    incr : ref -> unit
    main : unit -> i64
    ref : i64 -> ref
  }
