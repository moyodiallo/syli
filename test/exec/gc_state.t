The GC-state primitive reports how many objects were traced from stackmap
roots versus reclaimed. With the env thresholds set to 0, dropping the cyclic
container tmp leaves the live ref child as a suspect, so a tracing generation
runs and protects the rooted objects (traced == live objects, child survives
with value 42):

  $ cat >gc_state.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  >   extern syli_print_gc_state : unit -> unit = "syli_print_gc_state"
  > end
  > type box = { c : ref int64 }
  > fn main () =
  >   let child = ref 42
  >   let r1 = { c = child }
  >   let r2 = { c = child }
  >   let tmp = { c = child }
  >   let tmp = 0
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
  $ SYLI_GC_RELEASING_THRESHOLD=0 SYLI_GC_SUSPECT_THRESHOLD=0 ./gc_state.exe
  4242427GC[tracing_state=Idle releasing_state=Idle generations=2 suspects=0 notifications=0 traced=3 freed=10 waitlist=0 worklist=0]

Without the env thresholds GC stays dormant (no tracing generations):

  $ ./gc_state.exe
  4242427GC[tracing_state=Idle releasing_state=Idle generations=0 suspects=0 notifications=0 traced=0 freed=6 waitlist=3 worklist=0]

A minimal program: two containers share a ref child, only child is dereferenced
after the GC. The first state print shows GC activity (traced=1, the rooted
child; freed=1, a released container) and the deref still yields 42:

  $ cat >basic.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  >   extern syli_print_gc_state : unit -> unit = "syli_print_gc_state"
  > end
  > type box = { c : ref int64 }
  > fn main () =
  >   let child = ref 42
  >   let r1 = { c = child }
  >   let r2 = { c = child }
  >   syli_print_gc_state ()
  >   syli_print_i64 (*child)
  >   syli_print_gc_state ()
  > EOF
  $ dune exec sylic -- build basic.sy
  $ SYLI_GC_RELEASING_THRESHOLD=0 SYLI_GC_SUSPECT_THRESHOLD=0 ./basic.exe
  GC[tracing_state=Idle releasing_state=Idle generations=1 suspects=1 notifications=0 traced=1 freed=1 waitlist=1 worklist=0]
  42GC[tracing_state=Idle releasing_state=Idle generations=1 suspects=1 notifications=0 traced=1 freed=1 waitlist=1 worklist=0]

  $ ./basic.exe
  GC[tracing_state=Idle releasing_state=Idle generations=0 suspects=0 notifications=0 traced=0 freed=0 waitlist=2 worklist=0]
  42GC[tracing_state=Idle releasing_state=Idle generations=0 suspects=0 notifications=0 traced=0 freed=0 waitlist=2 worklist=0]

Shadowing a binding releases the old container, driving two tracing
generations; the still-rooted child is traced and freed objects accumulate:

  $ cat >shadow.sy <<EOF
  > signature:
  >   extern syli_print_gc_state : unit -> unit = "syli_print_gc_state"
  > end
  > type box = { c : ref int64 }
  > fn main () =
  >   let child = ref 42
  >   let r1 = { c = child }
  >   let r2 = { c = child }
  >   let tmp = { c = child }
  >   let tmp = 0
  >   let keep = ref 7
  >   syli_print_gc_state ()
  >   let keep2 = ref 8
  >   syli_print_gc_state ()
  > EOF
  $ dune exec sylic -- build shadow.sy
  $ SYLI_GC_RELEASING_THRESHOLD=0 SYLI_GC_SUSPECT_THRESHOLD=0 ./shadow.exe
  GC[tracing_state=Idle releasing_state=Idle generations=2 suspects=0 notifications=0 traced=2 freed=5 waitlist=0 worklist=0]
  GC[tracing_state=Idle releasing_state=Idle generations=2 suspects=0 notifications=0 traced=2 freed=6 waitlist=0 worklist=0]

  $ ./shadow.exe
  GC[tracing_state=Idle releasing_state=Idle generations=0 suspects=0 notifications=0 traced=0 freed=1 waitlist=3 worklist=0]
  GC[tracing_state=Idle releasing_state=Idle generations=0 suspects=0 notifications=0 traced=0 freed=2 waitlist=3 worklist=0]
