# Tonc core functionality
# =======================

import common
import types

{.compile(toncPath & "/src/tonc_core.c", toncCFlags).}
{.compile(toncPath & "/asm/tonc_memcpy.s", toncAsmFlags).}
{.compile(toncPath & "/asm/tonc_memset.s", toncAsmFlags).}
# {.compile(toncPath & "/asm/tonc_nocash.s", toncAsmFlags).}  # Natu doesn't do nocash debugging yet.

{.pragma: tonc, header: "tonc_core.h".}
{.pragma: toncinl, header: "tonc_core.h".}  # indicates that the definition is in the header.

