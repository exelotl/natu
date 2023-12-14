# import ./mgbavid

type
  NatuAppMem* = object
    regs*: array[0x400, uint16]
    palram*: array[512, uint16]
    vram*: array[0xC000, uint16]
    oam*: array[128, uint64]
