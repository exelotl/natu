import natu/[utils, video, bios]
import natu/kit/pal_manager
from natu/private/common import doInclude, natuOutputDir

type
  BgKind* = enum
    bkReg4bpp  ## Regular background, 16 colors per-tile
    bkReg8bpp  ## Regular background, 256 colors
    bkAff      ## Affine background, 256 colors
  
  BgFlag* = enum
    bfScreenblock
    bfBlankTile
    bfAutoPal
  
  CompressionKind* = enum  # TODO: move this outta here in the future.
    None
    # Lz77
    # Huff
    Rle
  
  BgData* = object
    kind*: BgKind
    w*, h*: int
    imgWords*: uint16
    mapWords*: uint16
    palHalfwords*: uint16
    palOffset*: uint16
    tileOffset*: uint16
    flags*: set[BgFlag]
    regions*: seq[BgRegion]
    tileComp*: CompressionKind
    mapComp*: CompressionKind
  
  BgRegionLayout* = enum
    Chr4c
    Chr4r
  
  BgRegion* = tuple[layout: BgRegionLayout; x1, y1, x2, y2: int]

doInclude natuOutputDir & "/backgrounds.nim"

template kind*(bg: Background): BgKind = bg.data.kind
template flags*(bg: Background): set[BgFlag] = bg.data.flags
template regions*(bg: Background): seq[BgRegion] = bg.data.regions
template palOffset*(bg: Background): int = bg.data.palOffset.int
template tileOffset*(bg: Background): int = bg.data.tileOffset.int
template tileComp*(bg: Background): CompressionKind = bg.data.tileComp
template mapComp*(bg: Background): CompressionKind = bg.data.mapComp

template is8bpp*(bg: Background): bool =
  bg.data.kind in {bkReg8bpp, bkAff}


proc loadTiles*(bg: Background; dest: pointer) {.inline.} =
  ## 
  ## Copy a background's tile image data to some location in memory.
  ## 
  ## :bg:   The background asset to use.
  ## :dest: The location to copy the tileset to.
  ## 
  ## If your BG asset has a tileOffset specified, be sure to add that
  ## to the destination before calling this.
  ## 
  case bg.tileComp
  of None:
    memcpy32(dest, bg.imgDataPtr, bg.data.imgWords)
  of Rle:
    RLUnCompVram(bg.imgDataPtr, dest)


proc loadTiles*(bg: Background; cbb: range[0..3]) {.inline.} =
  ## 
  ## Copy a background's tile image data into VRAM.
  ## 
  ## :bg:  The background asset to use.
  ## :cbb: Character Base Block: The tileset will be copied to this location.
  ## 
  let tileOffset = bg.tileOffset * (if bg.is8bpp: 2 else: 1)
  bg.loadTiles(addr bgTileMem[cbb][tileOffset])


proc loadMap*(bg: Background; dest: pointer) {.inline.} =
  ## 
  ## Copy a background's map data to some location in memory.
  ## 
  ## :bg:   The background asset to use.
  ## :dest: The location to copy the map data to.
  ## 
  case bg.mapComp
  of None:
    memcpy32(dest, bg.mapDataPtr, bg.data.mapWords)
  of Rle:
    RLUnCompVram(bg.mapDataPtr, dest)


proc loadMap*(bg: Background; sbb: range[0..31]) {.inline.} =
  ## 
  ## Copy a background's map data into VRAM.
  ## 
  ## :bg:
  ##   The background asset to use.
  ## 
  ## :sbb:
  ##   Screen Base Block: The map will be copied to this location.
  ##   If there is more than 1 screenblock of data, it will be copied
  ##   over into the next screenblocks.
  ## 
  bg.loadMap(addr seMem[sbb])


proc loadPal*(bg: Background; dest: pointer) {.inline.} =
  ## 
  ## Copy a background's palette to some location in memory.
  ## 
  ## :bg:   The background asset to use.
  ## :dest: The location to copy the palette to.
  ## 
  memcpy16(dest, bg.palDataPtr, bg.data.palHalfwords)


proc loadPal*(bg: Background; palId: range[0..15]) {.inline.} =
  ## 
  ## Copy a background's palette into buffered palette memory.
  ## 
  ## :bg:    The background asset to use.
  ## :palId: The palette will be copied to this location in `bgPalBuf`.
  ## 
  memcpy16(addr bgPalBuf[palId], bg.palDataPtr, bg.data.palHalfwords)


template load*(bgcnt: BgCnt; bg: Background) =
  ## 
  ## Load a background by copying its tiles, map, and palette into memory.
  ## 
  ## :bgcnt: A BG control register value which determines
  ##         where in VRAM to copy the tiles and map.
  ## :bg:    The asset to be loaded.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   bgcnt[0].init(cbb = 0, sbb = 28)    # init BG, set img/map destination
  ##   bgcnt[0].load(bgConstructionYard)   # copy img, map and pal
  ##   dispcnt.bg0 = true                  # show BG
  ## 
  bg.loadTiles(bgcnt.cbb)
  bg.loadMap(bgcnt.sbb)
  bg.loadPal(bg.data.palOffset.int)
