#include "syli/syli_state.h"

#include <assert.h>
#include <stdatomic.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "syli/env.h"
#include "syli/gc_helpers.h"
#include "syli/gc_roots.h"
#include "syli/object.h"

SYLI_TLS Syli_state syli_state;

void syli_state_init()
{
    syli_rt_stackmap_check_version();
    syli_load_env();

    // Zero out the entire state to ensure clean initialization
    memset(&syli_state, 0, sizeof(Syli_state));

    syli_state.THRESHOLD_MEM_CYCLIC_OBJ
        = syli_env.syli_gc_mem_cyclic_obj_threshold;
    syli_state.THRESHOLD_CANDIDATES_RATIO
        = syli_env.syli_gc_candidates_ratio_threshold;

    syli_state.THRESHOLD_RELEASING_BUCKET = syli_env.syli_gc_release_threshold;

    // Initialize budgets
    syli_state.BUDGET_GC_TRACING   = 2 * BUDGET_BATCH_SIZE;
    syli_state.BUDGET_GC_RELEASING = 5 * BUDGET_BATCH_SIZE;
    syli_state.BUDGET_GC_CHECKING  = 3 * BUDGET_BATCH_SIZE;

    syli_state.tracing_budget   = 0;
    syli_state.releasing_budget = 0;
    syli_state.checking_budget  = 0;

    // Initialize GC worklists (vectors of GCObject*)
    vector_init_obj_ptr(&syli_state.tracing_worklist);
    vector_init_obj_ptr(&syli_state.tracing_mutations_worklist);
    vector_init_obj_ptr(&syli_state.releasing_worklist);
    vector_init_obj_ptr(&syli_state.releasing_waitlist);

    // Initialize the cyclic candidate registry and its release buffers
    vector_init_CyclicCandidate(&syli_state.cyclic_candidates);
    vector_init_obj_ptr(&syli_state.lost_cycle_worklist);

    // Initialize stats
    syli_state.releasing_steps = 0;
    syli_state.tracing_steps   = 0;
    syli_state.mutation_steps  = 0;
    syli_state.checking_steps  = 0;

    syli_state.total_objects_traced       = 0;
    syli_state.total_objects_released     = 0;
    syli_state.total_objects_memory_freed = 0;

    syli_state.generation_tracing = 0;

    // Initialize tracing state
    syli_state.tracing_current_bit_mark = 0;
    syli_state.tracing_generations      = 0;

    // Initialize state machines
    syli_state.tracing_state   = Tracing_Idle;
    syli_state.releasing_state = Releasing_Idle;

    syli_state.current_candidate_check_index = 0;

    syli_state.stackmap_record_entry     = NULL;
    syli_state.stackmap_record_entry_len = 0;
}

void syli_state_destroy()
{
    // Clean up GC worklists
    vector_destroy_obj_ptr(&syli_state.tracing_worklist);
    vector_destroy_obj_ptr(&syli_state.tracing_mutations_worklist);
    vector_destroy_obj_ptr(&syli_state.releasing_worklist);
    vector_destroy_obj_ptr(&syli_state.releasing_waitlist);

    // Clean up the cyclic candidate registry and its release buffers
    vector_destroy_CyclicCandidate(&syli_state.cyclic_candidates);
    vector_destroy_obj_ptr(&syli_state.lost_cycle_worklist);

    // Clean up stackmap recorded pc
    free(syli_state.stackmap_record_entry);
}
