from natu/oam import ObjSize

export ObjSize

type
  GraphicData* = object
    bpp*: int
    size*: ObjSize
    w*, h*: int
    imgPos*: int
    imgWords*: int
    palNum*: int
    palPos*: int
    palHalfwords*: int
    frames*: int
    frameWords*: int
  
  BgKind* = enum
    bkReg4bpp  ## Regular background, 16 colors per-tile
    bkReg8bpp  ## Regular background, 256 colors
    bkAff      ## Affine background, 256 colors
  
  BgFlag* = enum
    bfScreenblock
    bfBlankTile
    bfAutoPal
  
  BgData* = object
    kind*: BgKind
    w*, h*: int
    imgWords*: uint16
    mapWords*: uint16
    palHalfwords*: uint16
    palOffset*: uint16
    tileOffset*: uint16
    flags*: set[BgFlag]
