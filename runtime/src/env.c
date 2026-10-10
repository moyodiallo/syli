#include "syli/env.h"
#include <stdlib.h>

Syli_Env syli_env;

void syli_load_env()
{
    Syli_Env env;

    // Default env
    env.syli_gc_release_threshold        = DEFAULT_GC_RELEASE_THRESHOLD;
    env.syli_gc_mem_cyclic_obj_threshold = DEFAULT_MEM_CYCLIC_OBJ_THRESHOLD;
    env.syli_gc_candidates_ratio_threshold
        = DEFAULT_GC_CANDIDATES_RATIO_THRESHOLD;

    const char* env_mem_cyclic_obj_threshold
        = getenv("SYLI_GC_MEM_CYCLIC_OBJ_THRESHOLD");
    if (env_mem_cyclic_obj_threshold != NULL) {
        char* end = NULL;
        unsigned long long value
            = strtoull(env_mem_cyclic_obj_threshold, &end, 10);
        if (end != env_mem_cyclic_obj_threshold && *end == '\0') {
            env.syli_gc_mem_cyclic_obj_threshold = value;
        }
    }

    const char* env_candidates_ratio_threshold
        = getenv("SYLI_GC_CANDIDATES_RATIO_THRESHOLD");
    if (env_candidates_ratio_threshold != NULL) {
        char* end    = NULL;
        double value = strtod(env_candidates_ratio_threshold, &end);
        if (end != env_candidates_ratio_threshold && *end == '\0') {
            env.syli_gc_candidates_ratio_threshold = value;
        }
    }

    const char* env_releasing_threshold = getenv("SYLI_GC_RELEASING_THRESHOLD");
    if (env_releasing_threshold != NULL) {
        char* end                = NULL;
        unsigned long long value = strtoull(env_releasing_threshold, &end, 10);
        if (end != env_releasing_threshold && *end == '\0') {
            env.syli_gc_release_threshold = value;
        }
    }

    syli_env = env;
}
