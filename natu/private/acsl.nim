const AcslAsmFlags = "-I" & currentSourcePath[0..^22] & "/vendor/acsl/asminc"

{.compile("../../vendor/acsl/stdlib/calloc.s", AcslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/errno.s", AcslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/malloc_free.s", AcslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/realloc.s", AcslAsmFlags).}

proc acsl_initMemMgr() {.importc.}

acsl_initMemMgr()
