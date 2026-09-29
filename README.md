# Syli

[![CI](https://github.com/syli-lang/syli/actions/workflows/ci.yml/badge.svg)](https://github.com/syli-lang/syli/actions/workflows/ci.yml)

## Overview

Syli is a general-purpose programming language with a functional core, statically typed and ML-like syntax. The runtime is a based on refcount memory management system with [**ownership tag pointers**](doc/ownership.md) (release happens on only tagged pointers). The closure concept is based on a closure call graph that uses **Ball-Larus** algorithm to annotate the closure nodes in order to allow polymorphism with monomorphization.

The goal of the language is to have expressivity, low latency and high performance, It is compiled into native code.



This language is not doing something totally new, it is trying to hold on giants, to borrow from languages that are mature and are doing amazing things for years.

> [!CAUTION]
> The project is under development, it is not ready for production yet. For contributors: the tests are good indicative of the progression in the language, there could be inactive code inside the project as a specification.

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

## Example

```
  type list = Nil | Cons of (i64, list)
  
  let rec insert x xs =
    match xs with
    | Nil -> Cons (x, Nil)
    | Cons (y, ys) ->
        if x < y then
          Cons (x, Cons (y, ys))
        else
          Cons (y, insert x ys)
  
  let rec sort xs =
    match xs with
    | Nil -> Nil
    | Cons (x, rest) -> insert x (sort rest)
  
  let main () =
    let xs = Cons (3, Cons (1, Cons (5, Cons (2, Cons (4, Nil)))))
    sort xs
  
  let _ = main ()
```


## Benchmarks
Running the bechmarks, make sure `hyperfine` is installed.
```
$ ./bench/run.sh 
```

## PLAN

See [PLAN.md](PLAN.md)

## Contributions

See [CONTRIBUTING](CONTRIBUTING.md)

## License

Licensed under both

* Apache License, Version 2.0 ([LICENSE-APACHE](LICENSE-APACHE) or <http://www.apache.org/licenses/LICENSE-2.0>)
* MIT license ([LICENSE-MIT](LICENSE-MIT) or <http://opensource.org/licenses/MIT>)
