# import ./mgbavid

type
  NatuMusic* {.borrow.} = distinct pointer
  NatuSample* {.borrow.} = distinct pointer  # corresponds to an SDL_Mixer 'Chunk'

proc `==`*(a, b: NatuMusic): bool {.borrow.}
proc isNil*(a: NatuMusic): bool {.borrow.}

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
    
    loadMusic*: proc (f: cstring): NatuMusic {.nimcall.}
    freeMusic*: proc (music: NatuMusic) {.nimcall.}
    startMusic*: proc (music: NatuMusic; loops: cint) {.nimcall.}
    pauseMusic*: proc () {.nimcall.}
    resumeMusic*: proc () {.nimcall.}
    stopMusic*: proc () {.nimcall.}
    setMusicPosition*: proc (pos: cdouble) {.nimcall.}
    setMusicVolume*: proc (vol: cfloat) {.nimcall.}
    loadSample*: proc (f: cstring): NatuSample {.nimcall.}
    freeSample*: proc (sample: NatuSample) {.nimcall.}
    playSample*: proc (sample: NatuSample) {.nimcall.}
