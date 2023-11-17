{.used.}

# Startup Code
# ------------

{.compile: "./gba_crt0.s".}

proc acsl_initMemMgr() {.importc.}
acsl_initMemMgr()

# ACSL Routines
# -------------

const acslPath = currentSourcePath[0..^29] & "/vendor/acsl"
const acslAsmFlags = "-Wa,-I" & acslPath & "/asminc,-I" & acslPath # base path needed for font
const acslCFlags = "-g -O2 -fno-strict-aliasing"

{.compile("../../vendor/acsl/acsl/bluescreen.s", acslAsmFlags).}
# {.compile("../../vendor/acsl/acsl/crt0.s", acslAsmFlags).}   # we have our own crt0.
{.compile("../../vendor/acsl/acsl/render_text.s", acslAsmFlags).}
{.compile("../../vendor/acsl/acsl/retzero.s", acslAsmFlags).}
{.compile("../../vendor/acsl/acsl/tenpowers.s", acslAsmFlags).}
{.compile("../../vendor/acsl/ctype/isxxxx.s", acslAsmFlags).}
{.compile("../../vendor/acsl/ctype/tolower_toupper.s", acslAsmFlags).}
{.compile("../../vendor/acsl/math/copysign.c", acslCFlags).}
{.compile("../../vendor/acsl/math/copysignf.c", acslCFlags).}
{.compile("../../vendor/acsl/math/fabs.c", acslCFlags).}
{.compile("../../vendor/acsl/math/fabsf.c", acslCFlags).}
{.compile("../../vendor/acsl/math/isnana.c", acslCFlags).}
{.compile("../../vendor/acsl/math/isnanfa.c", acslCFlags).}
{.compile("../../vendor/acsl/math/isnanft.c", acslCFlags).}
{.compile("../../vendor/acsl/math/isnant.c", acslCFlags).}
{.compile("../../vendor/acsl/math/ldexpf.s", acslAsmFlags).}
{.compile("../../vendor/acsl/math/ldexp.s", acslAsmFlags).}
{.compile("../../vendor/acsl/math/nan.c", acslCFlags).}
{.compile("../../vendor/acsl/math/nanf.c", acslCFlags).}
{.compile("../../vendor/acsl/stdio/formatstr.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdio/perror.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdio/snprintf.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdio/sprintf.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdio/stdio_partialimp.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdio/stdio_unimplemented.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdio/stdio_vars.c", acslCFlags).}
{.compile("../../vendor/acsl/stdlib/abort.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/abs.c", acslCFlags).}
{.compile("../../vendor/acsl/stdlib/calloc.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/malloc_free.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/realloc.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/div.c", acslCFlags).}
{.compile("../../vendor/acsl/stdlib/errno.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/exit.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/ldiv.c", acslCFlags).}
{.compile("../../vendor/acsl/stdlib/llabs.c", acslCFlags).}
{.compile("../../vendor/acsl/stdlib/lldiv.c", acslCFlags).}
{.compile("../../vendor/acsl/stdlib/rand_srand.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/setjmp.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/strtoany.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/strtod.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/strtof.c", acslCFlags).}
{.compile("../../vendor/acsl/stdlib/strtoll.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/strtol.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/strtoull.s", acslAsmFlags).}
{.compile("../../vendor/acsl/stdlib/strtoul.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/memchr.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/memcmp.s", acslAsmFlags).}
# {.compile("../../vendor/acsl/string/memcpy.s", acslAsmFlags).}
# {.compile("../../vendor/acsl/string/memmove.s", acslAsmFlags).}   # buggy :(
# {.compile("../../vendor/acsl/string/memset.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/strcat.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/strchr.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/strcmp.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/strcpy.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/strerror.c", acslCFlags).}
{.compile("../../vendor/acsl/string/strlen.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/strncat.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/strncmp.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/strncpy.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/strspn.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/strstr.s", acslAsmFlags).}
{.compile("../../vendor/acsl/string/strtok.s", acslAsmFlags).}
{.compile("../../vendor/acsl/wchar/wcslen.s", acslAsmFlags).}

# AGBABI Routines
# ---------------

const agbabiPath = currentSourcePath[0..^29] & "/vendor/agbabi"
const agbabiAsmFlags = "-Wa,-I" & agbabiPath & "/source"

# We use agbabi's memory functions cause they're better tested.
# But we already have a fast memcpy32/16 provided by Tonc, so these have been moved into ROM
# TODO: get rid of Tonc's memcpy32/16, route them to these, and put these ones in IWRAM?

{.compile("../../vendor/agbabi/source/memcpy.s", agbabiAsmFlags).}
{.compile("../../vendor/agbabi/source/memmove.s", agbabiAsmFlags).}
{.compile("../../vendor/agbabi/source/memset.s", agbabiAsmFlags).}
{.compile("../../vendor/agbabi/source/rmemcpy.s", agbabiAsmFlags).}

# Misc.
# -----
# Make sure panic is always compiled.
import ./panics
