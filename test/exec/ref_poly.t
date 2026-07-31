Store a named polymorphic function in a ref and use it:
  $ cat >test_ref.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  > end
  > fn id x = x
  > fn main () =
  >   let f = ref id
  >   let g = *f
  >   syli_print_i64(g 21)
  > EOF
  $ dune exec sylic -- oir test_ref.sy
  Fatal error: exception Failure("Cir.CR_GenericTyp should be monomorphized before lowering to OIR")
  ***** UNREACHABLE *****
  $ dune exec sylic -- build test_ref.sy
  ***** UNREACHABLE *****
