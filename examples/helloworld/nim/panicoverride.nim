# This module is required for --os:standalone to work

proc exit(code: int) {.importc, header: "<stdlib.h>", cdecl.}

{.push stack_trace: off, profiler:off.}


{.emit: """/*INCLUDESECTION*/
#include <tonc_types.h>
#define REG_DEBUG_ENABLE *(vu16*)0x4FFF780
#define REG_DEBUG_FLAGS *(vu16*)0x4FFF700
#define REG_DEBUG_STRING *(char*)0x4FFF600
""".}

var REG_DEBUG_ENABLE {.importc:"REG_DEBUG_ENABLE", nodecl.}: uint16
var REG_DEBUG_FLAGS {.importc:"REG_DEBUG_FLAGS", nodecl.}: uint16
var REG_DEBUG_STRING {.importc:"REG_DEBUG_STRING", nodecl.}: cstring

# log fatal message to mGBA

proc rawoutput(s: cstring) =
  REG_DEBUG_ENABLE = 0xC0DE
  copyMem(addr REG_DEBUG_STRING, s, 256)
  REG_DEBUG_FLAGS = 0x100

proc panic(s: string) {.noreturn.} =
  rawoutput(s)
  exit(1)

{.pop.}
