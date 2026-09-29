Variant pattern matching — SIR lowering.

Pattern match on integer literals:
  $ cat >test_match_int.sy <<EOF
  > let describe (x : i64) =
  >   match x with
  >   | 0 -> 100
  >   | 1 -> 200
  >   | _ -> 300
  > EOF
  $ dune exec sylic -- cir test_match_int.sy
  module Test_match_int :
  functions:
  public fn __init.Test_match_int() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_match_int.describe(%x:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_1:bool = %x:i64 == 1:i64
      cond_br %Sy_cir_var_1:bool, bb1, bb2
  
    bb2:
      %Sy_cir_var_2:bool = %x:i64 == 0:i64
      cond_br %Sy_cir_var_2:bool, bb3, bb4
  
    bb4:
      %Sy_cir_var_0:i64 = move(300:i64)
      goto bb5
  
    bb3:
      %Sy_cir_var_0:i64 = move(100:i64)
      goto bb5
  
    bb1:
      %Sy_cir_var_0:i64 = move(200:i64)
      goto bb5
  
    bb5:
  
      return %Sy_cir_var_0:i64
  end
  
  end

A variant whose constructors are all constant is a plain integer, so each case
is discriminated by switching on the value:
  $ cat >test_color.sy <<EOF
  > type color = Red | Green | Blue
  > let to_int (c : color) = match c with Red -> 0 | Green -> 1 | Blue -> 2
  > EOF
  $ dune exec sylic -- cir test_color.sy
  module Test_color :
  functions:
  public fn __init.Test_color() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_color.to_int(%c:i64) -> i64:
    entry: bb0
  
    bb0:
  
      switch %c:i64 [2: bb1, 1: bb2, 0: bb3 default: bb4]
  
    bb3:
      %Sy_cir_var_0:i64 = move(0:i64)
      goto bb5
  
    bb2:
      %Sy_cir_var_0:i64 = move(1:i64)
      goto bb5
  
    bb1:
      %Sy_cir_var_0:i64 = move(2:i64)
      goto bb5
  
    bb5:
  
      return %Sy_cir_var_0:i64
  
    bb4:
  
      match_failure
  end
  
  end

A variant with payload constructors is a heap object; cases are discriminated
by the tag in the object header (get_tag is an inlinable function):
  $ cat >test_shape.sy <<EOF
  > type shape = Circle of i64 | Square of i64
  > let area (s : shape) = match s with Circle r -> r | Square w -> w
  > EOF
  $ dune exec sylic -- cir test_shape.sy
  module Test_shape :
  functions:
  public fn __init.Test_shape() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_shape.area(%s:obj_ptr) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_1:i64 = get_tag(%s:obj_ptr)
      switch %Sy_cir_var_1:i64 [1: bb1, 0: bb2 default: bb3]
  
    bb2:
      %Sy_cir_var_3:i64 = obj_get(%s:obj_ptr, 0:i64):i64
      %Sy_cir_var_0:i64 = move(%Sy_cir_var_3:i64)
      goto bb4
  
    bb1:
      %Sy_cir_var_2:i64 = obj_get(%s:obj_ptr, 0:i64):i64
      %Sy_cir_var_0:i64 = move(%Sy_cir_var_2:i64)
      goto bb4
  
    bb4:
  
      return %Sy_cir_var_0:i64
  
    bb3:
  
      match_failure
  end
  
  end

A mixed variant is a heap object for every constructor; get_tag normalizes the
constant `11` immediate to its plain tag, so a single switch discriminates:
  $ cat >test_option.sy <<EOF
  > type option = None | Some of i64
  > let get (x : option) = match x with None -> 0 | Some v -> v
  > EOF
  $ dune exec sylic -- cir test_option.sy
  module Test_option :
  functions:
  public fn __init.Test_option() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_option.get(%x:obj_ptr) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_1:i64 = get_tag(%x:obj_ptr)
      switch %Sy_cir_var_1:i64 [1: bb1, 0: bb2 default: bb3]
  
    bb2:
      %Sy_cir_var_0:i64 = move(0:i64)
      goto bb4
  
    bb1:
      %Sy_cir_var_2:i64 = obj_get(%x:obj_ptr, 0:i64):i64
      %Sy_cir_var_0:i64 = move(%Sy_cir_var_2:i64)
      goto bb4
  
    bb4:
  
      return %Sy_cir_var_0:i64
  
    bb3:
  
      match_failure
  end
  
  end

get_tag is lowered to an inlinable function that detects the constant `11`
immediate before loading the object header:
  $ cat >test_tag.sy <<EOF
  > type option = None | Some of i64
  > let get (x : option) = match x with None -> 0 | Some v -> v
  > EOF
  $ dune exec sylic -- llvm test_tag.sy | grep -A 16 "define i64 @syli_inlinable_get_object_tag"
  define i64 @syli_inlinable_get_object_tag(ptr addrspace(1) %p) {
  bb0:
    %i = ptrtoint ptr addrspace(1) %p to i64
    %own = and i64 %i, 3
    %lo = icmp eq i64 %own, 3
    br i1 %lo, label %imm, label %obj
  imm:
    %it = lshr i64 %i, 2
    ret i64 %it
  obj:
    %u = and i64 %i, -4
    %up = inttoptr i64 %u to ptr addrspace(1)
    %h = load i64, ptr addrspace(1) %up
    %t = lshr i64 %h, 48
    %r = and i64 %t, 255
    ret i64 %r
  }

A record payload shared by two field patterns is materialised once: the payload
projection `obj_get(%v, 0)` is emitted a single time and reused by both fields:
  $ cat >test_shared_payload.sy <<EOF
  > type pair = { x : i64; y : i64 }
  > type t = A | B of pair
  > let f (v : t) = match v with A -> 0 | B { x = a; y = b } -> a
  > EOF
  $ dune exec sylic -- cir test_shared_payload.sy
  module Test_shared_payload :
  functions:
  public fn __init.Test_shared_payload() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_shared_payload.f(%v:obj_ptr) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_1:i64 = get_tag(%v:obj_ptr)
      switch %Sy_cir_var_1:i64 [1: bb1, 0: bb2 default: bb3]
  
    bb2:
      %Sy_cir_var_0:i64 = move(0:i64)
      goto bb4
  
    bb1:
      %Sy_cir_var_2:obj_ptr = obj_get(%v:obj_ptr, 0:i64):obj_ptr
      %Sy_cir_var_3:i64 = obj_get(%Sy_cir_var_2:obj_ptr, 1:i64):i64
      %Sy_cir_var_4:i64 = obj_get(%Sy_cir_var_2:obj_ptr, 0:i64):i64
      %Sy_cir_var_0:i64 = move(%Sy_cir_var_4:i64)
      goto bb4
  
    bb4:
  
      return %Sy_cir_var_0:i64
  
    bb3:
  
      match_failure
  end
  
  end
