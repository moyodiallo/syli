  $ cat >test_file.sy <<EOF
  > primitive (-)  : i64 -> i64 -> i64 = "sub"
  > primitive (*)  : i64 -> i64 -> i64 = "mul"
  > primitive (==)  : i64 -> i64 -> bool = "eq"
  > foreign syli_print_i64 : i64 -> unit = "syli_print_i64"
  > let rec factorial n =
  >   if n == 0 then
  >     1
  >   else
  >     n * factorial (n - 1)
  > let main () = syli_print_i64 (factorial 5)
  > EOF
  $ dune exec sylic -- core test_file.sy > test_file.core
  $ dune exec sylic -- cir test_file.sy > test_file.ir
  $ dune exec sylic -- llvm test_file.sy > test_file.ll

  $ cat test_file.core
  module Test_file
  extern "syliTest_file.-" : (i64) -> (i64) -> i64
  
  extern "syliTest_file.*" : (i64) -> (i64) -> i64
  
  extern "syliTest_file.==" : (i64) -> (i64) -> bool
  
  extern syliTest_file.syli_print_i64 : (i64) -> unit
  
  let rec syliTest_file.factorial = fun (n) : i64 ->
      if "syliTest_file.=="(n : i64, 0 : i64) : bool
        1 : i64
      else
        "syliTest_file.*"(n : i64, syliTest_file.factorial("syliTest_file.-"(n : i64, 1 : i64) : i64) : i64) : i64
  
  let syliTest_file.main = fun () : unit ->
      syliTest_file.syli_print_i64(syliTest_file.factorial(5 : i64) : i64) : unit
  

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
      %Sy_cir_var_0:i64 = #call_direct syliTest_file.factorial (5:i64)
      %Sy_cir_var_1:void = #call_direct syliTest_file.syli_print_i64 (%Sy_cir_var_0:i64)
      return
  end
  
  public fn syliTest_file.factorial(%n:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_cir_var_0:bool = #call_direct "syliTest_file.==" (%n:i64, 0:i64)
      cond_br %Sy_cir_var_0:bool, bb1, bb2
  
    bb2:
      %Sy_cir_var_2:i64 = #call_direct "syliTest_file.-" (%n:i64, 1:i64)
      %Sy_cir_var_3:i64 = #call_direct syliTest_file.factorial (%Sy_cir_var_2:i64)
      %Sy_cir_var_4:i64 = #call_direct "syliTest_file.*" (%n:i64, %Sy_cir_var_3:i64)
      %Sy_cir_var_1:i64 = move(%Sy_cir_var_4:i64)
      goto bb3
  
    bb1:
      %Sy_cir_var_1:i64 = move(1:i64)
      goto bb3
  
    bb3:
  
      return %Sy_cir_var_1:i64
  end
  
  public fn "syliTest_file.-"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 - %y:i64
      return %Sy_prim_result:i64
  end
  
  public fn "syliTest_file.*"(%x:i64, %y:i64) -> i64:
    entry: bb0
  
    bb0:
      %Sy_prim_result:i64 = %x:i64 * %y:i64
      return %Sy_prim_result:i64
  end
  
  public fn "syliTest_file.=="(%x:i64, %y:i64) -> bool:
    entry: bb0
  
    bb0:
      %Sy_prim_result:bool = %x:i64 == %y:i64
      return %Sy_prim_result:bool
  end
  
  end

  $ cat test_file.ll
  declare void @syli_print_i64(i64)
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
    %Sy_cir_var_0 = call i64 @syliTest_file.factorial(i64 5)
    call void @syli_print_i64(i64 %Sy_cir_var_0)
    ret void
  }
  
  define i64 @syliTest_file.factorial(i64 %n) gc "statepoint-example" {
  bb0:
    %Sy_cir_var_1 = alloca i64
    %Sy_cir_var_0 = call i1 @"syliTest_file.=="(i64 %n, i64 0)
    br i1 %Sy_cir_var_0, label %bb1, label %bb2
  bb2:
    %Sy_cir_var_2 = call i64 @"syliTest_file.-"(i64 %n, i64 1)
    %Sy_cir_var_3 = call i64 @syliTest_file.factorial(i64 %Sy_cir_var_2)
    %Sy_cir_var_4 = call i64 @"syliTest_file.*"(i64 %n, i64 %Sy_cir_var_3)
    store i64 %Sy_cir_var_4, ptr %Sy_cir_var_1
    br label %bb3
  bb1:
    store i64 1, ptr %Sy_cir_var_1
    br label %bb3
  bb3:
    %Sy_llvm_tmp_0 = load i64, ptr %Sy_cir_var_1
    ret i64 %Sy_llvm_tmp_0
  }
  
  define i64 @"syliTest_file.-"(i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_prim_result = sub i64 %x, %y
    ret i64 %Sy_prim_result
  }
  
  define i64 @"syliTest_file.*"(i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_prim_result = mul i64 %x, %y
    ret i64 %Sy_prim_result
  }
  
  define i1 @"syliTest_file.=="(i64 %x, i64 %y) gc "statepoint-example" {
  bb0:
    %Sy_prim_result = icmp eq i64 %x, %y
    ret i1 %Sy_prim_result
  }
  
  define ptr addrspace(1) @syli_inlinable_ownership_untag(ptr addrspace(1) %p) {
  bb0:
    %i = ptrtoint ptr addrspace(1) %p to i64
    %u = and i64 %i, -2
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
    %tag = and i64 %pi, 1
    %is_own = icmp ne i64 %tag, 0
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
    %tag = and i64 %pi, 1
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
  

  $ clang -c test_file.ll -o /dev/null 2>/dev/null
