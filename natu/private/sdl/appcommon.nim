# import ./mgbavid

type
  NatuSource* {.borrow.} = distinct pointer
    ## A thing that emits audio

proc `==`*(a, b: NatuSource): bool {.borrow.}
proc isNil*(a: NatuSource): bool {.borrow.}

type
  LoopKind* = enum
    LoopNone
    LoopForward
    LoopPingPong
  
  SampleInfo* = object
    dataStart*: uint32   # measured in floats
    dataEnd*: uint32     # .. (exclusive)
    channels*: uint16
    sampleRate*: uint32
    loopKind*: LoopKind
    loopStart*: uint32  # measured in samples (mono or stereo)
    loopEnd*: uint32    # ..
  
  NatuAppMem* = object
    regs*: array[0x200, uint16]
    palram*: array[512, uint16]
    vram*: array[0xC000, uint16]
    oam*: array[512, uint32]
    
    # api:
    panic*: proc (msg1: cstring; msg2: cstring = nil) {.nimcall.}
    setSampleData*: proc (data: pointer) {.nimcall.}
    createSourceFromSample*: proc (smp: ptr SampleInfo): NatuSource {.nimcall.}
    createSourceFromFile*: proc (f: cstring; loop: bool): NatuSource {.nimcall.}
    destroySource*: proc (s: NatuSource) {.nimcall.}
    playSource*: proc (s: NatuSource) {.nimcall.}
    pauseSource*: proc (s: NatuSource) {.nimcall.}
    stopSource*: proc (s: NatuSource) {.nimcall.}
    setSourceRate*: proc (s: NatuSource, rate: float32) {.nimcall.}
    setSourceVolume*: proc (s: NatuSource, vol: float32) {.nimcall.}
    setSourcePanning*: proc (s: NatuSource, pan: float32) {.nimcall.}
    setSourcePosition*: proc (s: NatuSource, pos: float32) {.nimcall.}
