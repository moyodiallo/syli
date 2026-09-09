String:
  $ cat >test_esc_str.sy <<EOF
  > foreign syli_print_string : string -> unit = "syli_print_string"
  > let main () =
  >   syli_print_string "helloworld"
  > let _ = main ()
  > EOF
  $ dune exec sylic -- llvm test_esc_str.sy
  declare void @syli_print_string(ptr addrspace(1))
  declare void @syli_rt_ownership_decr(ptr addrspace(1))
  declare void @syli_rt_ownership_incr(ptr addrspace(1))
  
  @__str.1 = global { i64, i64, [10 x i8] } { i64 -9223372036854775798, i64 0, [10 x i8] c"helloworld" }
  
  define i32 @syli_startup_program() gc "statepoint-example" {
  bb0:
    call void @syli_modules_init()
    ret i32 0
  }
  
  define void @syli_modules_init() gc "statepoint-example" {
  bb0:
    call void @__init.Test_esc_str()
    ret void
  }
  
  define void @__init.Test_esc_str() gc "statepoint-example" {
  bb0:
    call void @__init_global.syliTest_esc_str.sy1_any_pat()
    ret void
  }
  
  define void @__init_global.syliTest_esc_str.sy1_any_pat() gc "statepoint-example" {
  bb0:
    call void @syliTest_esc_str.main()
    ret void
  }
  
  define void @syliTest_esc_str.main() gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = ptrtoint ptr @__str.1 to i64
    %Sy_llvm_tmp_1 = add i64 %Sy_llvm_tmp_0, 2
    %Sy_llvm_tmp_2 = inttoptr i64 %Sy_llvm_tmp_1 to ptr addrspace(1)
    call void @syli_print_string(ptr addrspace(1) %Sy_llvm_tmp_2)
    ret void
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
  
String passed to a function parameter and returned:
  $ cat >test_str_fn.sy <<EOF
  > foreign syli_print_string : string -> unit = "syli_print_string"
  > let id (s: string) = s
  > let main () =
  >   let s = "hello"
  >   let r = id s
  >   syli_print_string r
  > let _ = main ()
  > EOF
  $ dune exec sylic -- llvm test_str_fn.sy
  declare void @syli_print_string(ptr addrspace(1))
  declare void @syli_rt_ownership_decr(ptr addrspace(1))
  declare void @syli_rt_ownership_incr(ptr addrspace(1))
  
  @__str.1 = global { i64, i64, [5 x i8] } { i64 -9223372036854775803, i64 0, [5 x i8] c"hello" }
  
  define i32 @syli_startup_program() gc "statepoint-example" {
  bb0:
    call void @syli_modules_init()
    ret i32 0
  }
  
  define void @syli_modules_init() gc "statepoint-example" {
  bb0:
    call void @__init.Test_str_fn()
    ret void
  }
  
  define void @__init.Test_str_fn() gc "statepoint-example" {
  bb0:
    call void @__init_global.syliTest_str_fn.sy3_any_pat()
    ret void
  }
  
  define void @__init_global.syliTest_str_fn.sy3_any_pat() gc "statepoint-example" {
  bb0:
    call void @syliTest_str_fn.main()
    ret void
  }
  
  define void @syliTest_str_fn.main() gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = ptrtoint ptr @__str.1 to i64
    %Sy_llvm_tmp_1 = add i64 %Sy_llvm_tmp_0, 2
    %Sy_llvm_tmp_2 = inttoptr i64 %Sy_llvm_tmp_1 to ptr addrspace(1)
    %Sy_cir_var_0 = call ptr addrspace(1) @syliTest_str_fn.id(ptr addrspace(1) %Sy_llvm_tmp_2)
    call void @syli_print_string(ptr addrspace(1) %Sy_cir_var_0)
    ret void
  }
  
  define ptr addrspace(1) @syliTest_str_fn.id(ptr addrspace(1) %s) gc "statepoint-example" {
  bb0:
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %s)
    %Sy_rir_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_own(ptr addrspace(1) %s)
    ret ptr addrspace(1) %Sy_rir_tmp_0
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
  

String returned from a closure capturing it:
  $ cat >test_str_closure.sy <<EOF
  > foreign syli_print_string : string -> unit = "syli_print_string"
  > let main () =
  >   let s = "hi"
  >   let f () = s
  >   let r = f ()
  >   syli_print_string r
  > let _ = main ()
  > EOF
  $ dune exec sylic -- llvm test_str_closure.sy
  declare void @syli_print_string(ptr addrspace(1))
  declare void @syli_rt_gc_cycle()
  declare ptr addrspace(1) @syli_rt_ownership_alloc_object(i64, i32, i32)
  declare void @syli_rt_ownership_decr(ptr addrspace(1))
  declare void @syli_rt_ownership_incr(ptr addrspace(1))
  
  @__str.1 = global { i64, i64, [2 x i8] } { i64 -9223372036854775806, i64 0, [2 x i8] c"hi" }
  
  define i32 @syli_startup_program() gc "statepoint-example" {
  bb0:
    call void @syli_modules_init()
    ret i32 0
  }
  
  define void @syli_modules_init() gc "statepoint-example" {
  bb0:
    call void @__init.Test_str_closure()
    ret void
  }
  
  define void @__init.Test_str_closure() gc "statepoint-example" {
  bb0:
    call void @__init_global.syliTest_str_closure.sy4_any_pat()
    ret void
  }
  
  define void @__init_global.syliTest_str_closure.sy4_any_pat() gc "statepoint-example" {
  bb0:
    call void @syliTest_str_closure.main()
    ret void
  }
  
  define void @syliTest_str_closure.main() gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = ptrtoint ptr @__str.1 to i64
    %Sy_llvm_tmp_1 = add i64 %Sy_llvm_tmp_0, 2
    %Sy_llvm_tmp_2 = inttoptr i64 %Sy_llvm_tmp_1 to ptr addrspace(1)
    call void @syli_rt_gc_cycle()
    %sy2_f = call ptr addrspace(1) @syli_rt_ownership_alloc_object(i64 4251398048237748290, i32 1, i32 2)
    ; nop
    %Sy_oir_accum_fn_0 = bitcast ptr @__make_closure_accum.sy2_f.26_ret_string to ptr
    %Sy_llvm_tmp_3 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %sy2_f)
    %Sy_llvm_tmp_4 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_3, i32 0, i32 2, i32 0
    store ptr %Sy_oir_accum_fn_0, ptr addrspace(1) %Sy_llvm_tmp_4
    %Sy_llvm_tmp_5 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %sy2_f)
    %Sy_llvm_tmp_6 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_5, i32 0, i32 2, i32 1
    %Sy_oir_release_tmp_1 = load ptr addrspace(1), ptr addrspace(1) %Sy_llvm_tmp_6
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_release_tmp_1)
    %Sy_rir_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_own(ptr addrspace(1) %Sy_llvm_tmp_2)
    %Sy_llvm_tmp_7 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %sy2_f)
    %Sy_llvm_tmp_8 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_7, i32 0, i32 2, i32 1
    store ptr addrspace(1) %Sy_rir_tmp_0, ptr addrspace(1) %Sy_llvm_tmp_8
    ; nop
    %Sy_llvm_tmp_9 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %sy2_f)
    %Sy_llvm_tmp_10 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_9, i32 0, i32 2, i32 0
    %Sy_accum_ptr_1 = load ptr, ptr addrspace(1) %Sy_llvm_tmp_10
    %Sy_cir_var_0 = call ptr addrspace(1) %Sy_accum_ptr_1(i64 0, ptr addrspace(1) %sy2_f, i64 0)
    ; nop
    call void @syli_print_string(ptr addrspace(1) %Sy_cir_var_0)
    ret void
  }
  
  define ptr addrspace(1) @sy2_f(ptr addrspace(1) %sy1_s) gc "statepoint-example" {
  bb0:
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %sy1_s)
    %Sy_rir_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_own(ptr addrspace(1) %sy1_s)
    ret ptr addrspace(1) %Sy_rir_tmp_0
  }
  
  define ptr addrspace(1) @__make_closure_accum.sy2_f.26_ret_string(i64 %Sy_oir_x0, ptr addrspace(1) %Sy_oir_clos, i64 %Sy_oir_dp_id) gc "statepoint-example" {
  bb0:
    %Sy_llvm_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %Sy_oir_clos)
    %Sy_llvm_tmp_1 = getelementptr { i64, i64, [0 x i64] }, ptr addrspace(1) %Sy_llvm_tmp_0, i32 0, i32 2, i64 1
    %Sy_rir_raw_tmp_0 = load ptr addrspace(1), ptr addrspace(1) %Sy_llvm_tmp_1
    %Sy_oir_obj0 = call ptr addrspace(1) @syli_inlinable_ownership_share(ptr addrspace(1) %Sy_rir_raw_tmp_0)
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_clos)
    %Sy_oir_rst = call ptr addrspace(1) @__wrapper.sy2_f.string_i64_ret_string(ptr addrspace(1) %Sy_oir_obj0, i64 %Sy_oir_x0)
    %Sy_rir_tmp_1 = call ptr addrspace(1) @syli_inlinable_ownership_own(ptr addrspace(1) %Sy_oir_rst)
    ret ptr addrspace(1) %Sy_rir_tmp_1
  }
  
  define ptr addrspace(1) @__wrapper.sy2_f.string_i64_ret_string(ptr addrspace(1) %Sy_oir_x0, i64 %Sy_oir_x1) gc "statepoint-example" {
  bb0:
    call void @syli_inlinable_ownership_release(ptr addrspace(1) %Sy_oir_x0)
    %Sy_oir_rst = call ptr addrspace(1) @sy2_f(ptr addrspace(1) %Sy_oir_x0)
    %Sy_rir_tmp_0 = call ptr addrspace(1) @syli_inlinable_ownership_own(ptr addrspace(1) %Sy_oir_rst)
    ret ptr addrspace(1) %Sy_rir_tmp_0
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
  
