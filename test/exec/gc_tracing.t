We are showing here that the tracing is working.
With this simple example we need to reduce the thresholds:
SYLI_GC_RELEASING_THRESHOLD=0 SYLI_GC_SUSPECT_THRESHOLD=0
  $ cat >gc_state.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > foreign syli_print_gc_state : unit -> unit = "syli_print_gc_state"
  > type box = { c : i64 ref }
  > let main () =
  >   let child = ref 42
  >   let r1 = { c = child }
  >   let r2 = { c = child }
  >   let tmp = { c = child }
  >   let keep = ref 7
  >   let c1 = r1.c
  >   let c2 = r2.c
  >   let k1 = *keep
  >   let v = *child
  >   syli_print_i64 (*c1)
  >   syli_print_i64 (*c2)
  >   syli_print_i64 (v)
  >   syli_print_i64 (k1)
  >   let flush1 = ref 1
  >   let flush2 = ref 2
  >   let flush3 = ref 3
  >   let flush4 = ref 4
  >   let flush5 = ref 5
  >   syli_print_gc_state ()
  > EOF
  $ dune exec sylic -- build gc_state.sy
  
  Parse error in gc_state.sy at line 3, column 21
  
    3 | type box = { c : i64 ref }
                              ^^^^^^^^^^
  
  Unexpected token: 'IDENT(ref)'
  
  ***** UNREACHABLE *****
  $ SYLI_GC_RELEASING_THRESHOLD=0 SYLI_GC_SUSPECT_THRESHOLD=0 ./gc_state.exe
  ***** UNREACHABLE *****

Without the reducing the treshold, no tracing for this simple example:
  $ ./gc_state.exe
  ***** UNREACHABLE *****

It shows even with this simple example object is still be freed.
And tracing also still works.
  $ cat >basic.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > foreign syli_print_gc_state : unit -> unit = "syli_print_gc_state"
  > type box = { c : ref i64 }
  > let main () =
  >   let child = ref 42
  >   let r1 = { c = child }
  >   let r2 = { c = child }
  >   syli_print_gc_state ()
  >   syli_print_i64 (*child)
  >   syli_print_gc_state ()
  > EOF
  ***** UNREACHABLE *****
  $ dune exec sylic -- build basic.sy
  ***** UNREACHABLE *****
  $ SYLI_GC_RELEASING_THRESHOLD=0 SYLI_GC_SUSPECT_THRESHOLD=0 ./basic.exe
  ***** UNREACHABLE *****

  $ ./basic.exe
  ***** UNREACHABLE *****
