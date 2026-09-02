open Syli_ir.Rir

let mk_ty (ir : ir_type) : ty = { id = fresh_id (); ty = ir }
let void_ty = mk_ty RR_Void
let i32_ty = mk_ty RR_I32
let i8ptr_ty = mk_ty (RR_Obj_Ptr Syli_ir.Oir.Acyclic)

let mk_var (ty : ty) (name : string) : var =
  { id = fresh_id (); fullname = name; ty }

let mk_void_call (name : qualified_name) (args : operand list) : statement =
  let id = fresh_id () in
  let void_var =
    { id; fullname = "__void_" ^ string_of_int id; ty = void_ty }
  in
  {
    id = fresh_id ();
    node = RR_Call { dst = void_var; target = Direct name; args };
    ty = void_ty;
  }

let mk_block (stmts : statement list) (term : terminator_node) : block =
  let tid = fresh_id () in
  let bid = fresh_id () in
  {
    id = bid;
    label_id = 0;
    statements = stmts;
    terminator = { id = tid; node = term };
  }

let mk_fn ~name ~params ~locals ~ret_ty ~visibility (entry : block) :
    function_rir =
  {
    id = fresh_id ();
    name;
    params;
    locals;
    entry_block = entry;
    blocks = [ entry ];
    return_ty = ret_ty;
    visibility;
  }

(** [syli_modules_init()] — calls each module's [__init.{module}] in order *)
let build_modules_init (prog : program_rir) : function_rir =
  let stmts = [ mk_void_call ("__init." ^ prog.name) [] ] in
  mk_fn ~name:"syli_modules_init" ~params:[] ~locals:[] ~ret_ty:void_ty
    ~visibility:CR_Public
    (mk_block stmts (RR_Return None))

(** [syli_startup_program(argc, argv)] — generated per program.

    which calls [syli_modules_init()] runs all module initialisers

    The startup function is linked to the runtime-owned [main] in [libsyli.a].
*)
let build_startup_function () : function_rir =
  let modules_init_stmt = mk_void_call "syli_modules_init" [] in
  let void_var = mk_var void_ty "void_main_ret" in
  mk_fn ~name:"syli_startup_program" ~params:[] ~locals:[ void_var ]
    ~ret_ty:i32_ty ~visibility:CR_Public
    (mk_block [ modules_init_stmt ]
       (RR_Return (Some (RR_OConstant (RR_IntLit "0", i32_ty)))))

let prepare_module_internal (prog : program_rir) : program_rir =
  let modules_init_fn = build_modules_init prog in
  let startup_fn = build_startup_function () in
  { prog with functions = startup_fn :: modules_init_fn :: prog.functions }

let prepare_module (ctx : Pipeline_types.rir_ctx) : Pipeline_types.rir_ctx =
  {
    module_rir = prepare_module_internal ctx.module_rir;
    apply_gen_functions = ctx.apply_gen_functions;
  }
