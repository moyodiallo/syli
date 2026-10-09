#include "syli/syli_foreign_primitives.h"
#include "syli/gc_helpers.h"
#include "syli/object.h"
#include "syli/syli_state.h"
#include <inttypes.h>
#include <stdint.h>
#include <stdio.h>

void syli_print_i64(int64_t value) { printf("%" PRId64, value); }

void syli_print_f64(double value) { printf("%f", value); }

/* The bytes length is recovered using the marker in the last byte.

Example: c"helloworld\00\00\00\00\00\05"
    the marker is 5, the length words is encoded inside the header, the
    formula would be:

    length_words(from header) * size_word - marker(last byte) - 1

A technique from OCaml string representation. */
static size_t syli_string_bytes_length(Object* obj)
{
    assert(obj != NULL);
    assert(syli_object_is_mono_imm(obj));
    size_t word_bytes = syli_object_mono_length(obj) * sizeof(uint64_t);
    assert(word_bytes > 0);
    const unsigned char* data = (const unsigned char*)syli_object_data(obj);
    size_t marker             = data[word_bytes - 1];
    assert(marker < sizeof(uint64_t));
    return word_bytes - 1 - marker;
}

void syli_print_string(obj_ptr ptr)
{
    Object* obj      = syli_object_of_obj_ptr(ptr);
    const char* data = (const char*)syli_object_data(obj);
    fwrite(data, 1, syli_string_bytes_length(obj), stdout);
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
    case Checking_Cyclic_Candidates:
        return "Checking";
    case Releasing_Unreachable:
        return "Releasing_Unreachable";
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
           "candidates=%zu cyclic-mem=%zu cyclic-alloc=%zu "
           "cyclic-dealloc=%zu obj-alloc=%zu obj-dealloc=%zu traced=%zu "
           "freed=%zu release-waitlist=%zu tracing-worklist=%zu]\n",
        tracing_state_name(syli_state.tracing_state),
        releasing_state_name(syli_state.releasing_state),
        syli_state.tracing_generations,
        vector_size_CyclicCandidate(&syli_state.cyclic_candidates),
        gc_current_cyclic_mem(), syli_state.cyclic_mem_alloc,
        syli_state.cyclic_mem_dealloc, syli_state.cyclic_obj_alloc,
        syli_state.cyclic_obj_dealloc, syli_state.total_objects_traced,
        syli_state.total_objects_memory_freed,
        vector_size_obj_ptr(&syli_state.releasing_waitlist),
        vector_size_obj_ptr(&syli_state.tracing_worklist));
}
