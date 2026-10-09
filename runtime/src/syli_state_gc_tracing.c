#include <assert.h>
#include <stdio.h>

#include "syli/gc_helpers.h"
#include "syli/gc_roots.h"
#include "syli/object.h"

#include "syli/syli_state.h"

// ============ Tracing of the cyclic and traceable objects =========
//
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
// lost_cycle_worklist only holds refcount-0 objects, so it never overlaps with
// the normal releasing pipeline. Unreachable candidates are treated once.

static inline void lost_cycle_enqueue_free(obj_ptr obj_p)
{
    Object* obj = syli_object_of_obj_ptr(obj_p);
    if (syli_object_has_flags(obj, Meta_Flags_Lost_Cycle_Releasing)) {
        return;
    }
    assert(syli_object_refcount(obj) == 0);
    syli_object_set_flags(obj, Meta_Flags_Lost_Cycle_Releasing);
    gc_vector_push_back(&syli_state.lost_cycle_worklist, obj_p);
}

// Release one reference to a child while walking a lost cycle.
static inline void lost_cycle_child_decr(obj_ptr obj_p)
{
    Object* obj = syli_object_of_obj_ptr(obj_p);
    syli_object_decr_local(obj);

    if (syli_object_refcount(obj) == 0) {
        if (syli_object_has_pointers(obj) == 0) {
            free_released_object(obj);
            return;
        }
        lost_cycle_enqueue_free(obj_p);
    }
    // RC > 0: still held by an unprocessed peer or not lost.
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

// Scan candidates top-down which avoid missing an object
// since a candidate could be removed via swap last entry.
static inline void gc_one_step_scan(void)
{
    size_t reg_size
        = vector_size_CyclicCandidate(&syli_state.cyclic_candidates);

    // Clamp after any removal shrank the list.
    if (syli_state.current_candidate_check_index > reg_size) {
        syli_state.current_candidate_check_index = reg_size;
    }
    if (syli_state.current_candidate_check_index == 0) {
        return; // list drained; the caller moves to idle
    }

    size_t index               = syli_state.current_candidate_check_index - 1;
    CyclicCandidate* candidate = (CyclicCandidate*)vector_at_CyclicCandidate(
        &syli_state.cyclic_candidates, index);
    obj_ptr obj_p = candidate->obj;
    Object* obj   = syli_object_of_obj_ptr(obj_p);

    syli_state.current_candidate_check_index = index;

    if (gc_is_object_mark_tagged(obj)) {
        return;
    }

    if (!syli_object_has_flags(obj, Meta_Flags_Children_Released)) {
        syli_object_set_flags(obj, Meta_Flags_Children_Released);
        lost_cycle_release_children(obj);
    }

    if (syli_object_refcount(obj) == 0) {
        lost_cycle_enqueue_free(obj_p);
    }
}

// Free one object from the deferred-free queue.
static inline void gc_one_step_free_unreachable(void)
{
    obj_ptr obj_p = gc_vector_pop_back(&syli_state.lost_cycle_worklist);
    Object* obj   = syli_object_of_obj_ptr(obj_p);

    if (!syli_object_has_flags(obj, Meta_Flags_Children_Released)) {
        syli_object_set_flags(obj, Meta_Flags_Children_Released);
        lost_cycle_release_children(obj);
    }

    free_released_object(obj);
}

// ==================== The state machine ====================

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
                    syli_state.current_candidate_check_index
                        = gc_cyclic_candidate_count();
                    gc_next_marking_generation();

                    syli_rt_collect_stack_roots();

                    if (vector_size_obj_ptr(&syli_state.tracing_worklist) == 0
                        && vector_size_obj_ptr(
                               &syli_state.tracing_mutations_worklist)
                            == 0) {
                        syli_state.tracing_state = Reclaiming_Cyclic_Candidates;
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
                syli_state.tracing_state = Reclaiming_Cyclic_Candidates;
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
                    syli_state.tracing_state = Reclaiming_Cyclic_Candidates;
                }
                break;
            }
            gc_one_step_prepare_tracing_mutations();
            syli_state.mutation_steps++;
            break;

        case Reclaiming_Cyclic_Candidates:
            syli_state.checking_budget--;
            if (vector_size_obj_ptr(&syli_state.lost_cycle_worklist) > 0) {
                gc_one_step_free_unreachable();
            } else if (syli_state.current_candidate_check_index == 0) {
                syli_state.tracing_state = Tracing_Idle;
            } else {
                gc_one_step_scan();
            }
            syli_state.checking_steps++;
            break;
        }
    }
}
