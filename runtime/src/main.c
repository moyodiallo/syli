#include "syli/syli_state.h"
#include "syli/env.h"

extern int syli_startup_program(void);

int main(int argc, char **argv) {
    load_env();
    syli_state_init();
    return syli_startup_program();
}
