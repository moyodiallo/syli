(** LLVM function definitions for ownership bit operations. These are appended
    to the module after lowering, so clang -O3 can inline them into call sites.
*)

open Llvm_lir.Types

let global (n : string) (ty : lltype) : operand = LV_Global (n, ty)
let local name ty = LV_Local (name, ty)
let assign dst rhs = LV_Assign (dst, rhs)
let i64_ty = LV_I64
let ptr_ty = LV_Ptr

(*
  define ptr @syli_ownership_untag(ptr %p) {
    %i = ptrtoint ptr %p to i64
    %u = and i64 %i, -2
    %r = inttoptr i64 %u to ptr
    ret ptr %r
  }
*)
let mk_untag_fn () : func =
  {
    name = "syli_ownership_untag";
    ret_type = ptr_ty;
    params = [ (ptr_ty, "p") ];
    blocks =
      [
        {
          label = "bb0";
          instructions =
            [
              assign (local "i" i64_ty)
                (LV_Cast (LV_PtrToInt, local "p" ptr_ty, i64_ty));
              assign (local "u" i64_ty)
                (LV_IBinOp
                   ( LV_IBitAnd,
                     local "i" i64_ty,
                     LV_Constant (LV_Integer (-2L), i64_ty) ));
              assign (local "r" ptr_ty)
                (LV_Cast (LV_IntToPtr, local "u" i64_ty, ptr_ty));
            ];
          terminator = LV_Ret (Some (local "r" ptr_ty));
        };
      ];
    linkage = Private;
  }

(*
  define ptr @syli_ownership_borrow(ptr %p) {
    %i = ptrtoint ptr %p to i64
    %u = and i64 %i, -2
    %r = inttoptr i64 %u to ptr
    ret ptr %r
  }
*)
let mk_borrow_fn () : func =
  {
    name = "syli_ownership_borrow";
    ret_type = ptr_ty;
    params = [ (ptr_ty, "p") ];
    blocks =
      [
        {
          label = "bb0";
          instructions =
            [
              assign (local "i" i64_ty)
                (LV_Cast (LV_PtrToInt, local "p" ptr_ty, i64_ty));
              assign (local "u" i64_ty)
                (LV_IBinOp
                   ( LV_IBitAnd,
                     local "i" i64_ty,
                     LV_Constant (LV_Integer (-2L), i64_ty) ));
              assign (local "r" ptr_ty)
                (LV_Cast (LV_IntToPtr, local "u" i64_ty, ptr_ty));
            ];
          terminator = LV_Ret (Some (local "r" ptr_ty));
        };
      ];
    linkage = Private;
  }

(*
  define ptr @syli_ownership_set_own(ptr %p) {
    %i = ptrtoint ptr %p to i64
    %o = or i64 %i, 1
    %r = inttoptr i64 %o to ptr
    ret ptr %r
  }
*)
let mk_set_own_fn () : func =
  {
    name = "syli_ownership_set_own";
    ret_type = ptr_ty;
    params = [ (ptr_ty, "p") ];
    blocks =
      [
        {
          label = "bb0";
          instructions =
            [
              assign (local "i" i64_ty)
                (LV_Cast (LV_PtrToInt, local "p" ptr_ty, i64_ty));
              assign (local "o" i64_ty)
                (LV_IBinOp
                   ( LV_IBitOr,
                     local "i" i64_ty,
                     LV_Constant (LV_Integer 1L, i64_ty) ));
              assign (local "r" ptr_ty)
                (LV_Cast (LV_IntToPtr, local "o" i64_ty, ptr_ty));
            ];
          terminator = LV_Ret (Some (local "r" ptr_ty));
        };
      ];
    linkage = Private;
  }

(*
  define void @syli_ownership_release(ptr %p) {
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
*)
let mk_release_fn () : func =
  let owned_fn_ty = LV_Func ([ ptr_ty ], LV_Void) in
  {
    name = "syli_ownership_release";
    ret_type = LV_Void;
    params = [ (ptr_ty, "p") ];
    blocks =
      [
        {
          label = "bb0";
          instructions =
            [
              assign (local "pi" i64_ty)
                (LV_Cast (LV_PtrToInt, local "p" ptr_ty, i64_ty));
              assign (local "tag" i64_ty)
                (LV_IBinOp
                   ( LV_IBitAnd,
                     local "pi" i64_ty,
                     LV_Constant (LV_Integer 1L, i64_ty) ));
              assign (local "is_own" LV_I1)
                (LV_ICmp
                   ( LV_INe,
                     local "tag" i64_ty,
                     LV_Constant (LV_Integer 0L, i64_ty) ));
            ];
          terminator = LV_CondBr (local "is_own" LV_I1, "own", "done");
        };
        {
          label = "own";
          instructions =
            [
              assign (local "_r" LV_Void)
                (LV_Call
                   {
                     fn = global "syli_rt_object_release_owned" owned_fn_ty;
                     args = [ local "p" ptr_ty ];
                     ret_ty = LV_Void;
                   });
            ];
          terminator = LV_Ret None;
        };
        { label = "done"; instructions = []; terminator = LV_Ret None };
      ];
    linkage = Private;
  }

(*
  define ptr @syli_ownership_own(ptr %p) {
    %i = ptrtoint ptr %p to i64
    %t = and i64 %i, 1
    %is_borrow = icmp eq i64 %t, 0
    br i1 %is_borrow, label %promote, label %done
  promote:
    call void @syli_rt_object_incr(ptr %p)
    %r = or i64 %i, 1
    %rp = inttoptr i64 %r to ptr
    ret ptr %rp
  done:
    ret ptr %p
  }
*)
let mk_own_fn () : func =
  let incr_fn_ty = LV_Func ([ ptr_ty ], LV_Void) in
  {
    name = "syli_ownership_own";
    ret_type = ptr_ty;
    params = [ (ptr_ty, "p") ];
    blocks =
      [
        {
          label = "bb0";
          instructions =
            [
              assign (local "pi" i64_ty)
                (LV_Cast (LV_PtrToInt, local "p" ptr_ty, i64_ty));
              assign (local "tag" i64_ty)
                (LV_IBinOp
                   ( LV_IBitAnd,
                     local "pi" i64_ty,
                     LV_Constant (LV_Integer 1L, i64_ty) ));
              assign (local "is_borrow" LV_I1)
                (LV_ICmp
                   ( LV_IEq,
                     local "tag" i64_ty,
                     LV_Constant (LV_Integer 0L, i64_ty) ));
            ];
          terminator =
            LV_CondBr (local "is_borrow" LV_I1, "promote", "done");
        };
        {
          label = "promote";
          instructions =
            [
              assign (local "_inc" LV_Void)
                (LV_Call
                   {
                     fn = global "syli_rt_object_incr" incr_fn_ty;
                     args = [ local "p" ptr_ty ];
                     ret_ty = LV_Void;
                   });
              assign (local "r" i64_ty)
                (LV_IBinOp
                   ( LV_IBitOr,
                     local "pi" i64_ty,
                     LV_Constant (LV_Integer 1L, i64_ty) ));
              assign (local "rp" ptr_ty)
                (LV_Cast (LV_IntToPtr, local "r" i64_ty, ptr_ty));
            ];
          terminator = LV_Ret (Some (local "rp" ptr_ty));
        };
        {
          label = "done";
          instructions = [];
          terminator = LV_Ret (Some (local "p" ptr_ty));
        };
      ];
    linkage = Private;
  }

let builtins () : func list =
  [ mk_untag_fn (); mk_borrow_fn (); mk_set_own_fn ();
    mk_release_fn (); mk_own_fn () ]

let builtin_decls () : (string * lltype) list =
  [ ("syli_rt_object_release_owned", LV_Func ([ LV_Ptr ], LV_Void));
    ("syli_rt_object_incr", LV_Func ([ LV_Ptr ], LV_Void)) ]
