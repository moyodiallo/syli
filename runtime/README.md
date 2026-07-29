# Runtime — Syli Runtime System

A high-performance runtime for the Syli programming language, implemented in C.

> [!WARNING]
> The benchmark are not realworld usage, it is for validating the runtime.

## Runtime

### GC — reference counting + tracing with cycle detection

Two independent incremental state machines, each with its own worklist and budget:

- **Releasing**: processes the refcount-zero waitlist. Traverses reference graphs, decrements child refcounts, and frees objects.
- **Tracing** (`Sy_Tracing`): 2-color mark from stack roots. The tracing flag guarantees each object is processed at most once per tracing phase. Iterates the tracing worklist; the mutations worklist captures unmarked children of objects modified by write barriers during tracing.
`syli_rt_gc_cycle()` sets budgets for both phases and calls them (releasing → tracing). Each phase is incremental — it processes a budgeted number of objects per invocation and returns to idle when its worklist is empty.


### Makefile

There is a `Makefile`, which you could use `make` command to build and run the tests.

### Allocator variants

The runtime supports pluggable memory allocators (mutually exclusive, one per build):

| Option | Allocator | Origin |
|---|---|---|
| (default) | `malloc`/`free` | System (glibc) |
| `-DUSE_MIMALLOC=ON` | mimalloc | Microsoft |
| `-DUSE_TCMALLOC=ON` | tcmalloc | Google |
| `-DUSE_JEMALLOC=ON` | jemalloc | Facebook |

```bash
# mimalloc build
cmake -S . -B cmake-allocators/mimalloc -DCMAKE_BUILD_TYPE=Release -DUSE_MIMALLOC=ON
cmake --build cmake-allocators/mimalloc -j

# tcmalloc build
cmake -S . -B cmake-allocators/tcmalloc -DCMAKE_BUILD_TYPE=Release -DUSE_TCMALLOC=ON
cmake --build cmake-allocators/tcmalloc -j

# jemalloc build
cmake -S . -B cmake-allocators/jemalloc -DCMAKE_BUILD_TYPE=Release -DUSE_JEMALLOC=ON
cmake --build cmake-allocators/jemalloc -j

# Compare all allocators
./build_all_allocators.sh
./compare_allocators.sh
```

## File Layout

```
runtime/
├── src/                  # Source files
├── include/syli/         # Public headers
├── tests/                # Unit tests and benchmarks
├── compat/               # Compatibility helpers
├── CMakeLists.txt
├── build_all_allocators.sh
├── compare_allocators.sh
├── run_bench.sh
├── perf.sh
└── run_test.sh
```

## Building

Requires CMake 3.20+ and a C11 compiler (GCC 10+, Clang 17+).

```bash
# Release build
cmake -S . -B cmake-build -G "Ninja Multi-Config"
cmake --build cmake-build --config Release -j

# Run benchmarks
./cmake-build/Release/bench_gc

# Run tests
cmake --build cmake-build --config Release -j --target test
```

### Sanitizers

```bash
cmake -S . -B cmake-build -G "Ninja Multi-Config" -DENABLE_ASAN=ON
cmake --build cmake-build --config Debug -j
```
