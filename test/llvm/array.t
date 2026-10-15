Array literal, index get/set lower to CIR and compile to LLVM:
  $ cat >test_array.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > primitive (index_get) : 'a array -> i64 -> 'a = "array_index_get"
  > primitive (index_set) : 'a array -> i64 -> 'a -> unit = "array_index_set"
  > let main () =
  >     let a = [| 10; 20; 30 |]
  >     syli_print_i64(a.[1])
  > EOF
  $ dune exec sylic -- cir test_array.sy
  module Test_array :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_array() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_array.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:obj{[array_elt=i64] acyclic} = object_create{length=3:i64}
      obj_set(%Sy_cir_var_0:obj_ptr, array[0:i64], 10:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, array[1:i64], 20:i64):i64
      obj_set(%Sy_cir_var_0:obj_ptr, array[2:i64], 30:i64):i64
      %Sy_cir_var_1:i64 = #call_direct syliTest_array.index_get__obj_obj_i64__i64_ret_i64 (%Sy_cir_var_0:obj_ptr, 1:i64)
      %Sy_cir_var_2:void = #call_direct syliTest_array.syli_print_i64 (%Sy_cir_var_1:i64)
      return
  end
  
  public fn syliTest_array.index_get__obj_obj_i64__i64_ret_i64(%x:obj_ptr, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = obj_get(%x:obj_ptr, array[%y:i64]):i64
      return %Sy_prim_result:i64
  end
  
  end

  $ dune exec sylic -- llvm test_array.sy
  declare void @syli_print_i64(i64)
  declare void @syli_rt_gc_cycle()
  declare ptr addrspace(1) @syli_rt_ownership_alloc_object(i64, i32, i64)
  declare void @syli_rt_ownership_decr(ptr addrspace(1))
  declare void @syli_rt_ownership_incr(ptr addrspace(1))
  
  define i32 @syli_startup_program() gc "statepoint-example" {
  bb0:
    call void @syli_modules_init()
    ret i32 0
  }
  
  define void @syli_modules_init() gc "statepoint-example" {
  bb0:
    call void @__init.Test_array()
    ret void
  }
  
  define void @__init.Test_array() gc "statepoint-example" {
  bb0:
    ret void
  }
  
  define void @syliTest_array.main() gc "statepoint-example" {
  bb0:
    call void @syli_rt_gc_cycle()
    %Sy_rir_hdr_0 = add i64 26388279066624, 3
    %Sy_cir_var_0 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 %Sy_rir_hdr_0, i32 1, i64 3)
    ; nop
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 0
    store i64 10, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i64 1
    store i64 20, ptr addrspace(1) %Sy_llvm_tmp_3
    %Sy_llvm_tmp_4 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_5 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_4, i32 0, i32 2, i64 2
    store i64 30, ptr addrspace(1) %Sy_llvm_tmp_5
    %Sy_cir_var_1 = call i64 @syliTest_array.index_get__obj_obj_i64__i64_ret_i64(ptr addrspace(1) %Sy_cir_var_0, i64 1)
    call void @syli_print_i64(i64 %Sy_cir_var_1)
    ret void
  }
  
  define i64 @syliTest_array.index_get__obj_obj_i64__i64_ret_i64(ptr addrspace(1) %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %x)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 %y
    %Sy_prim_result = load i64, ptr addrspace(1) %Sy_llvm_tmp_1
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %x)
    ret i64 %Sy_prim_result
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %p) {
  bb0:
    %i = ptrtoint ptr addrspace(1) %p to i64
    %u = and i64 %i, -4
    %r = inttoptr i64 %u to ptr addrspace(1)
    ret ptr addrspace(1) %r
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_borrow(ptr addrspace(1) %p) {
  bb0:
    %i = ptrtoint ptr addrspace(1) %p to i64
    %b1 = lshr i64 %i, 1
    %b1m = and i64 %b1, 1
    %m = or i64 %b1m, -2
    %u = and i64 %i, %m
    %r = inttoptr i64 %u to ptr addrspace(1)
    ret ptr addrspace(1) %r
  }
  
  define void @syli_inlinable_ownership_release(ptr addrspace(1) %p) {
  bb0:
    %pi = ptrtoint ptr addrspace(1) %p to i64
    %tag = and i64 %pi, 3
    %is_own = icmp eq i64 %tag, 1
    br i1 %is_own, label %own, label %done
  own:
    call void @syli_rt_ownership_decr(ptr addrspace(1) %p)
    ret void
  done:
    ret void
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_own(ptr addrspace(1) %p) {
  bb0:
    %pi = ptrtoint ptr addrspace(1) %p to i64
    %tag = and i64 %pi, 3
    %is_borrow = icmp eq i64 %tag, 0
    br i1 %is_borrow, label %promote, label %done
  promote:
    %r = or i64 %pi, 1
    %rp = inttoptr i64 %r to ptr addrspace(1)
    call void @syli_rt_ownership_incr(ptr addrspace(1) %rp)
    ret ptr addrspace(1) %rp
  done:
    ret ptr addrspace(1) %p
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_share(ptr addrspace(1) %p) {
  bb0:
    %pi = ptrtoint ptr addrspace(1) %p to i64
    %tag = and i64 %pi, 2
    %is_always = icmp ne i64 %tag, 0
    br i1 %is_always, label %done, label %promote
  promote:
    %r = or i64 %pi, 1
    %rp = inttoptr i64 %r to ptr addrspace(1)
    call void @syli_rt_ownership_incr(ptr addrspace(1) %rp)
    ret ptr addrspace(1) %rp
  done:
    ret ptr addrspace(1) %p
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_make_always_borrow(ptr addrspace(1) %p) {
  bb0:
    %i = ptrtoint ptr addrspace(1) %p to i64
    %u = and i64 %i, -4
    %r = or i64 %u, 2
    %rp = inttoptr i64 %r to ptr addrspace(1)
    ret ptr addrspace(1) %rp
  }
  
