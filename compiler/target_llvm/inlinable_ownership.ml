open Syli_common
(** LLVM function definitions for ownership bit operations. These are appended
    to the module after lowering, so clang -O3 can inline them into call sites.
*)

open Llvm_lir.Types

let global (n : string) (ty : lltype) : operand = LV_Global (n, ty)
let local name ty = LV_Local (name, ty)
let assign dst rhs = LV_Assign (dst, rhs)
let i64_ty = LV_I64
let ptr_ty = LV_Ptr_as 1

(*
  define ptr @syli_inlinable_ownership_untag(ptr %p) {
    %i = ptrtoint ptr %p to i64
    %u = and i64 %i, -4
    %r = inttoptr i64 %u to ptr
    ret ptr %r
  }
*)
let mk_untag_fn () : func =
  {
    name = "syli_inlinable_ownership_untag";
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
                     LV_Constant (LV_Integer (-4L), i64_ty) ));
              assign (local "r" ptr_ty)
                (LV_Cast (LV_IntToPtr, local "u" i64_ty, ptr_ty));
            ];
          terminator = LV_Ret (Some (local "r" ptr_ty));
        };
      ];
    linkage = Private;
    attributes = [];
  }

(*
  define ptr @syli_inlinable_ownership_borrow(ptr %p) {
    %i = ptrtoint ptr %p to i64
    %b1 = lshr i64 %i, 1
    %b1m = and i64 %b1, 1
    %m = or i64 %b1m, -2
    %u = and i64 %i, %m
    %r = inttoptr i64 %u to ptr
    ret ptr %r
  }

  Ownership tags (low 2 bits): 00 borrow, 01 own, 10 always-borrow,
  11 immediate (constant variant). Borrow maps 01 -> 00 and keeps 00, while
  leaving 10 and 11 untouched; so bit 0 is cleared only when bit 1 is clear,
  i.e. the mask is all-ones for tags 10/11 and ~1 for tags 00/01. This is why
  a plain `and i64 %i, -2` is not enough: it would turn 11 into 10.
*)
let mk_borrow_fn () : func =
  {
    name = "syli_inlinable_ownership_borrow";
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
              assign (local "b1" i64_ty)
                (LV_IBinOp
                   ( LV_ILShr,
                     local "i" i64_ty,
                     LV_Constant (LV_Integer 1L, i64_ty) ));
              assign (local "b1m" i64_ty)
                (LV_IBinOp
                   ( LV_IBitAnd,
                     local "b1" i64_ty,
                     LV_Constant (LV_Integer 1L, i64_ty) ));
              assign (local "m" i64_ty)
                (LV_IBinOp
                   ( LV_IBitOr,
                     local "b1m" i64_ty,
                     LV_Constant (LV_Integer (-2L), i64_ty) ));
              assign (local "u" i64_ty)
                (LV_IBinOp (LV_IBitAnd, local "i" i64_ty, local "m" i64_ty));
              assign (local "r" ptr_ty)
                (LV_Cast (LV_IntToPtr, local "u" i64_ty, ptr_ty));
            ];
          terminator = LV_Ret (Some (local "r" ptr_ty));
        };
      ];
    linkage = Private;
    attributes = [];
  }

(*
  define void @syli_inlinable_ownership_release(ptr %p) {
    %pi = ptrtoint ptr %p to i64
    %tag = and i64 %pi, 3
    %is_own = icmp eq i64 %tag, 1
    br i1 %is_own, label %own, label %done
  own:
    call void @syli_rt_ownership_decr(ptr %p)
    ret void
  done:
    ret void
  }
*)
let mk_release_fn () : func =
  let owned_fn_ty = LV_Func ([ ptr_ty ], LV_Void) in
  {
    name = "syli_inlinable_ownership_release";
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
                     LV_Constant (LV_Integer 3L, i64_ty) ));
              assign (local "is_own" LV_I1)
                (LV_ICmp
                   ( LV_IEq,
                     local "tag" i64_ty,
                     LV_Constant (LV_Integer 1L, i64_ty) ));
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
                     fn = global "syli_rt_ownership_decr" owned_fn_ty;
                     args = [ local "p" ptr_ty ];
                     ret_ty = LV_Void;
                   });
            ];
          terminator = LV_Ret None;
        };
        { label = "done"; instructions = []; terminator = LV_Ret None };
      ];
    linkage = Private;
    attributes = [];
  }

(*
  define ptr @syli_inlinable_ownership_own(ptr %p) {
    %i = ptrtoint ptr %p to i64
    %t = and i64 %i, 3
    %is_borrow = icmp eq i64 %t, 0
    br i1 %is_borrow, label %promote, label %done
  promote:
    %r = or i64 %i, 1
    %rp = inttoptr i64 %r to ptr
    call void @syli_rt_ownership_incr(ptr %rp)
    ret ptr %rp
  done:
    ret ptr %p
  }
*)
let mk_own_fn () : func =
  let incr_fn_ty = LV_Func ([ ptr_ty ], LV_Void) in
  {
    name = "syli_inlinable_ownership_own";
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
                     LV_Constant (LV_Integer 3L, i64_ty) ));
              assign (local "is_borrow" LV_I1)
                (LV_ICmp
                   ( LV_IEq,
                     local "tag" i64_ty,
                     LV_Constant (LV_Integer 0L, i64_ty) ));
            ];
          terminator = LV_CondBr (local "is_borrow" LV_I1, "promote", "done");
        };
        {
          label = "promote";
          instructions =
            [
              assign (local "r" i64_ty)
                (LV_IBinOp
                   ( LV_IBitOr,
                     local "pi" i64_ty,
                     LV_Constant (LV_Integer 1L, i64_ty) ));
              assign (local "rp" ptr_ty)
                (LV_Cast (LV_IntToPtr, local "r" i64_ty, ptr_ty));
              assign (local "_inc" LV_Void)
                (LV_Call
                   {
                     fn = global "syli_rt_ownership_incr" incr_fn_ty;
                     args = [ local "rp" ptr_ty ];
                     ret_ty = LV_Void;
                   });
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
    attributes = [];
  }

(*
  define ptr @syli_inlinable_ownership_share(ptr %p) {
    %i = ptrtoint ptr %p to i64
    %t = and i64 %i, 2
    %is_always = icmp ne i64 %t, 0
    br i1 %is_always, label %done, label %promote
  promote:
    %r = or i64 %i, 1
    %rp = inttoptr i64 %r to ptr
    call void @syli_rt_ownership_incr(ptr %rp)
    ret ptr %rp
  done:
    ret ptr %p
  }
*)
let mk_share_fn () : func =
  let incr_fn_ty = LV_Func ([ ptr_ty ], LV_Void) in
  {
    name = "syli_inlinable_ownership_share";
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
                     LV_Constant (LV_Integer 2L, i64_ty) ));
              assign (local "is_always" LV_I1)
                (LV_ICmp
                   ( LV_INe,
                     local "tag" i64_ty,
                     LV_Constant (LV_Integer 0L, i64_ty) ));
            ];
          terminator = LV_CondBr (local "is_always" LV_I1, "done", "promote");
        };
        {
          label = "promote";
          instructions =
            [
              assign (local "r" i64_ty)
                (LV_IBinOp
                   ( LV_IBitOr,
                     local "pi" i64_ty,
                     LV_Constant (LV_Integer 1L, i64_ty) ));
              assign (local "rp" ptr_ty)
                (LV_Cast (LV_IntToPtr, local "r" i64_ty, ptr_ty));
              assign (local "_inc" LV_Void)
                (LV_Call
                   {
                     fn = global "syli_rt_ownership_incr" incr_fn_ty;
                     args = [ local "rp" ptr_ty ];
                     ret_ty = LV_Void;
                   });
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
    attributes = [];
  }

(*
  define ptr @syli_inlinable_ownership_make_always_borrow(ptr %p) {
    %i = ptrtoint ptr %p to i64
    %u = and i64 %i, -4
    %r = or i64 %u, 2
    %rp = inttoptr i64 %r to ptr
    ret ptr %rp
  }
*)
let mk_make_always_borrow_fn () : func =
  {
    name = "syli_inlinable_ownership_make_always_borrow";
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
                     LV_Constant (LV_Integer (-4L), i64_ty) ));
              assign (local "r" i64_ty)
                (LV_IBinOp
                   ( LV_IBitOr,
                     local "u" i64_ty,
                     LV_Constant (LV_Integer 2L, i64_ty) ));
              assign (local "rp" ptr_ty)
                (LV_Cast (LV_IntToPtr, local "r" i64_ty, ptr_ty));
            ];
          terminator = LV_Ret (Some (local "rp" ptr_ty));
        };
      ];
    linkage = Private;
    attributes = [];
  }

(*
  define i64 @syli_inlinable_get_object_tag(ptr addrspace(1) %p) {
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
*)
let mk_get_object_tag_fn () : func =
  {
    name = "syli_inlinable_get_object_tag";
    ret_type = i64_ty;
    params = [ (ptr_ty, "p") ];
    blocks =
      [
        {
          label = "bb0";
          instructions =
            [
              assign (local "i" i64_ty)
                (LV_Cast (LV_PtrToInt, local "p" ptr_ty, i64_ty));
              assign (local "own" i64_ty)
                (LV_IBinOp
                   ( LV_IBitAnd,
                     local "i" i64_ty,
                     LV_Constant (LV_Integer 3L, i64_ty) ));
              assign (local "lo" LV_I1)
                (LV_ICmp
                   ( LV_IEq,
                     local "own" i64_ty,
                     LV_Constant (LV_Integer 3L, i64_ty) ));
            ];
          terminator = LV_CondBr (local "lo" LV_I1, "imm", "obj");
        };
        {
          label = "imm";
          instructions =
            [
              assign (local "it" i64_ty)
                (LV_IBinOp
                   ( LV_ILShr,
                     local "i" i64_ty,
                     LV_Constant (LV_Integer 2L, i64_ty) ));
            ];
          terminator = LV_Ret (Some (local "it" i64_ty));
        };
        {
          label = "obj";
          instructions =
            [
              assign (local "u" i64_ty)
                (LV_IBinOp
                   ( LV_IBitAnd,
                     local "i" i64_ty,
                     LV_Constant (LV_Integer (-4L), i64_ty) ));
              assign (local "up" ptr_ty)
                (LV_Cast (LV_IntToPtr, local "u" i64_ty, ptr_ty));
              assign (local "h" i64_ty)
                (LV_Load { ptr = local "up" ptr_ty; ty = i64_ty });
              assign (local "t" i64_ty)
                (LV_IBinOp
                   ( LV_ILShr,
                     local "h" i64_ty,
                     LV_Constant (LV_Integer 48L, i64_ty) ));
              assign (local "r" i64_ty)
                (LV_IBinOp
                   ( LV_IBitAnd,
                     local "t" i64_ty,
                     LV_Constant (LV_Integer 255L, i64_ty) ));
            ];
          terminator = LV_Ret (Some (local "r" i64_ty));
        };
      ];
    linkage = Private;
    attributes = [];
  }

(*
  define void @syli_inlinable_ownership_notify_mutation(ptr %obj, ptr %value) {
    %vi = ptrtoint ptr %value to i64
    %tag = and i64 %vi, 3
    %imm = icmp eq i64 %tag, 3
    br i1 %imm, label %done, label %notify
  notify:
    call void @syli_rt_ownership_notify_mutation(ptr %obj, ptr %value)
    ret void
  done:
    ret void
  }
*)
let mk_notify_mutation_fn () : func =
  let notify_fn_ty = LV_Func ([ ptr_ty; ptr_ty ], LV_Void) in
  {
    name = "syli_inlinable_ownership_notify_mutation";
    ret_type = LV_Void;
    params = [ (ptr_ty, "obj"); (ptr_ty, "value") ];
    blocks =
      [
        {
          label = "bb0";
          instructions =
            [
              assign (local "vi" i64_ty)
                (LV_Cast (LV_PtrToInt, local "value" ptr_ty, i64_ty));
              assign (local "tag" i64_ty)
                (LV_IBinOp
                   ( LV_IBitAnd,
                     local "vi" i64_ty,
                     LV_Constant (LV_Integer 3L, i64_ty) ));
              assign (local "imm" LV_I1)
                (LV_ICmp
                   ( LV_IEq,
                     local "tag" i64_ty,
                     LV_Constant (LV_Integer 3L, i64_ty) ));
            ];
          terminator = LV_CondBr (local "imm" LV_I1, "done", "notify");
        };
        {
          label = "notify";
          instructions =
            [
              assign (local "_r" LV_Void)
                (LV_Call
                   {
                     fn =
                       global "syli_rt_ownership_notify_mutation" notify_fn_ty;
                     args = [ local "obj" ptr_ty; local "value" ptr_ty ];
                     ret_ty = LV_Void;
                   });
            ];
          terminator = LV_Ret None;
        };
        { label = "done"; instructions = []; terminator = LV_Ret None };
      ];
    linkage = Private;
    attributes = [];
  }

let builtins () : func list =
  [
    mk_untag_fn ();
    mk_borrow_fn ();
    mk_release_fn ();
    mk_own_fn ();
    mk_share_fn ();
    mk_make_always_borrow_fn ();
    mk_get_object_tag_fn ();
    mk_notify_mutation_fn ();
  ]

let gated_inlinables =
  [
    "syli_inlinable_get_object_tag"; "syli_inlinable_ownership_notify_mutation";
  ]

let is_gated_inlinable (name : string) : bool = List.mem name gated_inlinables

let builtin_decls (used : StringSet.t) : (string * lltype) list =
  let base =
    [
      ("syli_rt_ownership_decr", LV_Func ([ LV_Ptr_as 1 ], LV_Void));
      ("syli_rt_ownership_incr", LV_Func ([ LV_Ptr_as 1 ], LV_Void));
    ]
  in
  let notify_decl =
    if StringSet.mem "syli_inlinable_ownership_notify_mutation" used then
      [
        ( "syli_rt_ownership_notify_mutation",
          LV_Func ([ LV_Ptr_as 1; LV_Ptr_as 1 ], LV_Void) );
      ]
    else []
  in
  base @ notify_decl

let inlinable_runtime_functions =
  let open Syli_ir.Rir in
  StringMap.of_list
    [
      ( runtime_op_name_to_string RR_RT_object_borrow,
        "syli_inlinable_ownership_borrow" );
      ( runtime_op_name_to_string RR_RT_object_own,
        "syli_inlinable_ownership_own" );
      ( runtime_op_name_to_string RR_RT_object_share,
        "syli_inlinable_ownership_share" );
      ( runtime_op_name_to_string RR_RT_object_release,
        "syli_inlinable_ownership_release" );
      ( runtime_op_name_to_string RR_RT_object_make_always_borrow,
        "syli_inlinable_ownership_make_always_borrow" );
      ( runtime_op_name_to_string RR_RT_get_object_tag,
        "syli_inlinable_get_object_tag" );
      ( runtime_op_name_to_string RR_RT_object_check_mutation,
        "syli_inlinable_ownership_notify_mutation" );
    ]

let use_if_inlinable_runtime_function rt_fn_name =
  let rt_fn_name = Syli_ir.Rir.runtime_op_name_to_string rt_fn_name in
  match StringMap.find_opt rt_fn_name inlinable_runtime_functions with
  | Some fn -> Some fn
  | None -> None
