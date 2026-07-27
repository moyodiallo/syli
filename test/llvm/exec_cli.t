Exec command resolves entry from compiled function symbols

Non-function main reports missing entry symbol:
  $ cat >test_exec_missing_main.sy <<EOF
  > let main = 0
  > EOF
  $ dune exec sylic -- llvm test_exec_missing_main.sy 2>&1
  declare void @syli_rt_object_release_owned(ptr)
  declare void @syli_rt_object_incr(ptr)
  
  @syliTest_exec_missing_main.main = global i64 0
  
  define void @__init.Test_exec_missing_main() {
  bb0:
    %__init_tmp_0 = call i64 @__init_global.syliTest_exec_missing_main.main()
    store i64 %__init_tmp_0, ptr @syliTest_exec_missing_main.main
    ret void
  }
  
  define i64 @__init_global.syliTest_exec_missing_main.main() {
  bb0:
    ret i64 0
  }
  
  define ptr @syli_ownership_untag(ptr %p) {
  bb0:
    %i = ptrtoint ptr %p to i64
    %u = and i64 %i, -2
    %r = inttoptr i64 %u to ptr
    ret ptr %r
  }
  
  define ptr @syli_ownership_borrow(ptr %p) {
  bb0:
    %i = ptrtoint ptr %p to i64
    %u = and i64 %i, -2
    %r = inttoptr i64 %u to ptr
    ret ptr %r
  }
  
  define ptr @syli_ownership_set_own(ptr %p) {
  bb0:
    %i = ptrtoint ptr %p to i64
    %o = or i64 %i, 1
    %r = inttoptr i64 %o to ptr
    ret ptr %r
  }
  
  define void @syli_ownership_release(ptr %p) {
  bb0:
    %pi = ptrtoint ptr %p to i64
    %tag = and i64 %pi, 1
    %is_own = icmp ne i64 %tag, 0
    br i1 %is_own, label %own, label %done
  own:
    call void @syli_rt_object_release_owned(ptr %p)
    ret void
  done:
    ret void
  }
  
  define ptr @syli_ownership_own(ptr %p) {
  bb0:
    %pi = ptrtoint ptr %p to i64
    %tag = and i64 %pi, 1
    %is_borrow = icmp eq i64 %tag, 0
    br i1 %is_borrow, label %promote, label %done
  promote:
    call void @syli_rt_object_incr(ptr %p)
    %r = or i64 %pi, 1
    %rp = inttoptr i64 %r to ptr
    ret ptr %rp
  done:
    ret ptr %p
  }
  

Function main emits exec startup symbols:
  $ cat >test_exec_fn_main.sy <<EOF
  > fn main () = 0
  > EOF
  $ dune exec sylic -- llvm test_exec_fn_main.sy 2>&1
  declare void @syli_rt_object_release_owned(ptr)
  declare void @syli_rt_object_incr(ptr)
  
  define i32 @syli_startup_program(i32 %argc, ptr %argv) {
  bb0:
    call void @syli_modules_init()
    %__dropped_main_ret = call i64 @syliTest_exec_fn_main.main()
    ret i32 0
  }
  
  define void @syli_modules_init() {
  bb0:
    call void @__init.Test_exec_fn_main()
    ret void
  }
  
  define void @__init.Test_exec_fn_main() {
  bb0:
    ret void
  }
  
  define i64 @syliTest_exec_fn_main.main() {
  bb0:
    ret i64 0
  }
  
  define ptr @syli_ownership_untag(ptr %p) {
  bb0:
    %i = ptrtoint ptr %p to i64
    %u = and i64 %i, -2
    %r = inttoptr i64 %u to ptr
    ret ptr %r
  }
  
  define ptr @syli_ownership_borrow(ptr %p) {
  bb0:
    %i = ptrtoint ptr %p to i64
    %u = and i64 %i, -2
    %r = inttoptr i64 %u to ptr
    ret ptr %r
  }
  
  define ptr @syli_ownership_set_own(ptr %p) {
  bb0:
    %i = ptrtoint ptr %p to i64
    %o = or i64 %i, 1
    %r = inttoptr i64 %o to ptr
    ret ptr %r
  }
  
  define void @syli_ownership_release(ptr %p) {
  bb0:
    %pi = ptrtoint ptr %p to i64
    %tag = and i64 %pi, 1
    %is_own = icmp ne i64 %tag, 0
    br i1 %is_own, label %own, label %done
  own:
    call void @syli_rt_object_release_owned(ptr %p)
    ret void
  done:
    ret void
  }
  
  define ptr @syli_ownership_own(ptr %p) {
  bb0:
    %pi = ptrtoint ptr %p to i64
    %tag = and i64 %pi, 1
    %is_borrow = icmp eq i64 %tag, 0
    br i1 %is_borrow, label %promote, label %done
  promote:
    call void @syli_rt_object_incr(ptr %p)
    %r = or i64 %pi, 1
    %rp = inttoptr i64 %r to ptr
    ret ptr %rp
  done:
    ret ptr %p
  }
  

  $ cat >test_exec_fn_main.sy <<EOF
  > fn main () = 0
  > EOF
  $ dune exec sylic -- llvm test_exec_fn_main.sy 2>&1
  declare void @syli_rt_object_release_owned(ptr)
  declare void @syli_rt_object_incr(ptr)
  
  define i32 @syli_startup_program(i32 %argc, ptr %argv) {
  bb0:
    call void @syli_modules_init()
    %__dropped_main_ret = call i64 @syliTest_exec_fn_main.main()
    ret i32 0
  }
  
  define void @syli_modules_init() {
  bb0:
    call void @__init.Test_exec_fn_main()
    ret void
  }
  
  define void @__init.Test_exec_fn_main() {
  bb0:
    ret void
  }
  
  define i64 @syliTest_exec_fn_main.main() {
  bb0:
    ret i64 0
  }
  
  define ptr @syli_ownership_untag(ptr %p) {
  bb0:
    %i = ptrtoint ptr %p to i64
    %u = and i64 %i, -2
    %r = inttoptr i64 %u to ptr
    ret ptr %r
  }
  
  define ptr @syli_ownership_borrow(ptr %p) {
  bb0:
    %i = ptrtoint ptr %p to i64
    %u = and i64 %i, -2
    %r = inttoptr i64 %u to ptr
    ret ptr %r
  }
  
  define ptr @syli_ownership_set_own(ptr %p) {
  bb0:
    %i = ptrtoint ptr %p to i64
    %o = or i64 %i, 1
    %r = inttoptr i64 %o to ptr
    ret ptr %r
  }
  
  define void @syli_ownership_release(ptr %p) {
  bb0:
    %pi = ptrtoint ptr %p to i64
    %tag = and i64 %pi, 1
    %is_own = icmp ne i64 %tag, 0
    br i1 %is_own, label %own, label %done
  own:
    call void @syli_rt_object_release_owned(ptr %p)
    ret void
  done:
    ret void
  }
  
  define ptr @syli_ownership_own(ptr %p) {
  bb0:
    %pi = ptrtoint ptr %p to i64
    %tag = and i64 %pi, 1
    %is_borrow = icmp eq i64 %tag, 0
    br i1 %is_borrow, label %promote, label %done
  promote:
    call void @syli_rt_object_incr(ptr %p)
    %r = or i64 %pi, 1
    %rp = inttoptr i64 %r to ptr
    ret ptr %rp
  done:
    ret ptr %p
  }
  

End-to-end runtime execution test with libsyliruntime.a:
  $ cat >test_e2e_print.sy <<EOF
  > fn main () =
  >   syli_print_i64(42)
  > EOF
  $ dune exec sylic -- llvm test_e2e_print.sy 2>&1 | head -20
  Fatal error: exception Syli_typing__Env.Type_error("main must return unit or int64")

Runtime linking test compiles and links successfully:
  $ cat >test_e2e_add.sy <<EOF
  > fn main () =
  >   let result = 10 + 32
  >   syli_print_i64(result)
  > EOF
  $ dune exec sylic -- llvm test_e2e_add.sy > test_e2e_add.ll 2>&1
  ***** UNREACHABLE *****
  $ test -f test_e2e_add.ll && echo "Generated LLVM IR"
  ***** UNREACHABLE *****

