#ifndef IMMEDIATE_H
#define IMMEDIATE_H

#include "syli/object.h"

#include <stdint.h>

void syli_print_i64(int64_t value);
void syli_print_f64(double value);
void syli_print_string(obj_ptr ptr);
void syli_print_char(int value);
void syli_print_gc_state(void);

#endif // IMMEDIATE_H
