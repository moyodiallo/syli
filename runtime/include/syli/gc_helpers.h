#include "syli/object.h"
#include "syli/syli_state.h"

static inline size_t gc_cyclic_candidate_count(void)
{
    return vector_size_CyclicCandidate(&syli_state.cyclic_candidates);
}

static inline size_t gc_current_cyclic_mem(void)
{
    return syli_state.cyclic_mem_alloc >= syli_state.cyclic_mem_dealloc
        ? syli_state.cyclic_mem_alloc - syli_state.cyclic_mem_dealloc
        : 0;
}

static inline size_t gc_current_cyclic_obj(void)
{
    return syli_state.cyclic_obj_alloc >= syli_state.cyclic_obj_dealloc
        ? syli_state.cyclic_obj_alloc - syli_state.cyclic_obj_dealloc
        : 0;
}

static inline void gc_register_candidate(obj_ptr obj_ptr)
{
    Object* obj = syli_object_of_obj_ptr(obj_ptr);
    if (syli_object_has_flags(as_object(obj), Meta_Flags_Cyclic_Candidate)) {
        return;
    }
    CyclicCandidate* candidate
        = vector_alloc_slot_CyclicCandidate(&syli_state.cyclic_candidates);
    candidate->obj = obj_ptr;
    size_t last_index
        = vector_size_CyclicCandidate(&syli_state.cyclic_candidates) - 1;

    syli_object_set_candidate_index(as_gc_object(obj), last_index);
    syli_object_set_flags(as_object(obj), Meta_Flags_Cyclic_Candidate);
}

static inline void gc_remove_candidate_at(size_t index)
{
    vector_CyclicCandidate* vector = &syli_state.cyclic_candidates;
    size_t last                    = vector_size_CyclicCandidate(vector) - 1;
    if (index != last) {
        CyclicCandidate* data
            = (CyclicCandidate*)vector_at_CyclicCandidate(vector, index);
        CyclicCandidate* last_data
            = (CyclicCandidate*)vector_at_CyclicCandidate(vector, last);
        *data = *last_data;
        // The entry previously at `last` now lives at `index`; keep its
        // object's stored index in sync so it can still be removed later.
        Object* moved = syli_object_of_obj_ptr(data->obj);
        syli_object_set_candidate_index(as_gc_object(moved), index);
    }
    vector_pop_back_CyclicCandidate(vector);
}

static inline void gc_account_cyclic_free(Object* obj)
{
    if (syli_object_is_cyclic(obj)) {
        syli_state.cyclic_mem_dealloc += syli_object_total_words(obj);
        syli_state.cyclic_obj_dealloc++;
    }
}

static inline void free_released_object(Object* obj)
{
    if (syli_object_has_flags(obj, Meta_Flags_Cyclic_Candidate)) {
        size_t index = syli_object_get_candidate_index(as_gc_object(obj));
        gc_remove_candidate_at(index);
        syli_object_clear_flags(obj, Meta_Flags_Cyclic_Candidate);
    }

    if (syli_object_has_flags(obj, Meta_Flags_Tracing)) {
        syli_object_set_flags(obj, Meta_Flags_Waiting_Remove);
        return;
    }

    syli_state.total_objects_memory_freed++;
    gc_account_cyclic_free(obj);
    free(obj);
}

static inline void gc_remove_from_candidates_if_registered(Object* obj)
{
    if (syli_object_has_flags(obj, Meta_Flags_Cyclic_Candidate)) {
        size_t index = syli_object_get_candidate_index(as_gc_object(obj));
        gc_remove_candidate_at(index);
        syli_object_clear_flags(obj, Meta_Flags_Cyclic_Candidate);
    }
}

static inline obj_ptr gc_vector_pop_back(vector_obj_ptr* vector)
{
    assert(
        vector_size_obj_ptr(vector) > 0 && "pop_stack called on empty vector");
    obj_ptr* back = (obj_ptr*)vector_back_obj_ptr(vector);
    obj_ptr obj   = *back;
    vector_pop_back_obj_ptr(vector);
    return obj;
}

static inline void gc_vector_push_back(vector_obj_ptr* vector, obj_ptr obj)
{
    obj_ptr* slot = (obj_ptr*)vector_alloc_slot_obj_ptr(vector);
    *slot         = obj;
}

static inline void gc_tracing_worklist_push(obj_ptr obj_p)
{
    if (!syli_ownership_is_own_ref(obj_p)) {
        return;
    }
    Object* child = syli_object_of_obj_ptr(obj_p);
    if (syli_object_has_flags(child, Meta_Flags_Tracing)) {
        return;
    }
    syli_object_set_flags(child, Meta_Flags_Tracing);
    gc_vector_push_back(&syli_state.tracing_worklist, obj_p);
}

static inline void gc_releasing_worklist_push(obj_ptr obj_p)
{
    Object* obj = syli_object_of_obj_ptr(obj_p);
    assert(!syli_object_has_flags(obj, Meta_Flags_Releasing));
    syli_object_set_flags(obj, Meta_Flags_Releasing);
    gc_vector_push_back(&syli_state.releasing_waitlist, obj_p);
}

// ========================
// Object marking bit management
// ========================

static inline void gc_next_marking_generation(void)
{
    // Toggle the marking bit for the next tracing generation
    syli_state.tracing_current_bit_mark ^= MASK_MARKING_BIT;
    syli_state.tracing_generations++;
}

static inline void gc_mark_tag_object(Object* obj)
{
    GCObject* gc_obj       = as_gc_object(obj);
    gc_obj->meta_ref_count = (gc_obj->meta_ref_count & ~MASK_MARKING_BIT)
        | syli_state.tracing_current_bit_mark;
}

static inline bool gc_is_object_mark_tagged(Object* obj)
{
    return (as_gc_object(obj)->meta_ref_count & MASK_MARKING_BIT)
        == syli_state.tracing_current_bit_mark;
}
