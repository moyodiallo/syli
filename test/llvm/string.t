String:
  $ cat >test_esc_str.sy <<EOF
  > foreign syli_print_str : string -> unit = "syli_print_str"
  > let main () =
  >   syli_print_str "helloworld"
  > let _ = main ()
  > EOF
  $ dune exec sylic -- llvm test_esc_str.sy
  declare void @syli_print_str({ ptr, i64 })
  declare void @syli_rt_ownership_decr(ptr addrspace(1))
  declare void @syli_rt_ownership_incr(ptr addrspace(1))
  
  @__str.1 = global [10 x i8] c"helloworld"
  
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
    %Sy_llvm_tmp_0 = getelementptr i8, ptr @__str.1, i32 0
    %Sy_llvm_tmp_1 = insertvalue { ptr, i64 } zeroinitializer, ptr %Sy_llvm_tmp_0, 0
    %Sy_llvm_tmp_2 = insertvalue { ptr, i64 } %Sy_llvm_tmp_1, i64 10, 1
    call void @syli_print_str({ ptr, i64 } %Sy_llvm_tmp_2)
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
  
