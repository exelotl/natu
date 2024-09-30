{.compile(toncPath & "/asm/tonc_memcpy.s", toncAsmFlags).}
{.compile(toncPath & "/asm/tonc_memset.s", toncAsmFlags).}

{.pragma: tonc, header: "tonc_core.h".}
{.pragma: toncinl, header: "tonc_core.h".}  # indicates that the definition is in the header.

const natuMgbaLogging {.booldefine.} = true
const natuLogMode {.strdefine.} = (if natuMgbaLogging: "mgba" else: "none")

when natuLogMode == "mgba":
  
  import ../../mgba
  template natuLogImpl*(s: cstring; args: varargs[typed]) =
    printf(s, args)

elif natuLogMode == "none":
  
  template natuLogImpl*(s: cstring; args: varargs[typed]) =
    discard

else:
  {.error: "Unknown log mode " & natuLogMode.}


# Tonc memory functions
# ---------------------

proc memset16*(dst: pointer, hw: uint16, hwcount: SomeInteger) {.importc, tonc.}
  ## Fastfill for halfwords, analogous to memset()
  ## 
  ## Uses `memset32()` if `hwcount > 5`
  ## 
  ## :dst:     Destination address.
  ## :hw:      Source halfword (not address).
  ## :hwcount: Number of halfwords to fill.
  ## 
  ## .. note::
  ##    | `dst` *must* be halfword aligned.
  ##    | `r0` returns as `dst + hwcount*2`.

proc memcpy16*(dst: pointer, src: pointer, hwcount: SomeInteger) {.importc, tonc.}
  ## Copy for halfwords.
  ## 
  ## Uses `memcpy32()` if `hwcount > 6` and `src` and `dst` are aligned equally.
  ## 
  ## :dst:     Destination address.
  ## :src:     Source address.
  ## :hwcount: Number of halfwords to fill.
  ## 
  ## .. note::
  ##    | `dst` and `src` *must* be halfword aligned.
  ##    | `r0` and `r1` return as `dst + hwcount*2` and `src + hwcount*2`.

proc memset32*(dst: pointer, wd: uint32, wcount: SomeInteger) {.importc, tonc.}
  ## Fast-fill by words, analogous to memset()
  ## 
  ## Like CpuFastSet(), only without the requirement of 32byte chunks and no awkward store-value-in-memory-first issue.
  ## 
  ## :dst:     Destination address.
  ## :wd:      Fill word (not address).
  ## :wcount:  Number of words to fill.
  ## 
  ## .. note::
  ##    | `dst` *must* be word aligned.
  ##    | `r0` returns as `dst + wcount*4`.

proc memcpy32*(dst: pointer, src: pointer, wcount: SomeInteger) {.importc, tonc.}
  ## Fast-copy by words.
  ## 
  ## Like :xref:`CpuFastFill`, only without the requirement of 32byte chunks
  ## 
  ## :dst:     Destination address.
  ## :src:     Source address.
  ## :wcount:  Number of words.
  ## 
  ## .. note ::
  ##    | `src` and `dst` *must* be word aligned.
  ##    | `r0` and `r1` return as `dst + wcount*4` and `src + wcount*4`.