import natu/[core, video]
import natu/private/utils
import natu/kit/[types, pal_manager]

type Background = concept b
  b is enum
  data(b) is BgData
  imgDataPtr(b) is pointer
  mapDataPtr(b) is pointer
  palDataPtr(b) is pointer

template kind*(bg: Background): BgKind = bg.data.kind
template flags*(bg: Background): set[BgFlag] = bg.data.flags
template palOffset*(bg: Background): int = bg.data.palOffset.int
template tileOffset*(bg: Background): int = bg.data.tileOffset.int

template is8bpp*(bg: Background): bool =
  bg.data.kind in {bkReg8bpp, bkAff}

proc loadTiles*(bg: Background, cbb: range[0..3]) {.inline.} =
  ## 
  ## Copy a background's tile image data into memory.
  ## 
  ## **Parameters:**
  ## 
  ## bg
  ##   The background asset to use.
  ## 
  ## cbb
  ##   Character Base Block: The tileset will be copied to this location.
  ## 
  let tileOffset = bg.data.tileOffset.int * (if bg.is8bpp: 2 else: 1)
  memcpy32(addr bgTileMem[cbb][tileOffset], bg.imgDataPtr, bg.data.imgWords)

proc loadMap*(bg: Background, sbb: range[0..31]) {.inline.} =
  ## 
  ## Copy a background's map data into memory.
  ## 
  ## **Parameters:**
  ## 
  ## bg
  ##   The background asset to use.
  ## 
  ## sbb
  ##   Screen Base Block: The map will be copied to this location.
  ##   If there is more than 1 screenblock of data, it will be copied
  ##   over into the next screenblocks.
  ## 
  memcpy32(addr seMem[sbb], bg.mapDataPtr, bg.data.mapWords)

proc loadPal*(bg: Background, palId: range[0..15]) {.inline.} =
  ## 
  ## Copy a background's palette into memory.
  ## 
  ## **Parameters:**
  ## 
  ## bg
  ##   The background asset to use.
  ## 
  ## palId
  ##   The palette will be copied to this location.
  ## 
  memcpy16(addr bgPalBuf[palId], bg.palDataPtr, bg.data.palHalfwords)


template load*(bgcnt: BgCnt; bg: Background) =
  ## 
  ## Load a background by copying its tiles, map, and palette into memory.
  ## 
  ## The locations are determined by the supplied BG control register.
  ## 
  ## **Parameters:**
  ## 
  ## bgcnt
  ##   A BG control register value which determines
  ##   where to copy the tiles and map.
  ## 
  ## bg
  ##   The asset to be loaded.
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
