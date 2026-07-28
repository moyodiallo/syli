# Syli

[![CI](https://github.com/syli-lang/syli/actions/workflows/ci.yml/badge.svg)](https://github.com/syli-lang/syli/actions/workflows/ci.yml)

## Overview

Syli is a general-purpose programming language with a functional core, statically typed and Pythonic-ML-like syntax. The runtime is a based on refcount memory management system with [ownership](doc/ownership.md) tag pointers (release happens on only tagged pointers). The closure concept is based on a closure call graph that uses **Ball-Larus** algorithm in order to allow polymorphism with monomorphization.

The goal of the language is to have expressivity, low latency and high performance, It is compiled into native code.



This language is not doing something totally new, it is trying to hold on giants, to borrow from languages that are mature and are doing amazing things for years.

> [!CAUTION]
> The project is under development, it is not ready for production yet.

## Building

### System Requirements
- CMake 2.20+
- Clang 17.0+
- LLVM 17.0+

### Install Opam and Dune

Install Opam via [opam](https://opam.ocaml.org/doc/Install.html)

Create an empty switch
```sh
opam create switch syli-lang --empty
```

Install all deps and Dune
```sh
opam install . --deps-only
```

### Setup, build and run all test

Local setup of some env path for the development.
```sh
source setup.sh
```
Build the runtime
```
make -C runtime syliruntime
```
Build and run the tests
```sh
dune build
dune runtest
```

## Examples

```sy
signature:
  extern syli_print_i64 : int64 -> unit = "syli_print_i64"
end
let add x y = x + y
let apply f x = f x
let compose f g x = f (g x)
fn main () =
    let r = compose (add 10) (add 20) 5
    syli_print_i64 r
```

```
$ cat bench/clos4.sy
signature:
  extern syli_print_i64 : int64 -> unit = "syli_print_i64"
end
let rec add_n n x = n + x
let rec apply_n f x n =
  if n == 0 then
    x
  else
    apply_n f (f x) (n - 1)
let rec stress n acc =
  if n == 0 then
    acc
  else
    let f = add_n n
    let r = apply_n f 0 100
    stress (n - 1) (acc + r)
fn main () = syli_print_i64(stress 1000 0)
```


## Benchmarks
Running the bechmarks, make sure `hyperfine` is installed.
```
$ ./bench/run.sh 
Building tak...
Building queens...
Building clos...
Building clos4...

=== tak ===
Benchmark 1: ./tak.exe
  Time (mean ± σ):     387.9 ms ±  13.1 ms    [User: 386.0 ms, System: 1.4 ms]
  Range (min … max):   368.6 ms … 409.6 ms    7 runs
 

=== queens ===
Benchmark 1: ./queens.exe
  Time (mean ± σ):     962.4 µs ± 187.7 µs    [User: 275.5 µs, System: 549.3 µs]
  Range (min … max):   671.4 µs … 1818.7 µs    2132 runs
 

=== clos ===
Benchmark 1: ./clos.exe
  Time (mean ± σ):       1.5 ms ±   0.2 ms    [User: 0.6 ms, System: 0.7 ms]
  Range (min … max):     1.1 ms …   2.4 ms    1796 runs
 

=== clos4 ===
Benchmark 1: ./clos4.exe
  Time (mean ± σ):      1.052 s ±  0.021 s    [User: 1.051 s, System: 0.001 s]
  Range (min … max):    1.026 s …  1.082 s    5 runs
 

=== Memory usage peak ===
  tak      1800 KB
  queens   1936 KB
  clos     1740 KB
  clos4    1788 KB

```

## Roadmap

See [ROADMAP.md](ROADMAP.md)

## Contributions

See [CONTRIBUTING](CONTRIBUTING.md)

## License

Licensed under both

* Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <http://www.apache.org/licenses/LICENSE-2.0>)
* MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)
