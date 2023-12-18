# import ./mgbavid

type
  NatuAppMem* = object
    regs*: array[0x200, uint16]
    palram*: array[512, uint16]
    vram*: array[0xC000, uint16]
    oam*: array[512, uint32]
    
    # api:
    panic*: proc (msg1: cstring; msg2: cstring = nil) {.nimcall.}
