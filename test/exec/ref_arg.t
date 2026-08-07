Passing a ref as a function argument whose body stores it into a record field
must promote the borrowed argument to an owned copy. This used to crash in the
inlined ownership `own` helper (`syli_rt_ownership_incr` asserted the pointer
was own-tagged). child keeps value 42 after the GC runs:

  $ cat >ref_arg.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  >   extern syli_print_gc_state : unit -> unit = "syli_print_gc_state"
  > end
  > type box = { c : ref int64 }
  > fn trigger (live : ref int64) =
  >   let tmp = { c = live }
  >   0
  > fn main () =
  >   let child = ref 42
  >   let r1 = { c = child }
  >   let r2 = { c = child }
  >   trigger child
  >   let keep = ref 7
  >   syli_print_i64 (*child)
  >   syli_print_i64 (*keep)
  >   syli_print_gc_state ()
  > EOF
  $ dune exec sylic -- build ref_arg.sy
  $ SYLI_GC_RELEASING_THRESHOLD=0 SYLI_GC_SUSPECT_THRESHOLD=0 ./ref_arg.exe
  427GC[tracing_state=Idle releasing_state=Idle generations=3 suspects=1 notifications=0 traced=3 freed=5 waitlist=0 worklist=0]

Without the env thresholds GC stays dormant:

  $ ./ref_arg.exe
  427GC[tracing_state=Idle releasing_state=Idle generations=0 suspects=0 notifications=0 traced=0 freed=1 waitlist=3 worklist=0]
