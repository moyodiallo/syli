#include "syli/gc_helpers.h"
#include "syli/gc_roots.h"
#include "syli/object.h"
#include "syli/syli_state.h"

#include <libunwind.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern unsigned char __start_llvm_stackmaps[] __attribute__((weak));
extern unsigned char __stop_llvm_stackmaps[] __attribute__((weak));

#define STACKMAP_VERSION 3

enum {
    LOC_REGISTER      = 1,
    LOC_DIRECT        = 2,
    LOC_INDIRECT      = 3,
    LOC_CONSTANT      = 4,
    LOC_CONSTANTINDEX = 5,
};

void syli_rt_stackmap_check_version(void)
{
    unsigned char* start = __start_llvm_stackmaps;
    unsigned char* stop  = __stop_llvm_stackmaps;
    if (syli_rt_stackmap_supported(start, stop))
        return;
    fprintf(stderr,
        "clang version not supported: stackmap version %u (expected %d)\n",
        (unsigned)((const SyliStackMap_Header*)start)->version,
        STACKMAP_VERSION);
    exit(1);
}

int syli_rt_stackmap_supported(
    const unsigned char* start, const unsigned char* stop)
{
    if (!start || !stop || start == stop)
        return 1; // No section is fine
    return ((const SyliStackMap_Header*)start)->version == STACKMAP_VERSION;
}

static SyliStackMap_Record* advance_record(SyliStackMap_Record* record)
{
    SyliStackMap_Location* locations = (SyliStackMap_Location*)(record + 1);
    unsigned char* p = (unsigned char*)(locations + record->num_locations);

    if ((record->num_locations * sizeof(SyliStackMap_Location)) % 8 == 4)
        p += 4;

    uint16_t num_liveouts;
    memcpy(&num_liveouts, p + 2, sizeof(num_liveouts));
    p += 4 + 4 * num_liveouts;

    if ((4 * num_liveouts + 4) % 8 == 4)
        p += 4;

    return (SyliStackMap_Record*)p;
}

void syli_build_stackmap_record_entry(const unsigned char* start)
{
    if (syli_state.stackmap_record_entry != NULL)
        return;

    SyliStackMap_Header* headers     = (SyliStackMap_Header*)start;
    SyliStackMap_Function* functions = (SyliStackMap_Function*)(headers + 1);
    SyliStackMap_Record* records
        = (SyliStackMap_Record*)((unsigned char*)(functions
                                     + headers->num_functions)
            + (size_t)headers->num_constants * 8);

    syli_state.stackmap_record_entry_len = headers->num_records;
    syli_state.stackmap_record_entry     = (SyliStackMap_Record_Entry*)calloc(
        headers->num_records, sizeof(SyliStackMap_Record_Entry));

    if (syli_state.stackmap_record_entry == NULL) {
        syli_state.stackmap_record_entry_len = 0;
        return;
    }

    uint64_t index                      = 0;
    SyliStackMap_Record* current_record = records;

    for (size_t i = 0; i < headers->num_functions; i++) {

        SyliStackMap_Function* function = &functions[i];
        for (size_t j = 0; j < function->num_records; j++) {

            SyliStackMap_Record* record = current_record;
            SyliStackMap_Location* locations
                = (SyliStackMap_Location*)(record + 1);

            SyliStackMap_Record_Entry entry;
            entry.pc        = function->addr + record->instr_offset;
            entry.record    = record;
            entry.locations = locations;
            syli_state.stackmap_record_entry[index++] = entry;

            current_record = advance_record(record);
        }
    }
}

SyliStackMap_Record_Entry syli_lookup_record_entry(uint64_t pc)
{
    assert(syli_state.stackmap_record_entry != NULL);

    int high;
    int low;

    low  = 0;
    high = syli_state.stackmap_record_entry_len;

    SyliStackMap_Record_Entry entry;

    while (low < high) {

        int mid = low + (high - low) / 2;
        entry   = syli_state.stackmap_record_entry[mid];

        if (entry.pc == pc) {
            return entry;
        }

        if (pc < entry.pc) {
            high = mid;
        } else {
            low = mid + 1;
        }
    }

    entry.pc        = INTPTR_MAX;
    entry.record    = NULL;
    entry.locations = NULL;
    return entry;
}

static uintptr_t get_register_value(unw_cursor_t* cursor, unsigned dwarf)
{
    unw_word_t value;
    if (unw_get_reg(cursor, dwarf, &value))
        return 0;
    return (uintptr_t)value;
}

static uintptr_t decode_location(
    unw_cursor_t* cursor, const SyliStackMap_Location loc)
{
    uintptr_t base;

    switch (loc.kind) {

    case LOC_REGISTER:
        return get_register_value(cursor, loc.dwarf_reg);

    case LOC_DIRECT:
        base = get_register_value(cursor, loc.dwarf_reg);
        if (!base)
            return 0;
        return base + loc.offset;

    case LOC_INDIRECT:
        base = get_register_value(cursor, loc.dwarf_reg);
        if (!base)
            return 0;
        return *(uintptr_t*)(base + loc.offset);

    default:
        return 0;
    }
}

void syli_rt_collect_stack_roots(void)
{
    unsigned char* start = __start_llvm_stackmaps;
    unsigned char* stop  = __stop_llvm_stackmaps;
    if (!start || !stop || start == stop)
        return;

    if (syli_state.stackmap_record_entry == NULL)
        syli_build_stackmap_record_entry(start);

    assert(syli_state.stackmap_record_entry != NULL);
    if (syli_state.stackmap_record_entry == NULL)
        return;

    unw_context_t uc;
    unw_cursor_t cur;

    unw_getcontext(&uc);
    unw_init_local(&cur, &uc);

    while (unw_step(&cur) > 0) {

        unw_word_t ip;
        if (unw_get_reg(&cur, UNW_REG_IP, &ip))
            continue;
        const SyliStackMap_Record_Entry entry
            = syli_lookup_record_entry((uintptr_t)ip);

        if (!entry.locations || !entry.record)
            continue;

        for (unsigned i = 0; i < entry.record->num_locations; i++) {
            uintptr_t value = decode_location(&cur, entry.locations[i]);
            if (!value)
                continue;
            obj_ptr obj = (obj_ptr)value;
            gc_tracing_worklist_push(obj);
        }
    }
}
