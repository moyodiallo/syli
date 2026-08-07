/* Place the .llvm_stackmaps section and define the bounds symbols that the
 * runtime parses between. */
SECTIONS
{
  .llvm_stackmaps : {
    __start_llvm_stackmaps = .;
    KEEP(*(.llvm_stackmaps))
    __stop_llvm_stackmaps = .;
  }
} INSERT AFTER .rodata;
