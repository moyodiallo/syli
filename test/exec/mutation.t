A mutable record field assignment emits the mutation-notification write
barrier (syli_rt_ownership_notify_mutation) after the reference store and runs
correctly through the full pipeline:

  $ cat >mutation.sy <<EOF
  > signature:
  >   extern syli_print_i64 : int64 -> unit = "syli_print_i64"
  >   extern syli_print_gc_state : unit -> unit = "syli_print_gc_state"
  > end
  > type box = { mutable next : ref int64 }
  > fn main () =
  >   let child = ref 42
  >   let b = { next = child }
  >   b.next = ref 7
  >   let c = b.next
  >   let n = *c
  >   syli_print_i64 n
  >   syli_print_gc_state ()
  > EOF
  $ dune exec sylic -- build mutation.sy
  $ SYLI_GC_RELEASING_THRESHOLD=0 SYLI_GC_SUSPECT_THRESHOLD=0 ./mutation.exe
  7GC[tracing_state=Idle releasing_state=Idle generations=0 suspects=0 notifications=0 traced=0 freed=1 waitlist=1 worklist=0]
  $ ./mutation.exe
  7GC[tracing_state=Idle releasing_state=Idle generations=0 suspects=0 notifications=0 traced=0 freed=1 waitlist=1 worklist=0]
