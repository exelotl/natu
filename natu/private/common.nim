# Constants needed to compile individual source files from libtonc

const toncPath* = "../../vendor/libtonc"
const toncCFlags* = "-g -O2 -fno-strict-aliasing"
const toncAsmFlags* = "-g -x assembler-with-cpp"

# Essential sources needed for the panic handler

{.compile(toncPath & "/asm/tonc_memcpy.s", toncAsmFlags).}
{.compile(toncPath & "/asm/tonc_memset.s", toncAsmFlags).}

{.compile(toncPath & "/asm/tonc_bios.s", toncAsmFlags).}
{.compile(toncPath & "/asm/tonc_bios_ex.s", toncAsmFlags).}

{.compile(toncPath & "/src/tonc_surface.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_schr4c.c", toncCFlags).}

{.compile(toncPath & "/src/font/sys8.s", toncAsmFlags).}
{.compile(toncPath & "/src/font/verdana9.s", toncAsmFlags).}
{.compile(toncPath & "/src/tte/chr4c_drawg_b1cts.c", toncCFlags).}
{.compile(toncPath & "/src/tte/tte_main.c", toncCFlags).}
{.compile(toncPath & "/src/tte/tte_init_chr4c.c", toncCFlags).}
{.compile(toncPath & "/src/tte/tte_types.s", toncAsmFlags).}
