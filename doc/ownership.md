## Ownership with tag pointer

This **memory management** system concept is based on **reference counting** and combined with **ownership** encoded on the object pointers.

---

### 1. The Core Idea

Every object pointer carries a **one‑bit tag** in its lowest bit:

- **`Own_Ref`** (bit = 1) – owns the object; responsible for decrementing the reference count on `release`.
- **`Borrow_Ref`** (bit = 0) – a non‑owning view; `release` is a no‑op.

Variables **default to `Own_Ref`** (freshly created objects, results of `share`, incoming owned parameters).  
A `Borrow_Ref` is only produced by `borrow()` or by a local `get` that returns a borrow.

**“Viewership is on one view”** – borrows never track counts; the object stays alive because the owning `Own_Ref`(s) outlive them. Liveness analysis statically guarantees an owner is never released while any borrow is still alive.

---

### 2. The Five Primitives

| Operation | Meaning | Input → Output | RC Change |
|:---|:---|:---|:---|
| `borrow(x)` | Create a borrowed view. | Any → `Borrow_Ref` | None |
| `transfer(x)` | Move a reference unchanged. | Own → Own, Borrow → Borrow | None |
| `own(x)` | Promote to `Own_Ref` if needed. | Borrow → Own (RC++)<br>Own → Own (no‑op) | Only if Borrowed |
| `share(x)` | Create an independent owner. | Any → `Own_Ref` | **Always** RC++ |
| `release(x)` | Drop this reference. | Own → RC-- (free if 0)<br>Borrow → nothing | Only if Owned |

The algorithms could be seeing at the end of the document.

---

### 3. Pass 1 – Liveness‑Driven Insertion (Safe but Conservative)

This pass only looks at whether a variable is **live** or **dead** after the current statement.  
No escape, no lifetime containment – just correct, always‑safe placement of ownership operations.

#### Function call `callee(x)`

| `x` liveness | Operation | Release `x`? |
|:---|:---|---|
| **Live** after call | `callee(borrow(x))` | Could be released after |
| **Dead** after call | `callee(transfer(x))` | No, responsibility moved |

#### `v = get(obj, f)`

| `v` liveness | Operation |
|:---|:---|
| **Live** after | `v = share(raw_get(obj, f))` |
| **Dead** after | `v = borrow(raw_get(obj, f))` |

#### `set(obj, f, val)`

1. `release(raw_get(obj, f))` – always release the old field value.
2. Then:

| `val` liveness | Operation | Release `val` ? |
|:---|:---|---|
| **Dead** after | `raw_set(obj, f, own(val))` | No,responsability moved |
| **Live** after | `raw_set(obj, f, share(val))` | Yes, could be release |

#### Scope exit
`release(var)` at the end of every variable’s live range.

---

### 4. Pass 2 – Escape & Lifetime Reduction (Optimisation)

This pass uses functions **escape analysis** and **lifetime containment** to downgrade expensive operations (`share`, `own`) into zero‑cost ones (`borrow`, `transfer`) wherever it’s safe.

#### `v = get(obj, f)` reduction

| Condition | Replacement | RC saved |
|:---|:---|:---|
| `v` does **not escape** **and** `obj` **outlives** `v` | `share` → `borrow` | removes RC++ |
| `v` escapes **and** `obj` does not escape |`v = share(raw_get(obj, f))` becomes `v = own(raw_get(obj, f));`<br>`raw_set(obj, f, borrow(v));` | if field was Owned, avoids RC++ (share would have incremented) |
| `v` does not escapes **and** v outlive `obj` |`v = share(raw_get(obj, f))` becomes `v = transfer(raw_get(obj, f));`<br>`raw_set(obj, f, borrow(v));` | removes RC++ |

#### `set(obj, f, val)` reduction

| `val` liveness | `obj` escapes? | Lifetime relation | Replacement | RC change | Release `val`? |
|:---|:---|:---|:---|:---|:---|
| **Dead** | No | any | `own(val)` → **`transfer(val)`** | 0 | **No** – dead, responsibility moved to field |
| **Dead** | Yes | (any) | Keep **`own(val)`** | if borrowed | **No** |
| **Live** | No | `obj` dies before `val` | `share(val)` → **`borrow(val)`** | 0 | **Yes** – `val` stays alive, released later |
| **Live** | No | `obj` outlives `val` | `share(val)` → **`transfer(val)`** | 0 | **No**- reponsability moves |
| **Live** | Yes | `val` also | Keep **`share(val)`** | RC++ | **Yes** |
| **Live** | Yes | `val` does not escape | `share(val)` → **`own(val)`**| RC++ if val is borrowed | **No**-responsability moves |

---

Any other optimization is possible when if it safe do so.

### 5. Soundness Guarantees

- **Liveness** ensures an `Own_Ref` is never released while any `Borrow_Ref` derived from it is still alive. A borrow extends the live range of its source.
- **Transitive cascading frees** are safe: when an object dies, its destructor releases its fields, possibly freeing other objects. Liveness of any borrow into the graph keeps the root owner alive, hence the whole chain stays alive.
- No runtime borrow counts – the bit handles it all.

---

### 6. Potential performance gain

- **Local reads**, **dead‑value stores**, and **argument passing** become `borrow`/`transfer` – zero RC ops.
- `share` (the only unconditional RC++) appears **only** when two live references must exist independently and neither can safely borrow from the other.
- Cycles could be reduced because of `borrowed` pointers



## The api operations

Here are the algorithms with explicit bit operations.

---

### `borrow(x)` — Create a borrowed view

```
borrow(x):
    return x & ~1                 // clear bit 0 → Borrow_Ref
```

---

### `transfer(x)` — Move unchanged

```
transfer(x):
    return x                      // no bit change, pass through
```

---

### `own(x)` — Ensure ownership responsibility

```
own(x):
    if (x & 1) == 0:              // test bit 0 → Borrow_Ref
        ptr = x & ~1              // untag to get object pointer
        obj_atomic_inc(rc)           
        return x | 1              // set bit 0 → Own_Ref
    else:
        return x                  // already Own_Ref, no-op
```

---

### `share(x)` — Create an independent owner

```
share(x):
    ptr = x & ~1                  // untag to get object pointer
    obj_atomic_inc(ptr)
    return x | 1                  // set bit 0 → Own_Ref
```

---

### `release(x)` — Drop this reference

```
release(x):
    if (x & 1) == 1:              // test bit 0 → Own_Ref
        ptr = x & ~1              // untag
        new_rc = obj_atomic_dec(ptr)
        if new_rc == 0:
            free(ptr)              // free the whole block (rc + object)
    else:
        nothing                   // Borrow_Ref, bit 0 is 0
```

---

### `reuse_if(x)` — Mutate in place if unique

```
reuse_if(x):
    if (x & 1) == 1:              // test bit 0 → Own_Ref
        ptr = x & ~1              // untag
        if obj_atomic_ref(ptr) == 1:
            return x              // yes, safe to mutate in place
    size = object_size(x)
    new_obj = alloc_object(size)    // new Own_Ref, RC = 1
    release(x)                    // drop old reference
    return new_obj
```


## Conclusion

The optimization could be more, whenever it is safe to optimize. `reuse` technique in this article [Counting Immutable Beans](https://arxiv.org/pdf/1908.05647) may fit on this concept. And this concept could push further those two articles:
- [Counting Immutable Beans](https://arxiv.org/pdf/1908.05647)
- [Perceus: Garbage Free Reference Counting with Reuse](https://dl.acm.org/doi/epdf/10.1145/3453483.3454032)