{.used.}

# Startup Code
# ------------

{.compile: "./gba_crt0.s".}

proc acsl_initMemMgr() {.importc.}
acsl_initMemMgr()

# ACSL Routines
# -------------

const acslPath = currentSourcePath[0..^33] & "/vendor/acsl"
const acslAsmFlags = "-Wa,-I" & acslPath & "/asminc,-I" & acslPath # base path needed for font
const acslCFlags = "-g -O2 -fno-strict-aliasing"

{.compile(acslPath & "/acsl/bluescreen.s", acslAsmFlags).}
# {.compile(acslPath & "/acsl/crt0.s", acslAsmFlags).}   # we have our own crt0.
{.compile(acslPath & "/acsl/render_text.s", acslAsmFlags).}
{.compile(acslPath & "/acsl/retzero.s", acslAsmFlags).}
{.compile(acslPath & "/acsl/tenpowers.s", acslAsmFlags).}
{.compile(acslPath & "/ctype/isxxxx.s", acslAsmFlags).}
{.compile(acslPath & "/ctype/tolower_toupper.s", acslAsmFlags).}
{.compile(acslPath & "/math/copysign.c", acslCFlags).}
{.compile(acslPath & "/math/copysignf.c", acslCFlags).}
{.compile(acslPath & "/math/fabs.c", acslCFlags).}
{.compile(acslPath & "/math/fabsf.c", acslCFlags).}
{.compile(acslPath & "/math/isnana.c", acslCFlags).}
{.compile(acslPath & "/math/isnanfa.c", acslCFlags).}
{.compile(acslPath & "/math/isnanft.c", acslCFlags).}
{.compile(acslPath & "/math/isnant.c", acslCFlags).}
{.compile(acslPath & "/math/ldexpf.s", acslAsmFlags).}
{.compile(acslPath & "/math/ldexp.s", acslAsmFlags).}
{.compile(acslPath & "/math/nan.c", acslCFlags).}
{.compile(acslPath & "/math/nanf.c", acslCFlags).}
{.compile(acslPath & "/stdio/formatstr.s", acslAsmFlags).}
{.compile(acslPath & "/stdio/perror.s", acslAsmFlags).}
{.compile(acslPath & "/stdio/snprintf.s", acslAsmFlags).}
{.compile(acslPath & "/stdio/sprintf.s", acslAsmFlags).}
{.compile(acslPath & "/stdio/stdio_partialimp.s", acslAsmFlags).}
{.compile(acslPath & "/stdio/stdio_unimplemented.s", acslAsmFlags).}
{.compile(acslPath & "/stdio/stdio_vars.c", acslCFlags).}
{.compile(acslPath & "/stdlib/abort.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/abs.c", acslCFlags).}
{.compile(acslPath & "/stdlib/calloc.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/malloc_free.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/realloc.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/div.c", acslCFlags).}
{.compile(acslPath & "/stdlib/errno.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/exit.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/ldiv.c", acslCFlags).}
{.compile(acslPath & "/stdlib/llabs.c", acslCFlags).}
{.compile(acslPath & "/stdlib/lldiv.c", acslCFlags).}
{.compile(acslPath & "/stdlib/rand_srand.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/setjmp.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/strtoany.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/strtod.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/strtof.c", acslCFlags).}
{.compile(acslPath & "/stdlib/strtoll.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/strtol.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/strtoull.s", acslAsmFlags).}
{.compile(acslPath & "/stdlib/strtoul.s", acslAsmFlags).}
{.compile(acslPath & "/string/memchr.s", acslAsmFlags).}
{.compile(acslPath & "/string/memcmp.s", acslAsmFlags).}
# {.compile(acslPath & "/string/memcpy.s", acslAsmFlags).}
# {.compile(acslPath & "/string/memmove.s", acslAsmFlags).}   # buggy :(
# {.compile(acslPath & "/string/memset.s", acslAsmFlags).}
{.compile(acslPath & "/string/strcat.s", acslAsmFlags).}
{.compile(acslPath & "/string/strchr.s", acslAsmFlags).}
{.compile(acslPath & "/string/strcmp.s", acslAsmFlags).}
{.compile(acslPath & "/string/strcpy.s", acslAsmFlags).}
{.compile(acslPath & "/string/strerror.c", acslCFlags).}
{.compile(acslPath & "/string/strlen.s", acslAsmFlags).}
{.compile(acslPath & "/string/strncat.s", acslAsmFlags).}
{.compile(acslPath & "/string/strncmp.s", acslAsmFlags).}
{.compile(acslPath & "/string/strncpy.s", acslAsmFlags).}
{.compile(acslPath & "/string/strspn.s", acslAsmFlags).}
{.compile(acslPath & "/string/strstr.s", acslAsmFlags).}
{.compile(acslPath & "/string/strtok.s", acslAsmFlags).}
{.compile(acslPath & "/wchar/wcslen.s", acslAsmFlags).}

# AGBABI Routines
# ---------------

const agbabiPath = currentSourcePath[0..^33] & "/vendor/agbabi"
const agbabiAsmFlags = "-Wa,-I" & agbabiPath & "/source"

# We use agbabi's memory functions cause they're better tested.
# But we already have a fast memcpy32/16 provided by Tonc, so these have been moved into ROM
# TODO: get rid of Tonc's memcpy32/16, route them to these, and put these ones in IWRAM?

{.compile(agbabiPath & "/source/memcpy.s", agbabiAsmFlags).}
{.compile(agbabiPath & "/source/memmove.s", agbabiAsmFlags).}
{.compile(agbabiPath & "/source/memset.s", agbabiAsmFlags).}
{.compile(agbabiPath & "/source/rmemcpy.s", agbabiAsmFlags).}

# Misc.
# -----
# Make sure panic is always compiled.
import ./panics
