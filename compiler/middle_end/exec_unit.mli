(** Prepares a compiled module for execution.

    Auto-generates the call of [syli_modules_init] and [syli_startup_program] *)

val prepare_module : Pipeline_types.rir_ctx -> Pipeline_types.rir_ctx
