# Constants needed to compile individual source files from libtonc

const toncPath* = currentSourcePath[0..^25] & "/vendor/libtonc"
const toncCFlags* = "-g -O2 -fno-strict-aliasing"
const toncAsmFlags* = "-g -x assembler-with-cpp"

const natuOutputDir* {.strdefine.} = ""
const natuConfigDir* {.strdefine.} = ""

when natuOutputDir == "": {.error: "natuOutputDir is not set.".}
when natuConfigDir == "": {.error: "natuConfigDir is not set.".}

template doInclude*(path: static string) =
  include `path`
