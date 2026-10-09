#include <assert.h>
#include <stdio.h>

#include "syli/gc_helpers.h"
#include "syli/gc_roots.h"
#include "syli/object.h"

#include "syli/syli_state.h"

// Non-recursive DFS marking (precise - uses type descriptors)
static void gc_one_step_tracing(void)
{

    Object* obj = syli_object_of_obj_ptr(
        gc_vector_pop_back(&syli_state.tracing_worklist));

    assert(obj != NULL && "Null GCObject in tracing worklist");

    // Clear the in-worklist guard now that we've popped it
    syli_object_clear_flags(obj, Meta_Flags_Tracing);

    if (syli_object_has_flags(obj, Meta_Flags_Waiting_Remove)) {
        gc_account_cyclic_free(obj);
        free(obj);
        return;
    }

    GCObject* current = as_gc_object(obj);

    // Skip freed objects
    if ((current->meta_ref_count & REFCOUNT_MASK) == 0) {
        return;
    }

    if (gc_is_object_mark_tagged(as_object(current))) {
        return; // Already marked in this tracing cycle
    }

    gc_mark_tag_object(as_object(current));
    syli_state.total_objects_traced++;

    // All the child are reference
    if (syli_object_is_mono_ref(obj)) {
        // Fast path for uniform all-reference objects
        size_t length = syli_object_length(obj);
        syli_state.tracing_budget -= (int)length;
        for (size_t i = 0; i < length; i++) {
            uint64_t field_value = current->value[i];
            if (!field_value
                || !syli_ownership_is_own_ref((obj_ptr)field_value)) {
                continue;
            }
            gc_tracing_worklist_push((obj_ptr)field_value);
        }
        return;
    }

    // Mixed bitmap references
    if (syli_object_is_mixed_bitmap(obj)) {
        // All fields are references, traverse all
        size_t length = syli_object_bitmap_length(obj);
        int bitmap    = syli_object_bitmap_bits(obj);
        syli_state.tracing_budget -= (int)length;
        for (size_t i = 0; i < length; i++) {
            if (!syli_bitmap_is_ref(bitmap, i)) {
                continue; // non-reference field
            }
            uint64_t field_value = current->value[i];
            if (!field_value
                || !syli_ownership_is_own_ref((obj_ptr)field_value)) {
                continue;
            }
            gc_tracing_worklist_push((obj_ptr)field_value);
        }
        return;
    }

    // Mixed order references
    if (syli_object_is_mixed_order(obj)) {
        size_t ptr_count = syli_object_order_ptr_count(obj);
        syli_state.tracing_budget -= ptr_count;
        for (size_t i = 0; i < ptr_count; i++) {
            uint64_t field_value = current->value[i];
            if (!field_value
                || !syli_ownership_is_own_ref((obj_ptr)field_value)) {
                continue;
            }
            gc_tracing_worklist_push((obj_ptr)field_value);
        }
        return;
    }
}

static void gc_one_step_prepare_tracing_mutations()
{
    // obj is not pushed to the tracing_worklist, if you noticed,
    // this is because obj is already marked.

    obj_ptr obj_p = gc_vector_pop_back(&syli_state.tracing_mutations_worklist);
    assert(syli_ownership_is_own_ref(obj_p));
    Object* obj      = syli_object_of_obj_ptr(obj_p);
    GCObject* gc_obj = as_gc_object(obj);

    assert(gc_obj != NULL);
    assert(syli_object_get_zone((Object*)gc_obj) == Zone_GcLocal);

    if (syli_object_has_flags(obj, Meta_Flags_Waiting_Remove)) {
        free(obj);
        return;
    }

    if (syli_object_is_mono_ref(obj)) {
        // All fields are references, traverse all
        size_t length = syli_object_length(obj);
        syli_state.tracing_budget -= (int)length;
        for (size_t i = 0; i < length; i++) {
            uint64_t field_value = gc_obj->value[i];
            if (!field_value
                || !syli_ownership_is_own_ref((obj_ptr)field_value)) {
                continue;
            }
            gc_tracing_worklist_push((obj_ptr)field_value);
        }
        return;
    }

    if (syli_object_is_mixed_bitmap(obj)) {
        // Precisely traverse only reference fields using type descriptor
        uint64_t length = syli_object_bitmap_length(obj);
        uint32_t bitmap = syli_object_bitmap_bits(obj);
        for (uint32_t i = 0; i < length; i++) {
            if (!syli_bitmap_is_ref(bitmap, i)) {
                continue; // non-reference field
            }
            uint64_t field_value = gc_obj->value[i];
            if (!field_value
                || !syli_ownership_is_own_ref((obj_ptr)field_value)) {
                continue;
            }
            gc_tracing_worklist_push((obj_ptr)field_value);
        }
        return;
    }

    if (syli_object_is_mixed_order(obj)) {
        // Precisely traverse only reference fields using type descriptor
        size_t ptr_count = syli_object_order_ptr_count(obj);
        syli_state.tracing_budget -= (int)ptr_count;
        for (size_t i = 0; i < ptr_count; i++) {
            uint64_t field_value = gc_obj->value[i];
            if (!field_value
                || !syli_ownership_is_own_ref((obj_ptr)field_value)) {
                continue;
            }
            gc_tracing_worklist_push((obj_ptr)field_value);
        }
        return;
    }
}

// ==================== Lost-cycle release ====================
//
// The checking phase collects unreachable mutable-cyclic candidates. Release
// mirrors the normal releasing pipeline but keeps its own worklist/waitlist so
// the two mechanisms never mix. An unreachable object with refcount > 1 is
// still referenced by a peer, so it waits until its referrers are released.

static inline void lost_cycle_enqueue(vector_obj_ptr* list, obj_ptr obj_p)
{
    Object* obj = syli_object_of_obj_ptr(obj_p);
    if (syli_object_has_flags(obj, Meta_Flags_Lost_Cycle_Releasing)) {
        return;
    }
    syli_object_set_flags(obj, Meta_Flags_Lost_Cycle_Releasing);
    gc_vector_push_back(list, obj_p);
}

static inline void lost_cycle_route(obj_ptr obj_p)
{
    Object* obj = syli_object_of_obj_ptr(obj_p);

    const int rc = (int)syli_object_refcount(obj);
    if (rc > 1) {
        lost_cycle_enqueue(&syli_state.lost_cycle_waitlist, obj_p);
    } else {
        lost_cycle_enqueue(&syli_state.lost_cycle_worklist, obj_p);
    }
}

// Release one reference to a child while walking a lost cycle.
static inline void lost_cycle_child_decr(obj_ptr obj_p)
{
    Object* obj = syli_object_of_obj_ptr(obj_p);
    syli_object_decr_local(obj);

    const int rc = (int)syli_object_refcount(obj);

    if (rc == 0) {
        if (syli_object_has_pointers(obj) == 0) {
            free_released_object(obj);
            return;
        }
        lost_cycle_enqueue(&syli_state.lost_cycle_worklist, obj_p);
        return;
    }

    if (gc_is_object_mark_tagged(obj)) {
        return; // reachable: not a lost cycle
    }

    lost_cycle_route(obj_p);
}

static inline void lost_cycle_release_children(Object* obj)
{
    GCObject* gc_obj = as_gc_object(obj);

    if (syli_object_is_mono_ref(obj)) {
        size_t length = syli_object_length(obj);
        syli_state.checking_budget -= (int)length;
        for (size_t i = 0; i < length; i++) {
            uint64_t field_value = gc_obj->value[i];
            if (!field_value
                || !syli_ownership_is_own_ref((obj_ptr)field_value)) {
                continue;
            }
            lost_cycle_child_decr((obj_ptr)field_value);
        }
    } else if (syli_object_is_mixed_bitmap(obj)) {
        size_t length   = syli_object_bitmap_length(obj);
        uint32_t bitmap = syli_object_bitmap_bits(obj);
        syli_state.checking_budget -= (int)length;
        for (size_t i = 0; i < length; i++) {
            if (!syli_bitmap_is_ref(bitmap, i)) {
                continue;
            }
            uint64_t field_value = gc_obj->value[i];
            if (!field_value
                || !syli_ownership_is_own_ref((obj_ptr)field_value)) {
                continue;
            }
            lost_cycle_child_decr((obj_ptr)field_value);
        }
    } else if (syli_object_is_mixed_order(obj)) {
        size_t ptr_count = syli_object_order_ptr_count(obj);
        syli_state.checking_budget -= (int)ptr_count;
        for (size_t i = 0; i < ptr_count; i++) {
            uint64_t field_value = gc_obj->value[i];
            if (!field_value
                || !syli_ownership_is_own_ref((obj_ptr)field_value)) {
                continue;
            }
            lost_cycle_child_decr((obj_ptr)field_value);
        }
    }
}

// Scan the candidate registry, to find the unreachable
static inline void gc_one_step_scan(void)
{
    syli_state.checking_budget--;

    size_t reg_size
        = vector_size_CyclicCandidate(&syli_state.cyclic_candidates);
    if (syli_state.current_candidate_check_index >= reg_size) {
        // Registry scanned: release what was collected.
        syli_state.current_candidate_check_index = 0;
        syli_state.tracing_state                 = Releasing_Unreachable;
        return;
    }

    CyclicCandidate* candidate = (CyclicCandidate*)vector_at_CyclicCandidate(
        &syli_state.cyclic_candidates,
        syli_state.current_candidate_check_index);
    obj_ptr obj_p = candidate->obj;
    Object* obj   = syli_object_of_obj_ptr(obj_p);

    if (gc_is_object_mark_tagged(obj)) {
        // Still reachable: keep it in the registry.
        syli_state.current_candidate_check_index++;
    } else {
        // Unreachable: leave the registry and release it.
        syli_object_clear_flags(obj, Meta_Flags_Cyclic_Candidate);
        gc_remove_candidate_at(syli_state.current_candidate_check_index);
        lost_cycle_route(obj_p);
    }
}

// Drain the lost-cycle worklist/waitlist.
static inline void gc_one_step_release_unreachable(void)
{
    syli_state.checking_budget--;

    if (vector_size_obj_ptr(&syli_state.lost_cycle_worklist) > 0) {
        obj_ptr obj_p = gc_vector_pop_back(&syli_state.lost_cycle_worklist);
        Object* obj   = syli_object_of_obj_ptr(obj_p);

        if (!syli_object_has_flags(obj, Meta_Flags_Children_Released)) {
            lost_cycle_release_children(obj);
            syli_object_set_flags(obj, Meta_Flags_Children_Released);
        }

        if (syli_object_refcount(obj) == 0) {
            free_released_object(obj);
        } else {
            gc_vector_push_back(&syli_state.lost_cycle_waitlist, obj_p);
        }
        return;
    }

    // Worklist drained; promote the waitlist for another pass. Objects whose
    // referrers were released now have refcount 0.
    if (vector_size_obj_ptr(&syli_state.lost_cycle_waitlist) > 0) {
        vector_obj_ptr tmp             = syli_state.lost_cycle_worklist;
        syli_state.lost_cycle_worklist = syli_state.lost_cycle_waitlist;
        syli_state.lost_cycle_waitlist = tmp;
        vector_clear_obj_ptr(&syli_state.lost_cycle_waitlist);
        return;
    }

    // waitlist and worklist are empty: done.
    syli_state.tracing_state = Tracing_Idle;
}

void syli_state_gc_tracing()
{

    while (1) {

        if (syli_state.tracing_budget <= 0)
            return;

        switch (syli_state.tracing_state) {
        case Tracing_Idle:

            if (syli_state.tracing_state == Tracing_Idle) {
                const size_t cyclic_objs      = gc_current_cyclic_obj();
                const size_t candidates_live  = gc_cyclic_candidate_count();
                const double candidates_ratio = cyclic_objs == 0
                    ? 0.0
                    : (double)candidates_live / (double)cyclic_objs;

                // TODO: the triggering heuristic is naive one, we should
                // find an accurate one. Making it it dynamic could be an
                // option. One idea is to count during the tracing the possible
                // cycles and use that for the next triggering.

                if (gc_current_cyclic_mem()
                        > syli_state.THRESHOLD_MEM_CYCLIC_OBJ
                    && candidates_ratio > syli_state.THRESHOLD_CANDIDATES_RATIO
                    && syli_state.cyclic_obj_alloc
                        > syli_state.cyclic_obj_alloc_at_trace) {

                    syli_state.tracing_state = Tracing;
                    syli_state.cyclic_obj_alloc_at_trace
                        = syli_state.cyclic_obj_alloc;
                    gc_next_marking_generation();

                    syli_rt_collect_stack_roots();

                    if (vector_size_obj_ptr(&syli_state.tracing_worklist) == 0
                        && vector_size_obj_ptr(
                               &syli_state.tracing_mutations_worklist)
                            == 0) {
                        syli_state.tracing_state = Checking_Cyclic_Candidates;
                    }
                } else {
                    return; // No need to start tracing
                }
            }

            break;

        case Tracing:
            gc_one_step_tracing();
            syli_state.tracing_steps++;

            if (vector_size_obj_ptr(&syli_state.tracing_worklist) == 0
                && vector_size_obj_ptr(&syli_state.tracing_mutations_worklist)
                    == 0) {
                syli_state.tracing_state = Checking_Cyclic_Candidates;
                break;
            }

            if (vector_size_obj_ptr(&syli_state.tracing_mutations_worklist)
                > 0) {
                syli_state.tracing_state = Mutation_Prepare;
                break;
            }

            break;
        case Mutation_Prepare:
            if (vector_size_obj_ptr(&syli_state.tracing_mutations_worklist)
                == 0) {
                // No mutations left: resume tracing or finish the cycle.
                if (vector_size_obj_ptr(&syli_state.tracing_worklist) > 0) {
                    syli_state.tracing_state = Tracing;
                } else {
                    syli_state.tracing_state = Checking_Cyclic_Candidates;
                }
                break;
            }
            gc_one_step_prepare_tracing_mutations();
            syli_state.mutation_steps++;
            break;

        case Checking_Cyclic_Candidates:
            gc_one_step_scan();
            syli_state.checking_steps++;
            break;

        case Releasing_Unreachable:
            gc_one_step_release_unreachable();
            syli_state.checking_steps++;
            break;
        }
    }
}
