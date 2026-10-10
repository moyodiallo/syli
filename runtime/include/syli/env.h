#ifndef SYLI_ENV_H
#define SYLI_ENV_H

#include <stdint.h>

#define DEFAULT_GC_RELEASE_THRESHOLD            0
#define DEFAULT_MEM_CYCLIC_OBJ_THRESHOLD        (512*1024)
#define DEFAULT_GC_CANDIDATES_RATIO_THRESHOLD   0.2

typedef struct {
    uint64_t syli_gc_mem_cyclic_obj_threshold;
    double syli_gc_candidates_ratio_threshold;
    uint64_t syli_gc_release_threshold;

} Syli_Env;

extern Syli_Env syli_env;

void syli_load_env();

#endif