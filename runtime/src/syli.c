#include "syli/syli.h"
#include "syli/syli_state.h"

#include "syli/gc_helpers.h"
#include "syli/header_object.h"
#include "syli/object.h"
#include <stdio.h>
#include <stdlib.h>

GCObject* syli_rt_rc_alloc_object(
    object_header_t header, size_t refcount, size_t words)
{
    // Tag the object with the current generation's mark value
    uint64_t meta_ref_count = refcount | syli_state.tracing_current_bit_mark;

    GCObject* obj = (GCObject*)syli_object_alloc(header, meta_ref_count, words);

    // Initialize the object fields to 0
    // TODO: this will be removed once put in the language level
    //       the initialization is handled by the compiler
    for (size_t i = 0; i < words; i++) {
        obj->value[i] = 0;
    }

    return obj;
}

void syli_rt_object_incr(Object* obj)
{
    ObjectZone zone = syli_object_get_zone(obj);

    // Static: nothing to do
    if (zone == Zone_Static)
        return;

    if (zone == Zone_GcLocal) {
        GCObject* local_obj = as_gc_object(obj);
        local_obj->meta_ref_count++;
        return;
    }
}

void syli_rt_object_decr(Object* obj, obj_ptr obj_ptr)
{
    assert(obj != NULL);
    ObjectZone zone = syli_object_get_zone(obj);

    if (zone == Zone_Static)
        return;

    if (zone == Zone_GcLocal) {
        GCObject* local_obj = as_gc_object(obj);
        local_obj->meta_ref_count--;

        if (syli_object_refcount(obj) == 0) {

            if (syli_object_is_mono_imm(obj)) {
                syli_state.total_objects_memory_freed++;

                // Freeing an object that is not cyclic and has no value pointer
                gc_account_cyclic_free(obj);
                free(obj);
                return;
            }

            // Reaching 0 is a normal release, not a lost cycle: leaving the
            // candidate registry before the handling lost cyclic releasing owns it.
            gc_remove_from_candidates_if_registered(obj);

            gc_releasing_worklist_push(obj_ptr);
            return;
        }
    }
}

void syli_rt_object_decr_n(Object* obj, int n)
{
    ObjectZone zone = syli_object_get_zone(obj);

    if (zone == Zone_Static)
        return;

    if (zone == Zone_GcLocal) {
        GCObject* local_obj = as_gc_object(obj);
        syli_object_decr_local_n((Object*)local_obj, n);
        return;
    }
}

uint64_t syli_rt_get_object_tag(Object* obj)
{
    assert(obj != NULL);
    return syli_object_get_variant_tag(obj);
}

uint64_t syli_rt_get_object_length(Object* obj)
{
    assert(obj != NULL);
    return syli_object_length(obj);
}

void syli_match_failure(void)
{
    fprintf(stderr, "match failure\n");
    abort();
}

void syli_rt_object_notify_mutation(
    Object* obj, Object* target, obj_ptr target_ptr)
{
    assert(obj != NULL && target != NULL);

    if (!gc_is_object_mark_tagged(obj)) {
        return;
    }

    // TODO: make this as assert since only treceable objects will be notified.
    if (!syli_object_is_traceable(obj)) {
        return;
    }

    if (gc_is_object_mark_tagged(target)) {
        return;
    }

    // mark target to avoid re-adding it again and again
    // since the tracing is concurrent and it is possible
    // to another mutation to re-add it.
    gc_mark_tag_object(target);

    gc_vector_push_back(&syli_state.tracing_mutations_worklist, target_ptr);
}

void syli_rt_gc_cycle() { syli_state_gc_cycle(); }

/************************************************
 * Ownership Tag Primitives
 ************************************************/

obj_ptr syli_rt_ownership_alloc_object(
    object_header_t header, size_t refcount, size_t words)
{
    GCObject* obj = syli_rt_rc_alloc_object(header, refcount, words);
    obj_ptr ptr   = syli_ownership_set_own(obj);

    // Track every cyclic object
    if (syli_object_is_cyclic(as_object(obj))) {
        syli_state.cyclic_mem_alloc += syli_object_total_words(as_object(obj));
        syli_state.cyclic_obj_alloc++;

        if (syli_object_is_cyclic_mutable(obj)) {
            gc_register_candidate(ptr);
        }
    }

    return ptr;
}

obj_ptr syli_rt_ownership_share(obj_ptr ptr)
{
    assert(!syli_ownership_is_always_borrow(ptr));
    assert(!syli_ownership_is_immediate(ptr));
    Object* obj = (Object*)syli_ownership_untag(ptr);
    assert(obj != NULL);
    syli_rt_object_incr(obj);
    return syli_ownership_set_own(ptr);
}

void syli_rt_ownership_decr(obj_ptr ptr)
{
    assert(!syli_ownership_is_always_borrow((obj_ptr)ptr));
    assert(!syli_ownership_is_immediate(ptr));
    assert(syli_ownership_is_own_ref(ptr));
    Object* obj = (Object*)syli_ownership_untag(ptr);
    assert(obj != NULL);
    syli_rt_object_decr(obj, ptr);
}

obj_ptr syli_rt_ownership_untag(obj_ptr ptr)
{
    return syli_ownership_untag(ptr);
}

void syli_rt_ownership_incr(obj_ptr ptr)
{
    assert(!syli_ownership_is_always_borrow((obj_ptr)ptr));
    assert(!syli_ownership_is_immediate(ptr));
    assert(syli_ownership_is_own_ref(ptr));
    Object* obj = (Object*)syli_ownership_untag(ptr);
    assert(obj != NULL);
    syli_rt_object_incr(obj);
}

void syli_rt_ownership_notify_mutation(obj_ptr ptr, obj_ptr target_ptr)
{
    assert(!syli_ownership_is_immediate(ptr));
    if (!syli_ownership_is_own_ref(ptr)) {
        return;
    }

    Object* obj = syli_object_of_obj_ptr(ptr);

    if (syli_state.tracing_state == Tracing
        || syli_state.tracing_state == Mutation_Prepare) {
        Object* target = syli_object_of_obj_ptr(target_ptr);
        syli_rt_object_notify_mutation(obj, target, target_ptr);
    }
}

void syli_rt_ownership_release(void* ptr)
{
    assert(!syli_ownership_is_always_borrow((obj_ptr)ptr));
    assert(!syli_ownership_is_immediate((obj_ptr)ptr));
    if (syli_ownership_is_own_ref(ptr)) {
        Object* obj = (Object*)syli_ownership_untag(ptr);
        assert(obj != NULL);
        syli_rt_object_decr(obj, ptr);
    }
}

obj_ptr syli_rt_ownership_own(obj_ptr ptr)
{
    assert(!syli_ownership_is_always_borrow(ptr));
    assert(!syli_ownership_is_immediate(ptr));
    if (syli_ownership_is_own_ref(ptr)) {
        return ptr;
    }
    Object* obj = (Object*)syli_ownership_untag(ptr);
    assert(obj != NULL);
    syli_rt_object_incr(obj);
    return syli_ownership_set_own(obj);
}

obj_ptr syli_rt_ownership_borrow(obj_ptr ptr)
{
    assert(!syli_ownership_is_always_borrow(ptr));
    assert(!syli_ownership_is_immediate(ptr));
    return syli_ownership_untag(ptr);
}