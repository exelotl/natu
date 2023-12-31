# import ./mgbavid

type
  NatuSource* {.borrow.} = distinct pointer
    ## A thing that emits audio
  
  NatuSample* {.borrow.} = distinct pointer
    ## RAW PCM data in memory (can be used by a NatuSource)

proc `==`*(a, b: NatuSource): bool {.borrow.}
proc isNil*(a: NatuSource): bool {.borrow.}

proc `==`*(a, b: NatuSample): bool {.borrow.}
proc isNil*(a: NatuSample): bool {.borrow.}

type
  NatuAppMem* = object
    regs*: array[0x200, uint16]
    palram*: array[512, uint16]
    vram*: array[0xC000, uint16]
    oam*: array[512, uint32]
    
    # api:
    panic*: proc (msg1: cstring; msg2: cstring = nil) {.nimcall.}
    
    createSample*: proc (f: cstring): NatuSample {.nimcall.}
    destroySample*: proc (smp: NatuSample) {.nimcall.}
    
    createSourceFromSample*: proc (smp: NatuSample): NatuSource {.nimcall.}
    createSourceFromFile*: proc (f: cstring; loop: bool): NatuSource {.nimcall.}
    destroySource*: proc (s: NatuSource) {.nimcall.}
    playSource*: proc (s: NatuSource) {.nimcall.}
    pauseSource*: proc (s: NatuSource) {.nimcall.}
    stopSource*: proc (s: NatuSource) {.nimcall.}
    setSourceRate*: proc (s: NatuSource, rate: float32) {.nimcall.}
