Self describing signature parsing tests 
  $ cat >parse0.sy <<EOF
  > signature Sig_ex
  >   val add : int -> int
  > end
  > let x = 10
  > EOF
  $ cat parse0.sy
  signature Sig_ex
    val add : int -> int
  end
  let x = 10

  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  module Sig_ex
  let x = 10

Signature parsing with foreignal declarations
  $ cat >parse0.sy <<EOF
  > signature Sig_ex
  >   val add : int -> int
  >   foreign print_int : int -> unit = "print_int"
  > end
  > let x = 10
  > EOF
  $ cat parse0.sy
  signature Sig_ex
    val add : int -> int
    foreign print_int : int -> unit = "print_int"
  end
  let x = 10

  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  module Sig_ex
  let x = 10

Structure parsing with foreignal declarations
  $ cat >parse0.sy <<EOF
  > foreign print_int : int -> unit = "print_int"
  > let x = 10
  > EOF
  $ cat parse0.sy
  foreign print_int : int -> unit = "print_int"
  let x = 10
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  extern print_int : int -> unit
  let x = 10

Structure parsing with primitive declarations
  $ cat >parse0.sy <<EOF
  > primitive add_i64 : i64 -> i64 -> i64 = "add"
  > let x = 10
  > EOF
  $ cat parse0.sy
  primitive add_i64 : i64 -> i64 -> i64 = "add"
  let x = 10
  $ dune exec sylic parse parse0.sy
  Parsed parse0.sy
  extern add_i64 : int64 -> int64 -> int64
  let x = 10

Failing, primitive declaration that mismatches the type
  $ cat >parse0.sy <<EOF
  > primitive add_i64 : i64 -> i64 = "add"
  > let x = 10
  > EOF
  $ cat parse0.sy
  primitive add_i64 : i64 -> i64 = "add"
  let x = 10
  $ dune exec sylic parse parse0.sy
  Unexpected error: Failure("Primitive 'add' does not have instance of type 'int64 -> int64',")
  [1]

Failing primitive declaration that does not exist.
  $ cat >parse0.sy <<EOF
  > primitive add_i64 : i64 -> i64 = "ghost_primitive"
  > let x = 10
  > EOF
  $ cat parse0.sy
  primitive add_i64 : i64 -> i64 = "ghost_primitive"
  let x = 10
  $ dune exec sylic parse parse0.sy
  Unexpected error: Failure("Primitive ghost_primitive is unknown.")
  [1]
