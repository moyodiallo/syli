Variant constructor lowering — build and run.

Mixed variant: a constant constructor is a `11` immediate, payload is a heap object:
  $ cat >test_ctor_option.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type option = None | Some of i64
  > let value_of a = match a with Some v -> v | None -> 42
  > let main () =
  >   let a = Some 3
  >   let b = None
  >   syli_print_i64 (value_of a)
  >   syli_print_i64 (value_of b)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_ctor_option.sy
  $ ./test_ctor_option.exe
  342

A named record payload is a single reference field:
  $ cat >test_ctor_record.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type radius = { radius: i64 }
  > type dims = { w: i64; h: i64 }
  > type shape = Circle of radius | Rect of dims
  > let area s = match s with Circle r -> r.radius | Rect d -> d.w
  > let main () =
  >   syli_print_i64 (area (Circle { radius = 5 }))
  >   syli_print_i64 (area (Rect { w = 7; h = 8 }))
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_ctor_record.sy
  $ ./test_ctor_record.exe
  57

An anonymous record payload is matched with an explicit record pattern:
  $ cat >test_ctor_anonrec_pat.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type shape = Rect of { w: i64; h: i64 }
  > let area s = match s with Rect { w = w; h = h } -> w
  > let main () =
  >   syli_print_i64 (area (Rect { w = 7; h = 8 }))
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_ctor_anonrec_pat.sy
  $ ./test_ctor_anonrec_pat.exe
  7

An anonymous tuple payload is flattened into the constructor block:
  $ cat >test_ctor_tuple.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type t = P of (i64, i64)
  > let first x = match x with P (a, b) -> a
  > let main () =
  >   syli_print_i64 (first (P (1, 2)))
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_ctor_tuple.sy
  $ ./test_ctor_tuple.exe
  1

A tuple payload passed as a value is projected into the block:
  $ cat >test_ctor_proj.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type t = P of (i64, i64)
  > let mk (v: (i64, i64)) = P v
  > let first x = match x with P (a, b) -> a
  > let main () =
  >   syli_print_i64 (first (mk (1, 2)))
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_ctor_proj.sy
  $ ./test_ctor_proj.exe
  1

Nested variants:
  $ cat >test_ctor_nested.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > type opt = None | Some of i64
  > type wrapper = Wrap of opt | Nil
  > let get w = match w with Wrap (Some v) -> v | Wrap None -> 0 | Nil -> 42
  > let main () =
  >   syli_print_i64 (get (Wrap (Some 7)))
  >   syli_print_i64 (get (Wrap None))
  >   syli_print_i64 (get Nil)
  > let _ = main ()
  > EOF
  $ dune exec sylic -- build test_ctor_nested.sy
  $ ./test_ctor_nested.exe
  7042
