# Constants needed to compile individual source files from libtonc

const toncPath* = currentSourcePath[0..^25] & "/vendor/libtonc"
const toncCFlags* = "-g -O2 -fno-strict-aliasing"
const toncAsmFlags* = "-g -x assembler-with-cpp"
