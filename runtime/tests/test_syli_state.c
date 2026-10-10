#define _DEFAULT_SOURCE
#include <assert.h>
#include <stdbool.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "syli/gc_helpers.h"
#include "syli/object.h"
#include "syli/syli_state.h"

#pragma GCC diagnostic ignored "-Wunused-but-set-variable"

void test_state_init()
{
    printf("Test 1: syli_state_init()\n");

    syli_state_init();

    // Check thresholds
    assert(syli_state.THRESHOLD_MEM_CYCLIC_OBJ
        == DEFAULT_MEM_CYCLIC_OBJ_THRESHOLD);
    assert(syli_state.THRESHOLD_CANDIDATES_RATIO
        == DEFAULT_GC_CANDIDATES_RATIO_THRESHOLD);
    assert(
        syli_state.THRESHOLD_RELEASING_BUCKET == DEFAULT_GC_RELEASE_THRESHOLD);

    // Check budgets
    assert(syli_state.BUDGET_GC_TRACING == 2 * BUDGET_BATCH_SIZE);
    assert(syli_state.BUDGET_GC_RELEASING == 5 * BUDGET_BATCH_SIZE);
    assert(syli_state.BUDGET_GC_CHECKING == 3 * BUDGET_BATCH_SIZE);

    // Check budget counters start at 0
    assert(syli_state.tracing_budget == 0);
    assert(syli_state.releasing_budget == 0);
    assert(syli_state.checking_budget == 0);

    // Check GC worklists are initialized (empty)
    assert(vector_size_obj_ptr(&syli_state.tracing_worklist) == 0);
    assert(vector_empty_obj_ptr(&syli_state.tracing_worklist) == true);
    assert(vector_size_obj_ptr(&syli_state.tracing_mutations_worklist) == 0);
    assert(
        vector_empty_obj_ptr(&syli_state.tracing_mutations_worklist) == true);
    assert(vector_size_obj_ptr(&syli_state.releasing_worklist) == 0);
    assert(vector_empty_obj_ptr(&syli_state.releasing_worklist) == true);
    assert(vector_size_obj_ptr(&syli_state.releasing_waitlist) == 0);
    assert(vector_empty_obj_ptr(&syli_state.releasing_waitlist) == true);
    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 0);
    assert(vector_empty_CyclicCandidate(&syli_state.cyclic_candidates) == true);

    // Check stats start at 0
    assert(syli_state.releasing_steps == 0);
    assert(syli_state.tracing_steps == 0);
    assert(syli_state.mutation_steps == 0);
    assert(syli_state.checking_steps == 0);
    assert(syli_state.total_objects_traced == 0);
    assert(syli_state.total_objects_released == 0);
    assert(syli_state.total_objects_memory_freed == 0);

    assert(syli_state.generation_tracing == 0);

    // Check tracing state
    assert(syli_state.tracing_current_bit_mark == 0);
    assert(syli_state.tracing_generations == 0);

    // Check state machines
    assert(syli_state.tracing_state == Tracing_Idle);
    assert(syli_state.releasing_state == Releasing_Idle);

    // Check cyclic gauges and check indices
    assert(syli_state.cyclic_mem_alloc == 0);
    assert(syli_state.cyclic_mem_dealloc == 0);
    assert(syli_state.cyclic_obj_alloc == 0);
    assert(syli_state.cyclic_obj_dealloc == 0);
    assert(syli_state.current_candidate_check_index == 0);

    syli_state_destroy();
    printf("✓ syli_state_init() initializes all fields correctly\n\n");
}

void test_state_destroy()
{
    printf("Test 2: syli_state_destroy()\n");

    syli_state_init();

    // Verify state is usable before destroy
    assert(syli_state.tracing_worklist.chunks != NULL);

    syli_state_destroy();

    // After destroy, vectors should have chunks set to NULL
    assert(syli_state.tracing_worklist.chunks == NULL);
    assert(syli_state.tracing_worklist.chunk_count == 0);
    assert(syli_state.tracing_worklist.total_elements == 0);

    assert(syli_state.tracing_mutations_worklist.chunks == NULL);
    assert(syli_state.tracing_mutations_worklist.chunk_count == 0);
    assert(syli_state.tracing_mutations_worklist.total_elements == 0);

    assert(syli_state.releasing_worklist.chunks == NULL);
    assert(syli_state.releasing_worklist.chunk_count == 0);
    assert(syli_state.releasing_worklist.total_elements == 0);

    assert(syli_state.releasing_waitlist.chunks == NULL);
    assert(syli_state.releasing_waitlist.chunk_count == 0);
    assert(syli_state.releasing_waitlist.total_elements == 0);

    assert(syli_state.cyclic_candidates.chunks == NULL);
    assert(syli_state.cyclic_candidates.chunk_count == 0);
    assert(syli_state.cyclic_candidates.total_elements == 0);

    printf("✓ syli_state_destroy() cleans up all resources\n\n");
}

void test_state_init_destroy_cycle()
{
    printf("Test 3: Multiple init/destroy cycles\n");

    // Cycle 1
    syli_state_init();
    assert(syli_state.tracing_worklist.chunks != NULL);
    syli_state_destroy();
    assert(syli_state.tracing_worklist.chunks == NULL);

    // Cycle 2
    syli_state_init();
    assert(syli_state.tracing_worklist.chunks != NULL);
    syli_state_destroy();
    assert(syli_state.tracing_worklist.chunks == NULL);

    // Cycle 3
    syli_state_init();
    assert(vector_empty_obj_ptr(&syli_state.tracing_worklist) == true);
    assert(vector_empty_obj_ptr(&syli_state.releasing_worklist) == true);
    syli_state_destroy();

    printf("✓ Multiple init/destroy cycles work correctly\n\n");
}

void test_state_gc_cycle()
{
    printf("Test 4: syli_state_gc_cycle()\n");

    syli_state_init();

    // Set budget counters to non-zero to verify they get reset
    syli_state.tracing_budget   = -1;
    syli_state.releasing_budget = -1;
    syli_state.checking_budget  = -1;

    // Call gc_cycle which resets budgets
    syli_state_gc_cycle();

    // Budgets should be reset
    assert(syli_state.tracing_budget == (int)syli_state.BUDGET_GC_TRACING);
    assert(syli_state.releasing_budget == (int)syli_state.BUDGET_GC_RELEASING);
    assert(syli_state.checking_budget == (int)syli_state.BUDGET_GC_CHECKING);

    syli_state_destroy();
    printf("✓ syli_state_gc_cycle() resets budgets\n\n");
}

void test_state_worklist_operations()
{
    printf("Test 5: GC worklist operations\n");

    syli_state_init();

    // Verify all worklists are empty initially
    assert(vector_empty_obj_ptr(&syli_state.tracing_worklist) == true);
    assert(
        vector_empty_obj_ptr(&syli_state.tracing_mutations_worklist) == true);
    assert(vector_empty_obj_ptr(&syli_state.releasing_worklist) == true);
    assert(vector_empty_obj_ptr(&syli_state.releasing_waitlist) == true);
    assert(vector_empty_CyclicCandidate(&syli_state.cyclic_candidates) == true);

    // Push objects to tracing_worklist using gc_vector_push_back helper
    obj_ptr obj1 = (obj_ptr)0x1234;
    obj_ptr obj2 = (obj_ptr)0x5678;
    obj_ptr obj3 = (obj_ptr)0x9ABC;

    gc_vector_push_back(&syli_state.tracing_worklist, obj1);
    gc_vector_push_back(&syli_state.tracing_worklist, obj2);
    gc_vector_push_back(&syli_state.tracing_worklist, obj3);
    assert(vector_size_obj_ptr(&syli_state.tracing_worklist) == 3);

    // Pop and verify
    obj_ptr popped = gc_vector_pop_back(&syli_state.tracing_worklist);
    assert(popped == obj3);
    popped = gc_vector_pop_back(&syli_state.tracing_worklist);

    popped = gc_vector_pop_back(&syli_state.tracing_worklist);
    assert(popped == obj1);
    assert(vector_size_obj_ptr(&syli_state.tracing_worklist) == 0);

    // Push to releasing_worklist
    gc_vector_push_back(&syli_state.releasing_worklist, obj1);
    gc_vector_push_back(&syli_state.releasing_worklist, obj2);
    assert(vector_size_obj_ptr(&syli_state.releasing_worklist) == 2);
    popped = gc_vector_pop_back(&syli_state.releasing_worklist);

    popped = gc_vector_pop_back(&syli_state.releasing_worklist);
    assert(popped == obj1);
    assert(vector_size_obj_ptr(&syli_state.releasing_worklist) == 0);

    // Push to waitlists
    gc_vector_push_back(&syli_state.releasing_waitlist, obj1);

    popped = gc_vector_pop_back(&syli_state.releasing_waitlist);
    assert(popped == obj1);

    // Push to tracing_mutations_worklist
    gc_vector_push_back(&syli_state.tracing_mutations_worklist, obj1);

    popped = gc_vector_pop_back(&syli_state.tracing_mutations_worklist);
    assert(popped == obj1);

    // Cyclic candidate registry (uses CyclicCandidate struct directly)
    CyclicCandidate s1 = { .obj = (obj_ptr)obj1 };
    CyclicCandidate s2 = { .obj = (obj_ptr)obj2 };
    vector_push_back_CyclicCandidate(&syli_state.cyclic_candidates, &s1);
    vector_push_back_CyclicCandidate(&syli_state.cyclic_candidates, &s2);
    assert(vector_size_CyclicCandidate(&syli_state.cyclic_candidates) == 2);
    assert(vector_at_CyclicCandidate(&syli_state.cyclic_candidates, 0)->obj
        == obj1);
    assert(vector_at_CyclicCandidate(&syli_state.cyclic_candidates, 1)->obj
        == obj2);

    syli_state_destroy();
    printf("✓ GC worklist operations work correctly\n\n");
}

void test_state_env_thresholds()
{
    printf("Test 6: GC threshold env overrides\n");

    unsetenv("SYLI_GC_MEM_CYCLIC_OBJ_THRESHOLD");
    unsetenv("SYLI_GC_CANDIDATES_RATIO_THRESHOLD");
    syli_state_init();
    assert(syli_state.THRESHOLD_MEM_CYCLIC_OBJ
        == DEFAULT_MEM_CYCLIC_OBJ_THRESHOLD);
    assert(syli_state.THRESHOLD_CANDIDATES_RATIO
        == DEFAULT_GC_CANDIDATES_RATIO_THRESHOLD);
    syli_state_destroy();

    setenv("SYLI_GC_MEM_CYCLIC_OBJ_THRESHOLD", "1234", 1);
    setenv("SYLI_GC_CANDIDATES_RATIO_THRESHOLD", "0.75", 1);
    syli_state_init();
    assert(syli_state.THRESHOLD_MEM_CYCLIC_OBJ == 1234);
    assert(syli_state.THRESHOLD_CANDIDATES_RATIO == 0.75);
    syli_state_destroy();

    setenv("SYLI_GC_MEM_CYCLIC_OBJ_THRESHOLD", "not-a-number", 1);
    syli_state_init();
    assert(syli_state.THRESHOLD_MEM_CYCLIC_OBJ
        == DEFAULT_MEM_CYCLIC_OBJ_THRESHOLD);
    syli_state_destroy();

    setenv("SYLI_GC_RELEASING_THRESHOLD", "7", 1);
    unsetenv("SYLI_GC_MEM_CYCLIC_OBJ_THRESHOLD");
    unsetenv("SYLI_GC_CANDIDATES_RATIO_THRESHOLD");
    syli_state_init();
    assert(syli_state.THRESHOLD_RELEASING_BUCKET == 7);
    assert(syli_state.THRESHOLD_MEM_CYCLIC_OBJ
        == DEFAULT_MEM_CYCLIC_OBJ_THRESHOLD);
    assert(syli_state.THRESHOLD_CANDIDATES_RATIO
        == DEFAULT_GC_CANDIDATES_RATIO_THRESHOLD);
    syli_state_destroy();

    unsetenv("SYLI_GC_MEM_CYCLIC_OBJ_THRESHOLD");
    unsetenv("SYLI_GC_CANDIDATES_RATIO_THRESHOLD");
    unsetenv("SYLI_GC_RELEASING_THRESHOLD");
    printf("✓ GC threshold env overrides work\n\n");
}

int main()
{
    printf("\033[1;34m=== Running syli_state Tests ===\033[0m\n\n");

    test_state_init();
    test_state_destroy();
    test_state_init_destroy_cycle();
    test_state_gc_cycle();
    test_state_worklist_operations();
    test_state_env_thresholds();

    printf("\033[1;32m=== All syli_state Tests Passed! ===\033[0m\n\n");
    return 0;
}
