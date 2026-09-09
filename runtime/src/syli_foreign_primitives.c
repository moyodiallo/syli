#include "syli/syli_foreign_primitives.h"
#include "syli/object.h"
#include "syli/syli_state.h"
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

void syli_print_i64(int64_t value) { printf("%" PRId64, value); }

void syli_print_f64(double value) { printf("%f", value); }

void syli_print_string(obj_ptr ptr)
{
    Object* obj      = syli_object_of_obj_ptr(ptr);
    size_t len       = syli_object_mono_length(obj);
    const char* data = (const char*)syli_object_data(obj);
    fwrite(data, 1, len, stdout);
}

void syli_print_char(int value) { fputc(value, stdout); }

static const char* tracing_state_name(Tracing_state_machine state)
{
    switch (state) {
    case Tracing_Idle:
        return "Idle";
    case Tracing:
        return "Tracing";
    case Mutation_Prepare:
        return "Mutation_Prepare";
    case Checking_Suspect_Lost_Cycle:
        return "Checking";
    }
    return "?";
}

static const char* releasing_state_name(Releasing_state_machine state)
{
    switch (state) {
    case Releasing_Idle:
        return "Idle";
    case Releasing:
        return "Releasing";
    }
    return "?";
}

void syli_print_gc_state(void)
{
    printf("GC[tracing_state=%s releasing_state=%s generations=%zu "
           "suspects=%zu suspect-notif=%zu traced=%zu freed=%zu "
           "release-waitlist=%zu tracing-worklist=%zu]\n",
        tracing_state_name(syli_state.tracing_state),
        releasing_state_name(syli_state.releasing_state),
        syli_state.tracing_generations,
        vector_size_Suspected(&syli_state.suspect_lost_cycle),
        syli_state.suspect_objects_notifications,
        syli_state.total_objects_traced, syli_state.total_objects_memory_freed,
        vector_size_obj_ptr(&syli_state.releasing_waitlist),
        vector_size_obj_ptr(&syli_state.tracing_worklist));
}
