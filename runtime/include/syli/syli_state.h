#ifndef SYLI_STATE_H
#define SYLI_STATE_H

#include <stdatomic.h>
#include <stdint.h>
#include <stdlib.h>

#include "chunk_vector.h"
#include "env.h"
#include "gc_roots.h"
#include "object.h"

#define BUDGET_BATCH_SIZE 1000

typedef struct CyclicCandidate {
    obj_ptr obj;
} CyclicCandidate;

typedef enum Tracing_state_machine {
    Tracing_Idle               = 0,
    Tracing                    = 1,
    Mutation_Prepare           = 2,
    Checking_Cyclic_Candidates = 3,
    Releasing_Unreachable      = 4,
} Tracing_state_machine;

typedef enum Releasing_state_machine {
    Releasing_Idle = 0,
    Releasing      = 1
} Releasing_state_machine;

CHUNK_VECTOR_STRUCT(obj_ptr);
CHUNK_VECTOR_STRUCT(CyclicCandidate);

CHUNK_VECTOR_IMPLEMENT(obj_ptr);
CHUNK_VECTOR_IMPLEMENT(CyclicCandidate);

// ==================== Syli State ====================
typedef struct Syli_state {

    size_t THRESHOLD_MEM_CYCLIC_OBJ;
    double THRESHOLD_CANDIDATES_RATIO;
    size_t THRESHOLD_RELEASING_BUCKET;

    size_t BUDGET_GC_TRACING;
    size_t BUDGET_GC_RELEASING;
    size_t BUDGET_GC_CHECKING;

    int tracing_budget;
    int releasing_budget;
    int checking_budget;

    vector_obj_ptr tracing_worklist;
    vector_obj_ptr tracing_mutations_worklist;

    vector_obj_ptr releasing_worklist;

    vector_obj_ptr releasing_waitlist;

    vector_CyclicCandidate cyclic_candidates;

    vector_obj_ptr lost_cycle_worklist;
    vector_obj_ptr lost_cycle_waitlist;

    size_t releasing_steps;
    size_t tracing_steps;
    size_t mutation_steps;
    size_t checking_steps;

    size_t total_objects_traced;
    size_t total_objects_released;
    size_t total_objects_memory_freed;

    size_t generation_tracing;

    uint64_t tracing_current_bit_mark;
    size_t tracing_generations;

    Tracing_state_machine tracing_state;
    Releasing_state_machine releasing_state;

    size_t cyclic_mem_alloc;
    size_t cyclic_mem_dealloc;
    size_t cyclic_obj_alloc;
    size_t cyclic_obj_dealloc;

    size_t cyclic_obj_alloc_at_trace;

    size_t current_candidate_check_index;

    // LLVM pre-computed records
    SyliStackMap_Record_Entry* stackmap_record_entry;
    size_t stackmap_record_entry_len;

} Syli_state;

// ========================
// Thread-local state
// ========================

#if defined(__cplusplus)
#define SYLI_TLS thread_local
#elif defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
#define SYLI_TLS _Thread_local
#else
#define SYLI_TLS __thread
#endif

#define INITIAL_CANDIDATE_INDEX (-1)

// Thread-local state declaration
extern SYLI_TLS Syli_state syli_state;

// Initialize runtime system
void syli_state_init();
void syli_state_destroy();

// ========================
// Allocation
// ========================

// ARC allocations
Object* syli_state_alloc_object(object_header_t header, size_t length);

// ========================
// Garbage collection
// ========================

void syli_state_gc_tracing(void);
void syli_state_gc_releasing(void);

static inline void syli_state_gc_cycle()
{
    syli_state.tracing_budget   = syli_state.BUDGET_GC_TRACING;
    syli_state.releasing_budget = syli_state.BUDGET_GC_RELEASING;

    syli_state.checking_budget = syli_state.BUDGET_GC_CHECKING;

    syli_state_gc_releasing();
    syli_state_gc_tracing();
}

#endif // SYLI_STATE_H
