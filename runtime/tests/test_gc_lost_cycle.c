#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>

#include "syli/gc_helpers.h"
#include "syli/header_object.h"
#include "syli/object.h"
#include "syli/syli.h"
#include "syli/syli_state.h"

#pragma GCC diagnostic ignored "-Wunused-parameter"

// A Cons-like object: one reference field (index 0) and one immediate field
// (index 1). The header carries the mutable-cyclic bit, so it enters the
// candidate registry at creation.
static obj_ptr make_cons(obj_ptr tail)
{
    object_payload_t payload = syli_object_make_bitmap_payload(2, 0x1);
    object_header_t header   = syli_object_make_header(
        Zone_GcLocal, Cyclic, Type_MixedBitmap, Flag_HasPointers, payload);
    header |= GC_CYCLIC_MUTABLE_MASK;
    obj_ptr obj    = syli_rt_ownership_alloc_object(header, 1, 2);
    Object* o      = syli_object_of_obj_ptr(obj);
    uint64_t* data = syli_object_data(o);
    data[0]        = (uint64_t)tail;
    data[1]        = 42;
    return obj;
}

static void set_tail(obj_ptr cell, obj_ptr tail)
{
    syli_object_data(syli_object_of_obj_ptr(cell))[0] = (uint64_t)tail;
}

// Same layout as make_cons but allocated through the plain entrypoint, so it is
// never registered as a mutable-cyclic candidate.
static obj_ptr make_plain_cons(obj_ptr tail)
{
    object_payload_t payload = syli_object_make_bitmap_payload(2, 0x1);
    object_header_t header   = syli_object_make_header(
        Zone_GcLocal, Cyclic, Type_MixedBitmap, Flag_HasPointers, payload);
    obj_ptr obj    = syli_rt_ownership_alloc_object(header, 1, 2);
    Object* o      = syli_object_of_obj_ptr(obj);
    uint64_t* data = syli_object_data(o);
    data[0]        = (uint64_t)tail;
    data[1]        = 42;
    return obj;
}

// An object with two reference fields (index 0 and 1).
static obj_ptr make_two_refs(obj_ptr a, obj_ptr b)
{
    object_payload_t payload = syli_object_make_bitmap_payload(2, 0x3);
    object_header_t header   = syli_object_make_header(
        Zone_GcLocal, Cyclic, Type_MixedBitmap, Flag_HasPointers, payload);
    header |= GC_CYCLIC_MUTABLE_MASK;
    obj_ptr obj    = syli_rt_ownership_alloc_object(header, 1, 2);
    Object* o      = syli_object_of_obj_ptr(obj);
    uint64_t* data = syli_object_data(o);
    data[0]        = (uint64_t)a;
    data[1]        = (uint64_t)b;
    return obj;
}

static void set_field(obj_ptr cell, size_t index, obj_ptr value)
{
    syli_object_data(syli_object_of_obj_ptr(cell))[index] = (uint64_t)value;
}

static bool lost_cycle_drained(void)
{
    return vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 0
        && vector_size_obj_ptr(&syli_state.lost_cycle_worklist) == 0
        && syli_state.tracing_state == Tracing_Idle;
}

static bool candidates_empty_and_releasing_drained(void)
{
    return vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 0
        && vector_size_obj_ptr(&syli_state.lost_cycle_worklist) == 0
        && vector_size_obj_ptr(&syli_state.releasing_waitlist) == 0
        && vector_size_obj_ptr(&syli_state.releasing_worklist) == 0;
}

static void run_gc_until(bool (*done)(void), size_t max_cycles)
{
    size_t cycles = 0;
    while (!done()) {
        syli_state_gc_cycle();
        cycles++;
        assert(cycles <= max_cycles);
    }
}

static void configure(void)
{
    syli_state.THRESHOLD_RELEASING_BUCKET  = 1;
    syli_state.THRESHOLD_MEM_CYCLIC_OBJ    = 0;
    syli_state.THRESHOLD_CANDIDATES_RATIO  = 0.0;
    syli_state.BUDGET_GC_RELEASING         = 1024;
    syli_state.BUDGET_GC_TRACING           = 1024;
    syli_state.BUDGET_GC_CHECKING          = 1024;
}

static void test_two_cycle(void)
{
    printf("Test 1: unreachable two-cycle of mixed-bitmap objects\n");

    syli_state_init();
    configure();

    obj_ptr a = make_cons(NULL);
    obj_ptr b = make_cons(a);
    syli_rt_object_incr(syli_object_of_obj_ptr(a)); // a <- b
    set_tail(a, b);                                 // a -> b
    syli_rt_object_incr(syli_object_of_obj_ptr(b)); // b <- a

    // Drop the external references: only the cycle keeps them alive.
    syli_rt_ownership_decr(a);
    syli_rt_ownership_decr(b);

    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 2);

    run_gc_until(lost_cycle_drained, 256);

    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 0);
    assert(syli_state.total_objects_memory_freed == 2);

    syli_state_destroy();

    printf("✓ two-cycle reclaimed (freed == 2)\n\n");
}

static void test_multiply_referenced_cycle(void)
{
    printf("Test 2: unreachable cycle with a multiply-referenced node\n");

    syli_state_init();
    configure();

    obj_ptr a = make_two_refs(NULL, NULL);
    obj_ptr b = make_cons(a); // b -> a
    set_field(a, 0, b);       // a -> b
    set_field(a, 1, b);       // a -> b (again)

    syli_rt_object_incr(syli_object_of_obj_ptr(a)); // a <- b
    syli_rt_object_incr(syli_object_of_obj_ptr(b)); // b <- a (first)
    syli_rt_object_incr(syli_object_of_obj_ptr(b)); // b <- a (second)

    syli_rt_ownership_decr(a);
    syli_rt_ownership_decr(b);

    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 2);

    run_gc_until(lost_cycle_drained, 256);

    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 0);
    assert(syli_state.total_objects_memory_freed == 2);

    syli_state_destroy();

    printf("✓ multiply-referenced cycle reclaimed (freed == 2)\n\n");
}

static void test_three_cycle(void)
{
    printf("Test 3: unreachable three-cycle of mixed-bitmap objects\n");

    syli_state_init();
    configure();

    obj_ptr a = make_cons(NULL);
    obj_ptr b = make_cons(a); // b -> a
    obj_ptr c = make_cons(b); // c -> b
    set_tail(a, c);           // a -> c

    syli_rt_object_incr(syli_object_of_obj_ptr(a)); // a <- b
    syli_rt_object_incr(syli_object_of_obj_ptr(b)); // b <- c
    syli_rt_object_incr(syli_object_of_obj_ptr(c)); // c <- a

    syli_rt_ownership_decr(a);
    syli_rt_ownership_decr(b);
    syli_rt_ownership_decr(c);

    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 3);

    run_gc_until(lost_cycle_drained, 256);

    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 0);
    assert(syli_state.total_objects_memory_freed == 3);

    syli_state_destroy();

    printf("✓ three-cycle reclaimed (freed == 3)\n\n");
}

// A registered candidate that reaches refcount 0 during normal execution is
// not a lost cycle: it must leave the candidate registry and be released by the
// simple ARC path, children included.
static void test_zero_refcount_candidate_arc_released(void)
{
    printf("Test 4: cyclic candidate reaching rc=0 is ARC-released\n");

    syli_state_init();
    configure();

    obj_ptr b = make_cons(NULL); // b registered
    obj_ptr a = make_cons(b);    // a registered, a -> b
    syli_rt_object_incr(syli_object_of_obj_ptr(b)); // b <- a

    // Drop the external references. `b` stays at refcount 1 (from `a`); `a`
    // reaches 0 and must leave the candidates before the ARC queue owns it.
    syli_rt_ownership_decr(b);
    syli_rt_ownership_decr(a);

    assert(syli_object_refcount(syli_object_of_obj_ptr(a)) == 0);
    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 1); // only b
    assert(vector_size_obj_ptr(&syli_state.releasing_waitlist) == 1);   // a

    run_gc_until(candidates_empty_and_releasing_drained, 256);

    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 0);
    assert(syli_state.total_objects_memory_freed == 2);

    syli_state_destroy();

    printf("✓ zero-refcount candidate released by ARC (freed == 2)\n\n");
}

// A lost cycle can point at an unmarked child that is still referenced by
// another unmarked object (rc > 0) and is not itself a registered candidate.
// The cascade must route it, otherwise it and its peers leak.
//   a <-> b (registered), a -> c, c <-> d (c registered, d plain)
static void test_unmarked_child_with_refs(void)
{
    printf("Test 5: unmarked child with rc>0 is collected\n");

    syli_state_init();
    configure();

    obj_ptr a = make_two_refs(NULL, NULL); // registered
    obj_ptr b = make_cons(a);              // registered, b -> a
    obj_ptr c = make_cons(NULL);           // registered, c -> d
    obj_ptr d = make_plain_cons(c);        // not registered, d -> c

    set_field(a, 0, b); // a -> b
    set_field(a, 1, c); // a -> c
    set_tail(c, d);     // c -> d

    syli_rt_object_incr(syli_object_of_obj_ptr(a)); // a <- b
    syli_rt_object_incr(syli_object_of_obj_ptr(b)); // b <- a
    syli_rt_object_incr(syli_object_of_obj_ptr(c)); // c <- a
    syli_rt_object_incr(syli_object_of_obj_ptr(d)); // d <- c
    syli_rt_object_incr(syli_object_of_obj_ptr(c)); // c <- d

    // Drop the external references. a=1, b=1, c=2, d=1; all unreachable.
    syli_rt_ownership_decr(a);
    syli_rt_ownership_decr(b);
    syli_rt_ownership_decr(c);
    syli_rt_ownership_decr(d);

    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 3);

    run_gc_until(lost_cycle_drained, 256);

    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 0);
    assert(syli_state.total_objects_memory_freed == 4);

    syli_state_destroy();

    printf("✓ unmarked child with rc>0 collected (freed == 4)\n\n");
}

int main(void)
{
    printf("\033[1;34m=== Lost-Cycle Collection Tests ===\033[0m\n\n");

    test_two_cycle();
    test_multiply_referenced_cycle();
    test_three_cycle();
    test_zero_refcount_candidate_arc_released();
    test_unmarked_child_with_refs();

    printf("\033[1;32m=== All Lost-Cycle Tests Passed! ===\033[0m\n\n");
    return 0;
}
