  $ cat >test_file.sy <<EOF
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let id x = x
  > let apply_twice f x = f (f x)
  > let main () =
  >   let result_1 = apply_twice id 10
  >   syli_print_i64 result_1
  > EOF
  $ dune exec sylic -- core test_file.sy > test_file.core
  $ dune exec sylic -- cir test_file.sy > test_file.ir
  $ dune exec sylic -- llvm test_file.sy > test_file.ll

  $ cat test_file.core
  module Test_file
  extern syliTest_file.syli_print_i64 : (i64) -> unit
  
  let syliTest_file.id = fun (x) : 'a53 ->
      x : 'a53
  
  let syliTest_file.apply_twice = fun (f, x) : 'a61 ->
      f(f(x : 'a61) : 'a61) : 'a61
  
  let syliTest_file.main = fun () : unit ->
      {
        let sy1_result_1 = syliTest_file.apply_twice(syliTest_file.id : (i64) -> i64, 10 : i64) : i64
        syliTest_file.syli_print_i64(sy1_result_1 : i64) : unit
      }
  

  $ cat test_file.ir
  module Test_file :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_file() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_file.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:(i64 -> i64) = #make_closure {syliTest_file.id} () ()
      %Sy_cir_var_1:i64 = #call_direct syliTest_file.apply_twice__fn_i64_i64__i64_ret_i64 (%Sy_cir_var_0:(i64 -> i64), 10:i64)
      %Sy_cir_var_2:void = #call_direct syliTest_file.syli_print_i64 (%Sy_cir_var_1:i64)
      return
  end
  
  public fn syliTest_file.apply_twice__fn_i64_i64__i64_ret_i64(%f:(i64 -> i64), %x:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:i64 = #call_apply {%f:(i64 -> i64)}  (%x:i64)
      %Sy_cir_var_1:i64 = #call_apply {%f:(i64 -> i64)}  (%Sy_cir_var_0:i64)
      return %Sy_cir_var_1:i64
  end
  
  public fn syliTest_file.id__i64_ret_i64(%x:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  end

  $ dune exec sylic -- oir test_file.sy
  module Test_file :
  ffi_external_functions:
  extern fn syli_print_i64(i64) -> void
  
  
  functions:
  public fn __init.Test_file() -> void:
    entry: bb0
  
    bb0:
  
      return
  end
  
  public fn syliTest_file.main(%__unit.0:i64) -> void:
    entry: bb0
  
    bb0:
      gc_cycle
      %Sy_cir_var_0:obj{{card=1 [0:fn_ptr]} tag=0 unknow_cyclic} = object_create{size=1:i32}
      
      %Sy_oir_accum_fn_0:fn_ptr = addr_fn(__make_closure_accum.syliTest_file.id.62_ret_i64)
      obj_set(%Sy_cir_var_0:obj_ptr, 0:i32, %Sy_oir_accum_fn_0:fn_ptr):fn_ptr
      
      %Sy_cir_var_1:i64 = #call_direct syliTest_file.apply_twice__fn_i64_i64__i64_ret_i64 (@transfer %Sy_cir_var_0:obj_ptr, 10:i64)
      %Sy_cir_var_2:void = #call_direct syliTest_file.syli_print_i64 (%Sy_cir_var_1:i64)
      return
  end
  
  public fn syliTest_file.apply_twice__fn_i64_i64__i64_ret_i64(%f:obj_ptr, %x:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_accum_ptr_0:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_0:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_0:fn_ptr)  (%x:i64, @borrow %f:obj_ptr, 0:i64)
      
      %Sy_accum_ptr_1:fn_ptr = obj_get(%f:obj_ptr, 0:i32):fn_ptr
      %Sy_cir_var_1:i64 = #call_direct_fn_ptr(%Sy_accum_ptr_1:fn_ptr)  (%Sy_cir_var_0:i64, @transfer %f:obj_ptr, 0:i64)
      
      return %Sy_cir_var_1:i64
  end
  
  public fn syliTest_file.id__i64_ret_i64(%x:i64) -> i64:
    entry: bb0
  
    bb0:
  
      return %x:i64
  end
  
  private fn __make_closure_accum.syliTest_file.id.62_ret_i64(%Sy_oir_x0:i64, %Sy_oir_clos:obj_ptr, %Sy_oir_dp_id:i64) -> i64:
    entry: bb0
  
    bb0:
      release(%Sy_oir_clos:obj_ptr)
      %Sy_oir_rst:i64 = #call_direct __wrapper.syliTest_file.id.i64_ret_i64 (%Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  private fn __wrapper.syliTest_file.id.i64_ret_i64(%Sy_oir_x0:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_oir_rst:i64 = #call_direct syliTest_file.id__i64_ret_i64 (%Sy_oir_x0:i64)
      return %Sy_oir_rst:i64
  end
  
  end

  $ cat test_file.ll
  declare void @syli_print_i64(i64)
  declare void @syli_rt_gc_cycle()
  declare ptr addrspace(1) @syli_rt_ownership_alloc_object(i64, i32, i32)
  declare void @syli_rt_ownership_decr(ptr addrspace(1))
  declare void @syli_rt_ownership_incr(ptr addrspace(1))
  
  define i32 @syli_startup_program() gc "statepoint-example" {
  bb0:
    call void @syli_modules_init()
    ret i32 0
  }
  
  define void @syli_modules_init() gc "statepoint-example" {
  bb0:
    call void @__init.Test_file()
    ret void
  }
  
  define void @__init.Test_file() gc "statepoint-example" {
  bb0:
    ret void
  }
  
  define void @syliTest_file.main() gc "statepoint-example" {
  bb0:
    call void @syli_rt_gc_cycle()
    %Sy_cir_var_0 = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 2377900603251621889, i32 1, i32 1)
    ; nop
    %Sy_oir_accum_fn_0 = bitcast ptr @__make_closure_accum.syliTest_file.id.62_ret_i64 to ptr
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_cir_var_0)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_0, ptr addrspace(1) %Sy_llvm_tmp_1
    ; nop
    %Sy_cir_var_1 = call i64 @syliTest_file.apply_twice__fn_i64_i64__i64_ret_i64(ptr addrspace(1) %Sy_cir_var_0, i64 10)
    call void @syli_print_i64(i64 %Sy_cir_var_1)
    ret void
  }
  
  define i64 @syliTest_file.apply_twice__fn_i64_i64__i64_ret_i64(ptr addrspace(1) %f, i64 %x) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %f)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i32 0
    %Sy_accum_ptr_0 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_rir_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_borrow(ptr addrspace(1) %f)
    %Sy_cir_var_0 = call i64 %Sy_accum_ptr_0(i64 %x, ptr addrspace(1) %Sy_rir_tmp_0, i64 0)
    ; nop
    %Sy_llvm_tmp_2 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %f)
    %Sy_llvm_tmp_3 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_2, i32 0, i32 2, i32 0
    %Sy_accum_ptr_1 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_3
    %Sy_cir_var_1 = call i64 %Sy_accum_ptr_1(i64 %Sy_cir_var_0, ptr addrspace(1) %f, i64 0)
    ; nop
    ret i64 %Sy_cir_var_1
  }
  
  define i64 @syliTest_file.id__i64_ret_i64(i64 %x) gc "statepoint-example" {
  bb0:
    ret i64 %x
  }
  
  define i64 @__make_closure_accum.syliTest_file.id.62_ret_i64(i64 %Sy_oir_x0, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_oir_rst = call i64 @__wrapper.syliTest_file.id.i64_ret_i64(i64 %Sy_oir_x0)
    ret i64 %Sy_oir_rst
  }
  
  define i64 @__wrapper.syliTest_file.id.i64_ret_i64(i64 %Sy_oir_x0) gc "statepoint-example" {
  bb0:
    %Sy_oir_rst = call i64 @syliTest_file.id__i64_ret_i64(i64 %Sy_oir_x0)
    ret i64 %Sy_oir_rst
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
    %u = and i64 %i, -2
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
  
  $ clang -c test_file.ll -o /dev/null 2>/dev/null
