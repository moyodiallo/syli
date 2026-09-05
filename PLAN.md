# Syli Plan

## Language Level
These are objectifs to reach but they are not fixed and could change or being improved.

- [ ] Core Language
    - immediates:
      - int32, int64, float, int8, unit, int16, bool, str, char
    - operators
    - primitive functions
    - function/closure 
    - condition
    - let bind
    - simple ffi C
    - record
    - pattern matching
    - variant
    - array
    - string
    - char
    - loop
    - forIn
    - traits
    - loop
    - forIn

- [ ] Module system
    - signature
    - structure
    - a .sy file as a module
    - compilation unit
        - syi generate smi (compiled module interface)
        - sy generate symo (compile module object), symi, symg (generics), syml (inlinable)

- [ ] Exceptions / Error handling
    - try catch
    - raise

- [ ] Std library (modules)

- [ ] Traits patterns
      - list:  #[]   #[x]       #[x;y]
      - array: #[,]  #[x,]      #[x,y]
      - set:   #{;}  #{x}       #{x;y}
      - map:   #{}   #{k->v}    #{k1->v1;k2->v2}

    ('#' to avoid the confusion with builtin type because of the type inference)

- [ ] Dyn Trait

- [ ] Algebraic Effect handlers

- [ ] Domains (Arc object vs Rc object local thread)
    - threads TLS domains
    - ownership(move) around thread boundaries
    - introduce arc and mutex annotations:
        - array variant, record : @arc array, @mutex array
        - custom obj (ffi)
    - the runtime will be improved to support more thread.
        
## Runtime level

- [X] Rc system single thread
- [X] single thread handle cyclic with tracing fallback
- [ ] Support variant tag
- [ ] Exception support
- [ ] Fibers for algebraic effect handlers
- [ ] Domains threads support