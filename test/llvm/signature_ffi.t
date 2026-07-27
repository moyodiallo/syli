Signature with external declaration emits an external declaration in LLVM IR:
  $ cat >test_int.sy <<EOF
  > signature:
  >   extern print_int : int -> unit = "print_int"
  > end
  > let x = 42
  > EOF
  $ dune exec sylic -- llvm test_int.sy
  declare void @syli_rt_object_release_owned(ptr)
  declare void @syli_rt_object_incr(ptr)
  declare void @print_int(ptr)
  
  @syliTest_int.x = global i64 42
  
  define void @__init.Test_int() {
  bb0:
    %__init_tmp_0 = call i64 @__init_global.syliTest_int.x()
    store i64 %__init_tmp_0, ptr @syliTest_int.x
    ret void
  }
  
  define i64 @__init_global.syliTest_int.x() {
  bb0:
    ret i64 42
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
  
