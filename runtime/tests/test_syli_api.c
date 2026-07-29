#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "syli/config.h"
#include "syli/gc_helpers.h"
#include "syli/syli.h"
#include "syli/syli_state.h"

#pragma GCC diagnostic ignored "-Wunused-but-set-variable"

/* ============================================================
 * Helper: create a simple GC-local object using syli_rt_rc_alloc_object
 * ============================================================ */

static Object* make_object(ObjectZone zone, CyclicFlag cyclic, ObjectType type,
    ObjectImmutableFlag imm_flags, size_t words)
{
    object_payload_t payload;
    switch (type) {
    case Type_MonoImm:
    case Type_MonoRef:
        payload = syli_object_make_mono_payload(words);
        break;
    case Type_MixedOrder:
        payload = syli_object_make_order_payload(words, 0);
        break;
    case Type_MixedBitmap:
        payload = syli_object_make_bitmap_payload(words, 0);
        break;
    default:
        return NULL;
    }

    object_header_t header
        = syli_object_make_header(zone, cyclic, type, imm_flags, payload);
    return (Object*)syli_rt_rc_alloc_object(header, 1, words);
}

/* ============================================================
 * Test: syli_rt_rc_alloc_object
 * ============================================================ */

static void test_rt_rc_alloc_object(void)
{
    printf("Test 1: syli_rt_rc_alloc_object()\n");

    syli_state_init();

    /* Allocate a mono-imm acyclic object (1 word) */
    Object* obj
        = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, 1);
    assert(obj != NULL);
    assert(syli_object_get_zone(obj) == Zone_GcLocal);
    assert(syli_object_is_acyclic(obj));
    assert(syli_object_is_mono_imm(obj));
    assert(syli_object_mono_length(obj) == 1);
    assert(syli_object_refcount(obj) == 1);
    free(obj);

    /* Allocate a mono-ref cyclic object (3 words) */
    Object* cyclic
        = make_object(Zone_GcLocal, Cyclic, Type_MonoRef, Flag_HasPointers, 3);
    assert(cyclic != NULL);
    assert(syli_object_get_zone(cyclic) == Zone_GcLocal);
    assert(syli_object_is_cyclic(cyclic));
    assert(syli_object_is_mono_ref(cyclic));
    assert(syli_object_has_pointers(cyclic));
    assert(syli_object_mono_length(cyclic) == 3);
    assert(syli_object_refcount(cyclic) == 1);
    free(cyclic);

    /* Allocate a mixed-order object */
    object_payload_t order_payload = syli_object_make_order_payload(2, 1);
    object_header_t order_header   = syli_object_make_header(Zone_GcLocal,
        Acyclic, Type_MixedOrder, Flag_HasPointers, order_payload);
    Object* mixed = (Object*)syli_rt_rc_alloc_object(order_header, 5, 3);
    assert(mixed != NULL);
    assert(syli_object_is_mixed_order(mixed));
    assert(syli_object_refcount(mixed) == 5);
    free(mixed);

    /* Allocate a mixed-bitmap object */
    object_payload_t bitmap_payload = syli_object_make_bitmap_payload(4, 0b101);
    object_header_t bitmap_header   = syli_object_make_header(
        Zone_GcLocal, Acyclic, Type_MixedBitmap, Flag_None, bitmap_payload);
    Object* bitmap = (Object*)syli_rt_rc_alloc_object(bitmap_header, 1, 4);
    assert(bitmap != NULL);
    assert(syli_object_is_mixed_bitmap(bitmap));
    assert(syli_object_refcount(bitmap) == 1);
    assert(syli_object_bitmap_length(bitmap) == 4);
    free(bitmap);

    syli_state_destroy();
    printf("✓ syli_rt_rc_alloc_object works with all object types\n\n");
}

/* ============================================================
 * Test: syli_rt_object_incr and syli_rt_object_decr
 * ============================================================ */

static void test_rt_object_incr_decr(void)
{
    printf("Test 2: syli_rt_object_incr() / syli_rt_object_decr()\n");

    syli_state_init();

    /* Test on a local GC object */
    Object* obj
        = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, 0);
    assert(obj != NULL);
    assert(syli_object_refcount(obj) == 1);

    syli_rt_object_incr(obj);
    assert(syli_object_refcount(obj) == 2);

    syli_rt_object_incr(obj);
    assert(syli_object_refcount(obj) == 3);

    syli_rt_object_decr(obj);
    assert(syli_object_refcount(obj) == 2);

    syli_rt_object_decr(obj);
    assert(syli_object_refcount(obj) == 1);

    /* Acquire/release on a static object should be a no-op */
    Object static_obj;
    static_obj.header_word = syli_object_make_header(
        Zone_Static, Acyclic, Type_MonoImm, Flag_None, 0);

    uint64_t before_header = static_obj.header_word;
    syli_rt_object_incr(&static_obj);
    assert(static_obj.header_word == before_header);

    syli_rt_object_decr(&static_obj);
    assert(static_obj.header_word == before_header);

    free(obj);
    syli_state_destroy();
    printf("✓ Acquire/release work correctly on GC and static objects\n\n");
}

/* ============================================================
 * Test: syli_rt_object_decr_n
 * ============================================================ */

static void test_rt_object_decr_n(void)
{
    printf("Test 3: syli_rt_object_decr_n()\n");

    syli_state_init();

    Object* obj
        = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, 0);
    assert(obj != NULL);
    assert(syli_object_refcount(obj) == 1);

    /* Increase refcount to 5 */
    syli_rt_object_incr(obj);
    syli_rt_object_incr(obj);
    syli_rt_object_incr(obj);
    syli_rt_object_incr(obj);
    assert(syli_object_refcount(obj) == 5);

    /* Release by 3 */
    syli_rt_object_decr_n(obj, 3);
    assert(syli_object_refcount(obj) == 2);

    /* Release by 2 */
    syli_rt_object_decr_n(obj, 2);
    assert(syli_object_refcount(obj) == 0);

    /* Release_n on static object should be a no-op */
    Object static_obj;
    static_obj.header_word = syli_object_make_header(
        Zone_Static, Acyclic, Type_MonoImm, Flag_None, 0);
    uint64_t before_header = static_obj.header_word;
    syli_rt_object_decr_n(&static_obj, 5);
    assert(static_obj.header_word == before_header);

    free(obj);
    syli_state_destroy();
    printf("✓ syli_rt_object_decr_n decrements by the correct amount\n\n");
}

/* ============================================================
 * Test: syli_rt_object_check_release
 * ============================================================ */

static void test_rt_object_check_release(void)
{
    printf("Test 4: syli_rt_object_check_release()\n");

    syli_state_init();

    Object* obj
        = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, 0);
    assert(obj != NULL);

    /* Refcount is 1, check_release should NOT add to releasing_waitlist */
    assert(vector_size_GCObject(&syli_state.releasing_waitlist) == 0);
    syli_rt_object_check_release(obj);
    assert(vector_size_GCObject(&syli_state.releasing_waitlist) == 0);

    /* Release to refcount 0 */
    syli_rt_object_decr(obj);
    assert(syli_object_refcount(obj) == 0);

    /* Now check_release SHOULD add to releasing_waitlist */
    syli_rt_object_check_release(obj);
    assert(vector_size_GCObject(&syli_state.releasing_waitlist) == 1);

    /* Verify the object was added to the waitlist, then pop it back */
    {
        Object** back
            = (Object**)vector_back_GCObject(&syli_state.releasing_waitlist);
        assert(*back == obj);
        vector_pop_back_GCObject(&syli_state.releasing_waitlist);
        assert(vector_size_GCObject(&syli_state.releasing_waitlist) == 0);
    }

    /* check_release on static object should be a no-op */
    {
        Object static_obj;
        static_obj.header_word = syli_object_make_header(
            Zone_Static, Acyclic, Type_MonoImm, Flag_None, 0);
        syli_rt_object_check_release(&static_obj);
        assert(vector_size_GCObject(&syli_state.releasing_waitlist) == 0);
    }

    free(obj);
    syli_state_destroy();
    printf("✓ syli_rt_object_check_release correctly enqueues at refcount "
           "0\n\n");
}

/* ============================================================
 * Test: syli_rt_object_check_lost_cyclic_release
 * ============================================================ */

static void test_rt_object_check_lost_cyclic_release(void)
{
    printf("Test 6: syli_rt_object_check_lost_cyclic_release()\n");

    syli_state_init();

    Object* obj
        = make_object(Zone_GcLocal, Cyclic, Type_MonoRef, Flag_HasPointers, 1);
    assert(obj != NULL);
    assert(syli_object_refcount(obj) == 1);

    /* With refcount > 0, suspect should add to suspect_lost_cycle */
    assert(vector_size_Suspected(&syli_state.suspect_lost_cycle) == 0);
    syli_rt_object_check_lost_cyclic_release(obj);
    assert(vector_size_Suspected(&syli_state.suspect_lost_cycle) == 1);

    /* Verify the suspect's obj pointer matches */
    {
        Suspected* suspect
            = vector_at_Suspected(&syli_state.suspect_lost_cycle, 0);
        assert((Object*)suspect->obj == obj);
    }

    /* Calling suspect again should still have size 1 (flags already set) */
    syli_rt_object_check_lost_cyclic_release(obj);
    assert(vector_size_Suspected(&syli_state.suspect_lost_cycle) == 1);

    /* Reset: clear flags and clean up suspect list */
    syli_object_clear_flags(obj, Meta_Flags_Suspect_Lost_Cycle);
    vector_pop_back_Suspected(&syli_state.suspect_lost_cycle);
    assert(vector_size_Suspected(&syli_state.suspect_lost_cycle) == 0);

    /* With refcount == 0, suspect should NOT add */
    syli_rt_object_decr(obj);
    assert(syli_object_refcount(obj) == 0);

    syli_rt_object_check_lost_cyclic_release(obj);
    assert(vector_size_Suspected(&syli_state.suspect_lost_cycle) == 0);

    /* Static objects should not be affected */
    {
        Object static_obj;
        static_obj.header_word = syli_object_make_header(
            Zone_Static, Acyclic, Type_MonoImm, Flag_None, 0);
        syli_rt_object_check_lost_cyclic_release(&static_obj);
        assert(vector_size_Suspected(&syli_state.suspect_lost_cycle) == 0);
    }

    free(obj);
    syli_state_destroy();
    printf(
        "✓ syli_rt_object_check_lost_cyclic_release correctly manages suspects\n\n");
}

/* ============================================================
 * Test: syli_rt_get_object_tag
 * ============================================================ */

static void test_rt_get_object_tag(void)
{
    printf("Test 7: syli_rt_get_object_tag()\n");

    syli_state_init();

    /* Create an object with variant flags set in header */
    uint64_t variant_bits  = (uint64_t)0xAB << 48;
    object_header_t header = syli_object_make_header(Zone_GcLocal, Acyclic,
        Type_MonoImm, Flag_None, syli_object_make_mono_payload(0));
    header |= variant_bits;

    Object* obj = (Object*)syli_rt_rc_alloc_object(header, 1, 0);
    assert(obj != NULL);

    uint64_t tag = syli_rt_get_object_tag(obj);
    assert(tag == variant_bits);

    /* Object without variant flags */
    object_header_t header_no_variant
        = syli_object_make_header(Zone_GcLocal, Acyclic, Type_MonoRef,
            Flag_HasPointers, syli_object_make_mono_payload(0));
    Object* no_variant
        = (Object*)syli_rt_rc_alloc_object(header_no_variant, 1, 0);
    assert(no_variant != NULL);

    uint64_t tag_no_variant = syli_rt_get_object_tag(no_variant);
    assert(tag_no_variant == 0);

    free(obj);
    free(no_variant);
    syli_state_destroy();
    printf("✓ syli_rt_get_object_tag returns correct variant tag\n\n");
}

/* ============================================================
 * Test: syli_rt_get_object_length
 * ============================================================ */

static void test_rt_get_object_length(void)
{
    printf("Test 8: syli_rt_get_object_length()\n");

    syli_state_init();

    /* Mono object with length 5 */
    {
        Object* mono
            = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, 5);
        assert(mono != NULL);
        assert(syli_rt_get_object_length(mono) == 5);
        free(mono);
    }

    /* Mono-ref object with length 10 */
    {
        Object* mono_ref = make_object(
            Zone_GcLocal, Acyclic, Type_MonoRef, Flag_HasPointers, 10);
        assert(mono_ref != NULL);
        assert(syli_rt_get_object_length(mono_ref) == 10);
        free(mono_ref);
    }

    /* Mixed-order object: ptr_count=3, imm_count=2 => length=5 */
    {
        object_payload_t order_payload = syli_object_make_order_payload(3, 2);
        object_header_t order_header   = syli_object_make_header(Zone_GcLocal,
            Acyclic, Type_MixedOrder, Flag_HasPointers, order_payload);
        Object* mixed = (Object*)syli_rt_rc_alloc_object(order_header, 1, 5);
        assert(mixed != NULL);
        assert(syli_rt_get_object_length(mixed) == 5);
        free(mixed);
    }

    /* Mixed-bitmap object: length=4 */
    {
        object_payload_t bitmap_payload
            = syli_object_make_bitmap_payload(4, 0xF);
        object_header_t bitmap_header = syli_object_make_header(Zone_GcLocal,
            Acyclic, Type_MixedBitmap, Flag_HasPointers, bitmap_payload);
        Object* bitmap = (Object*)syli_rt_rc_alloc_object(bitmap_header, 1, 4);
        assert(bitmap != NULL);
        assert(syli_rt_get_object_length(bitmap) == 4);
        free(bitmap);
    }

    syli_state_destroy();
    printf("✓ syli_rt_get_object_length returns correct length for all "
           "types\n\n");
}

/* ============================================================
 * Test: syli_rt_object_raw_copy
 * ============================================================ */

static void test_rt_object_raw_copy(void)
{
    printf("Test 9: syli_rt_object_raw_copy()\n");

    syli_state_init();

    size_t words = 4;
    Object* src
        = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, words);
    assert(src != NULL);

    /* Set some data in source */
    uint64_t* src_data = syli_object_data(src);
    src_data[0]        = 0xDEAD;
    src_data[1]        = 0xBEEF;
    src_data[2]        = 0xCAFE;
    src_data[3]        = 0xBABE;

    /* Create a destination object of the same size */
    Object* dst
        = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, words);
    assert(dst != NULL);

    /* Fill destination with different data */
    uint64_t* dst_data = syli_object_data(dst);
    dst_data[0]        = 0xFFFF;
    dst_data[1]        = 0xFFFF;
    dst_data[2]        = 0xFFFF;
    dst_data[3]        = 0xFFFF;

    /* Copy source to destination */
    syli_rt_object_raw_copy(src, dst);

    /* Verify header and meta_ref_count were copied */
    GCObject* src_gc = as_gc_object(src);
    GCObject* dst_gc = as_gc_object(dst);
    assert(dst_gc->header_word == src_gc->header_word);
    assert(dst_gc->meta_ref_count == src_gc->meta_ref_count);

    /* Verify data array was copied */
    uint64_t* dst_data_after = syli_object_data(dst);
    assert(dst_data_after[0] == 0xDEAD);
    assert(dst_data_after[1] == 0xBEEF);
    assert(dst_data_after[2] == 0xCAFE);
    assert(dst_data_after[3] == 0xBABE);

    free(src);
    free(dst);
    syli_state_destroy();
    printf("✓ syli_rt_object_raw_copy copies header, meta_ref_count, and "
           "data\n\n");
}

/* ============================================================
 * Test: syli_rt_gc_cycle
 * ============================================================ */

static void test_rt_gc_cycle(void)
{
    printf("Test 10: syli_rt_gc_cycle()\n");

    syli_state_init();

    /* Set budget counters to non-zero to verify they get reset */
    syli_state.tracing_budget   = -1;
    syli_state.releasing_budget = -1;
    syli_state.checking_budget  = -1;

    /* Call gc_cycle which resets budgets */
    syli_rt_gc_cycle();

    /* Budgets should be reset */
    assert(syli_state.tracing_budget == (int)syli_state.BUDGET_GC_TRACING);
    assert(syli_state.releasing_budget == (int)syli_state.BUDGET_GC_RELEASING);
    assert(syli_state.checking_budget == (int)syli_state.BUDGET_GC_CHECKING);

    syli_state_destroy();
    printf("✓ syli_rt_gc_cycle() resets budgets\n\n");
}

/* ============================================================
 * Test: syli_rt_object_notify_mutation
 * ============================================================ */

static void test_rt_object_notify_mutation(void)
{
    printf("Test 12: syli_rt_object_notify_mutation()\n");

    syli_state_init();

    /* Ensure the mutation worklist is initially empty */
    assert(vector_size_GCObject(&syli_state.tracing_mutations_worklist) == 0);

    /* 1. Basic case: marked + traceable obj, unmarked target
     *    → target gets marked and pushed to mutations worklist.
     *
     *    Allocate while tracing_current_bit_mark == 0 so objects are NOT
     *    auto-marked. Then toggle to MASK_MARKING_BIT for testing. */
    {
        Object* obj = make_object(
            Zone_GcLocal, Acyclic, Type_MonoImm, Flag_Traceable, 1);
        assert(obj != NULL);

        Object* target
            = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, 1);
        assert(target != NULL);

        gc_next_marking_generation();

        /* Mark obj manually */
        gc_mark_tag_object(obj);
        assert(gc_is_object_mark_tagged(obj));
        assert(!gc_is_object_mark_tagged(target));

        syli_rt_object_notify_mutation(obj, target);

        /* target should now be marked and in the mutations worklist */
        assert(gc_is_object_mark_tagged(target));
        assert(
            vector_size_GCObject(&syli_state.tracing_mutations_worklist) == 1);

        /* Clean up: pop the worklist */
        vector_pop_back_GCObject(&syli_state.tracing_mutations_worklist);
        assert(
            vector_size_GCObject(&syli_state.tracing_mutations_worklist) == 0);

        free(obj);
        free(target);
    }

    /* 2. obj is NOT marked → no-op */
    {
        /* Toggle back to 0 before allocating */
        gc_next_marking_generation();

        Object* obj = make_object(
            Zone_GcLocal, Acyclic, Type_MonoImm, Flag_Traceable, 1);
        assert(obj != NULL);

        Object* target
            = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, 1);
        assert(target != NULL);

        gc_next_marking_generation();

        /* obj is NOT marked */
        assert(!gc_is_object_mark_tagged(obj));

        syli_rt_object_notify_mutation(obj, target);

        /* worklist should still be empty */
        assert(
            vector_size_GCObject(&syli_state.tracing_mutations_worklist) == 0);

        free(obj);
        free(target);
    }

    /* 3. obj is NOT traceable → no-op */
    {
        gc_next_marking_generation();

        Object* obj = make_object(Zone_GcLocal, Acyclic, Type_MonoImm,
            Flag_None, 1); /* No Flag_Traceable */
        assert(obj != NULL);

        Object* target
            = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, 1);
        assert(target != NULL);

        gc_next_marking_generation();

        /* Mark obj */
        gc_mark_tag_object(obj);
        assert(gc_is_object_mark_tagged(obj));

        /* obj is NOT traceable */
        assert(!syli_object_is_traceable(obj));

        syli_rt_object_notify_mutation(obj, target);

        /* worklist should still be empty */
        assert(
            vector_size_GCObject(&syli_state.tracing_mutations_worklist) == 0);

        free(obj);
        free(target);
    }

    /* 4. target is already marked → no-op */
    {
        gc_next_marking_generation();

        Object* obj = make_object(
            Zone_GcLocal, Acyclic, Type_MonoImm, Flag_Traceable, 1);
        assert(obj != NULL);

        Object* target
            = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, 1);
        assert(target != NULL);

        gc_next_marking_generation();

        /* Mark both obj and target */
        gc_mark_tag_object(obj);
        gc_mark_tag_object(target);
        assert(gc_is_object_mark_tagged(obj));
        assert(gc_is_object_mark_tagged(target));

        syli_rt_object_notify_mutation(obj, target);

        /* worklist should still be empty (target already marked) */
        assert(
            vector_size_GCObject(&syli_state.tracing_mutations_worklist) == 0);

        free(obj);
        free(target);
    }

    /* 5. Static obj → no-op (static objects are never
     *    marked or traceable by design) */
    {
        gc_next_marking_generation();

        Object static_obj;
        static_obj.header_word = syli_object_make_header(
            Zone_Static, Acyclic, Type_MonoImm, Flag_None, 0);

        Object* target
            = make_object(Zone_GcLocal, Acyclic, Type_MonoImm, Flag_None, 1);
        assert(target != NULL);

        gc_next_marking_generation();

        syli_rt_object_notify_mutation(&static_obj, target);

        /* worklist should be empty */
        assert(
            vector_size_GCObject(&syli_state.tracing_mutations_worklist) == 0);

        free(target);
    }

    syli_state_destroy();
    printf("✓ syli_rt_object_notify_mutation works correctly\n\n");
}

/* ============================================================
 * Main
 * ============================================================ */

int main(void)
{
    printf("\033[1;34m=== Running syli.h API Tests ===\033[0m\n\n");

    test_rt_rc_alloc_object();
    test_rt_object_incr_decr();
    test_rt_object_decr_n();
    test_rt_object_check_release();
    test_rt_object_check_lost_cyclic_release();
    test_rt_get_object_tag();
    test_rt_get_object_length();
    test_rt_object_raw_copy();
    test_rt_gc_cycle();
    test_rt_object_notify_mutation();

    printf("\033[1;32m=== All syli.h API Tests Passed! ===\033[0m\n\n");
    return 0;
}
