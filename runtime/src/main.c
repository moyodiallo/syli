#include "syli/syli_state.h"

extern int syli_startup_program();

int main(int argc, char** argv)
{

    // TODO: argv will be copy/initialized for the syli language. 

    syli_state_init();
    syli_startup_program();
}
