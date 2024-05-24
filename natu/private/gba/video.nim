
# I/O registers
# -------------

var dispcnt* {.importc:"(*(volatile NU16*)(0x04000000))", nodecl.}: DispCnt              ## Display control register
var dispstat* {.importc:"(*(volatile NU16*)(0x04000004))", nodecl.}: DispStat           ## Display status register
let vcount* {.importc:"(*(volatile NU16*)(0x04000006))", nodecl.}: uint16                   ## Scanline count register (read only)
var bgcnt* {.importc:"((volatile NU16*)(0x04000008))", nodecl.}: array[4, BgCnt]           ## BG control registers
var bgofs* {.importc:"((volatile BG_POINT*)(0x04000010))", header:"tonc_types.h".}: array[4, BgOfs]        ## [Write only!] BG scroll registers
var bgaff* {.importc:"((volatile BG_AFFINE*)(0x04000020))", header:"tonc_types.h".}: array[2..3, BgAffine] ## [Write only!] Affine parameters (matrix and scroll offset) for BG2 and BG3, depending on display mode.

var winh* {.importc:"((volatile WinH*)(0x04000040))", nodecl.}: array[2, WinH]  ## [Write only!] Sets the left and right bounds of a window
var winv* {.importc:"((volatile WinV*)(0x04000044))", nodecl.}: array[2, WinV]  ## [Write only!] Sets the upper and lower bounds of a window

var win0cnt* {.importc:"REG_WIN0CNT", header:"tonc_memmap.h".}: WinCnt  ## Window 0 control
var win1cnt* {.importc:"REG_WIN1CNT", header:"tonc_memmap.h".}: WinCnt  ## Window 1 control
var winoutcnt* {.importc:"REG_WINOUTCNT", header:"tonc_memmap.h".}: WinCnt  ## Out window control
var winobjcnt* {.importc:"REG_WINOBJCNT", header:"tonc_memmap.h".}: WinCnt  ## Object window control

var mosaic* {.importc:"(*(volatile NU16*)(0x0400004C))", nodecl.}: Mosaic        ## [Write only!] Mosaic size register

var bldcnt* {.importc:"(*(volatile NU16*)(0x04000050))", nodecl.}: BldCnt        ## Blend control register
var bldalpha* {.importc:"(*(volatile NU16*)(0x04000052))", nodecl.}: BlendAlpha  ## Alpha blending fade coefficients
var bldy* {.importc:"(*(volatile NU16*)(0x04000054))", nodecl.}: BlendBrightness ## [Write only!] Brightness (fade in/out) coefficient


# Memory mapped arrays
# --------------------

# Palette

var bgColorMem* {.importc:"pal_bg_mem", header:"tonc_memmap.h".}: array[256, Color]
  ## Access to BG PAL RAM as a single array of colors.
  ## 
  ## This is useful when working with 8bpp backgrounds, or display mode 4.

var bgPalMem* {.importc:"pal_bg_bank", header:"tonc_memmap.h".}: array[16, Palette]
  ## Access to BG PAL RAM as a table of 16-color palettes.
  ## 
  ## This is useful when working when 4bpp backgrounds.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ##   
  ##   # set all colors of the first palette in memory to white.
  ##   for color in bgPalMem[0].mitems:
  ##     color = clrWhite


var objColorMem* {.importc:"pal_obj_mem", header:"tonc_memmap.h".}: array[256, Color]
  ## Access to OBJ PAL RAM as a single array of colors.
  ## 
  ## This is useful when working with 8bpp sprites.

var objPalMem* {.importc:"pal_obj_bank", header:"tonc_memmap.h".}: array[16, Palette]
  ## Access to OBJ PAL RAM as a table of 16-color palettes.
  ## 
  ## This is useful when working when 4bpp sprites.


# VRAM

var bgTileMem* {.importc:"tile_mem", header:"tonc_memmap.h".}: array[4, UnboundedCharblock]
  ## BG charblocks, 4bpp tiles.
  ## 
  ## .. note::
  ##    While `bgTileMem[0]` has 512 elements, it's valid to reach across
  ##    into the neighbouring charblock, for example `bgTileMem[0][1000]`.
  ##    For this reason, bounds checking is not performed on tile memory
  ##    even when compiling with `--checks:on`.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   bgTileMem[i][j]   # Get image data from tile `j` in charblock `i`.

var bgTileMem8* {.importc:"tile8_mem", header:"tonc_memmap.h".}: array[4, UnboundedCharblock8]
  ## BG charblocks, 8bpp tiles.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   bgTileMem8[i][j]   # Get image data from tile `j` in charblock `i`.

var objTileMem* {.importc:"tile_mem_obj[0]", header:"tonc_memmap.h".}: array[1024, Tile]
  ## Object (sprite) image data, as 4bpp tiles.
  ## 
  ## This is 2 charblocks in size, and is separate from BG tile memory.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   objTileMem[n] = Tile()   # Clear the image data for a sprite tile.

var objTileMem8* {.importc:"tile8_mem_obj[0]", header:"tonc_memmap.h".}: array[512, Tile8]
  ## Object (sprite) tiles, 8bpp.

var seMem* {.importc:"se_mem", header:"tonc_memmap.h".}: array[32, Screenblock]
  ## Screenblocks as arrays.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   seMem[i]       # screenblock i
  ##   seMem[i][j]    # screenblock i, entry j
  ##   seMem[i][x,y]  # screenblock i, entry x + y*32


var vidMem* {.importc:"vid_mem", header:"tonc_memmap.h".}: array[240*160, Color]
  ## Main mode 3/5 frame as an array
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   vidMem[i]    # Get pixel `i` as a Color.

var m3Mem* {.importc:"m3_mem", header:"tonc_memmap.h".}: M3Mem
  ## Mode 3 frame as a matrix.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   m3Mem[y][x]  # Get pixel (x, y) as a Color.

var m4Mem* {.importc:"m4_mem", header:"tonc_memmap.h".}: M4Mem
  ## Mode 4 first page as a matrix.
  ## 
  ## .. note::
  ##    
  ##    This is a byte-buffer, not to be used for writing.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   m4Mem[y][x]  # Get pixel (x, y) as a uint8.

var m5Mem* {.importc:"m5_mem", header:"tonc_memmap.h".}: M5Mem
  ## Mode 5 first page as a matrix.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   m5Mem[y][x]  # Get pixel (x, y) as a Color.

var vidMemFront* {.importc:"vid_mem_front", header:"tonc_memmap.h".}: array[160*128, uint16]
  ## First page array

var vidMemBack* {.importc:"vid_mem_back", header:"tonc_memmap.h".}: array[160*128, uint16]
  ## Second page array

var m4MemBack* {.importc:"m4_mem_back", header:"tonc_memmap.h".}: M4Mem
  ## Mode 4 second page as a matrix.
  ## 
  ## This is a byte-buffer. Not to be used for writing.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   m4MemBack[y][x]  # Get pixel (x, y) as a uint8.

var m5MemBack* {.importc:"m5_mem_back", header:"tonc_memmap.h".}: M5Mem
  ## Mode 5 second page as a matrix.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   m5MemBack[y][x]  # Get pixel (x, y) as a Color.


# OAM

var objMem* {.importc:"oam_mem", header:"tonc_memmap.h".}: array[128, ObjAttr]
  ## Object attribute memory (where sprite properties belong).
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   var myObj: ObjAttr
  ##   
  ##   # Set up a sprite with some values:
  ##   myObj.init(
  ##     pos = vec2i(x, y),
  ##     tid = tid,
  ##     pal = pal,
  ##     size = s16x16,
  ##     prio = 0,
  ##   )
  ##   
  ##   # Later (during vblank) copy it into a slot in OAM:
  ##   objMem[i] = myObj

var objAffMem* {.importc:"obj_aff_mem", header:"tonc_memmap.h".}: array[32, ObjAffine]
  ## Object affine matrix memory.
  ## 
  ## This is where the transformation matrices for sprites belong.
  ## 
  ## **Example:**
  ## 
  ## .. code-block:: nim
  ## 
  ##   var myObj: ObjAttr
  ##   var affId = 0       # index of some matrix
  ##   var angle = 0x2000  # 45 degrees
  ##   
  ##   # Set up a sprite to use an affine matrix.
  ##   myObj.init(
  ##     mode = omAffine,
  ##     affId = affId,
  ##     pos = vec2i(x, y),
  ##     tid = tid,
  ##     pal = pal,
  ##     size = s16x16,
  ##   )
  ##   
  ##   # Later (during vblank):
  ##   objMem[i] = myObj                      # copy object into OAM.
  ##   objAffMem[affId].setToRotation(angle)  # rotate by 45 degrees anticlockwise.


{.compile(toncPath & "/src/tonc_video.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bg_affine.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bg.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bmp8.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_bmp16.c", toncCFlags).}
{.compile(toncPath & "/src/tonc_color.c", toncCFlags).}
{.compile(toncPath & "/asm/clr_blend_fast.s", toncAsmFlags).}
{.compile(toncPath & "/asm/clr_fade_fast.s", toncAsmFlags).}
{.compile(toncPath & "/src/tonc_obj_affine.c", toncCFlags).}


proc clrBlendFast*(srca: ptr Color; srcb: ptr Color; dst: ptr Color; nclrs: cint; alpha: cint) {.importc: "clr_blend_fast", tonc.}
  ## Blends color arrays `srca` and `srcb` into `dst`.
  ## 
  ## :srca: Source array A.
  ## :srcb: Source array B.
  ## :dst: Destination array.
  ## :nclrs: Number of colors.
  ## :alpha: Blend weight (range: 0-32).
  ## 
  ## .. note::
  ##    This is an ARM assembly routine placed in IWRAM, which makes it very fast, but keep in mind that IWRAM is a limited resource.


proc clrFadeFast*(src: ptr Color; clr: Color; dst: ptr Color; nclrs: cint; alpha: cint) {.importc: "clr_fade_fast", tonc.}
  ## Fades color arrays `srca` to `clr` into `dst`.
  ## 
  ## :src: Source array.
  ## :clr: Final color (at alpha=32).
  ## :dst: Destination array.
  ## :nclrs: Number of colors.
  ## :alpha: Blend weight (range: 0-32).
  ## 
  ## .. note::
  ##    This is an ARM assembly routine placed in IWRAM, which makes it very fast, but keep in mind that IWRAM is a limited resource.


# Objects (sprites)
# -----------------

func setAttr*(obj: ObjAttrPtr; a0, a1, a2: uint16) {.inline.} =
  ## Set the attributes of an object
  obj.attr0 = a0
  obj.attr1 = a1
  obj.attr2 = a2

func setAttr*(obj: var ObjAttr; a0, a1, a2: uint16) {.inline.} =
  ## Set the attributes of an object
  obj.attr0 = a0
  obj.attr1 = a1
  obj.attr2 = a2


# Obj affine procedures
# ---------------------

proc init*(oaff: var ObjAffine; pa, pb, pc, pd: Fixed) {.inline.} =
  ## Set the elements of an object affine matrix.
  oaff.pa = pa.int16
  oaff.pb = pb.int16
  oaff.pc = pc.int16
  oaff.pd = pd.int16

proc setToIdentity*(oaff: var ObjAffine) {.inline.} =
  ## Set an object affine matrix to the identity matrix.
  oaff.pa = 0x0100
  oaff.pb = 0
  oaff.pc = 0
  oaff.pd = 0x0100

proc setToScaleRaw*(oaff: var ObjAffine; sx, sy: Fixed) {.inline.} =
  ## Mathematically correct version of `setToScale`, but does the opposite of
  ## what you'd expect (since the matrix maps from screen space to texture space).
  oaff.pa = sx.int16
  oaff.pb = 0
  oaff.pc = 0
  oaff.pd = sy.int16

proc setToShearXRaw*(oaff: var ObjAffine; hx: Fixed) {.inline.} =
  oaff.pa = 0x0100
  oaff.pb = hx.int16
  oaff.pc = 0
  oaff.pd = 0x0100

proc setToShearYRaw*(oaff: var ObjAffine; hy: Fixed) {.inline.} =
  oaff.pa = 0x0100
  oaff.pb = 0
  oaff.pc = hy.int16
  oaff.pd = 0x0100

proc setToRotationRaw*(oaff: var ObjAffine; alpha: uint16) {.inline.} =
  ## Mathematically correct version of `setToRotation`, but does the opposite of
  ## what you'd expect (since the matrix maps from screen space to texture space).
  let ss = luSin(alpha.Angle).fp
  let cc = luCos(alpha.Angle).fp
  oaff.pa = (cc).int16
  oaff.pb = (-ss).int16
  oaff.pc = (ss).int16
  oaff.pd = (cc).int16

proc premul*(dst: var ObjAffine, src: ObjAffine) =
  ## Pre-multiply the matrix `dst` by `src`.
  ## i.e.
  ## 
  ## .. code-block::
  ## 
  ##   dst = src * dst
  let tmp_a = dst.pa.int
  let tmp_b = dst.pb.int
  let tmp_c = dst.pc.int
  let tmp_d = dst.pd.int
  dst.pa = ((src.pa.int * tmp_a + src.pb.int * tmp_c) shr 8).int16
  dst.pb = ((src.pa.int * tmp_b + src.pb.int * tmp_d) shr 8).int16
  dst.pc = ((src.pc.int * tmp_a + src.pd.int * tmp_c) shr 8).int16
  dst.pd = ((src.pc.int * tmp_b + src.pd.int * tmp_d) shr 8).int16

proc postmul*(dst: var ObjAffine, src: ObjAffine) =
  ## Post-multiply the matrix `dst` by `src`.
  ## i.e.
  ## 
  ## .. code-block::
  ## 
  ##   dst = dst * src
  let tmpa = dst.pa.int
  let tmpb = dst.pb.int
  let tmpc = dst.pc.int
  let tmpd = dst.pd.int
  dst.pa = ((tmp_a * src.pa.int + tmp_b * src.pc.int) shr 8).int16
  dst.pb = ((tmp_a * src.pb.int + tmp_b * src.pd.int) shr 8).int16
  dst.pc = ((tmp_c * src.pa.int + tmp_d * src.pc.int) shr 8).int16
  dst.pd = ((tmp_c * src.pb.int + tmp_d * src.pd.int) shr 8).int16

proc setToScaleAndRotationRaw*(oaff: var ObjAffine; sx, sy: Fixed; alpha: uint16) =
  ## Mathematically correct version of `setToScaleAndRotation`, but does the opposite of
  ## what you'd expect (since the matrix maps from screen space to texture space).
  let ss = luSin(alpha.Angle).int
  let cc = luCos(alpha.Angle).int
  oaff.pa = ((cc*sx) shr 12).int16
  oaff.pb = ((-ss*sx) shr 12).int16
  oaff.pc = ((ss*sy) shr 12).int16
  oaff.pd = ((cc*sy) shr 12).int16

proc rotscaleEx*(obj: var ObjAttr; oaff: var ObjAffine; asx: ptr AffSrcEx) {.importc: "obj_rotscale_ex", header: "tonc_oam.h".}
  ## Rot/scale an object around an arbitrary point.
  ## Sets up `obj` and `oaff` for rot/scale transformation around an arbitrary point using the `asx` data.
  ## 
  ## :obj:  Object to set.
  ## :oaff: Object affine data to set.
  ## :asx:  Affine source data: screen and texture origins, scales and angle.

template rotscaleEx*(obj: var ObjAttr; oaff: var ObjAffine; asx: AffSrcEx) =
  rotscaleEx(obj, oaff, unsafeAddr asx)

proc setToScale*(oa: var ObjAffine; sx: Fixed, sy = sx) {.inline.} =
  ## Set an object affine matrix for scaling.
  let x = ((1 shl 24) div sx.int) shr 8
  let y = ((1 shl 24) div sy.int) shr 8
  oa.setToScaleRaw(x.Fixed, y.Fixed)

proc setToRotation*(oa: var ObjAffine; theta: uint16) {.inline.} =
  ## Set obj matrix to counter-clockwise rotation.
  ## 
  ## :oaff:  Object affine matrix to set.
  ## :alpha: CCW angle. full-circle is `0x10000`.
  oa.setToRotationRaw(0'u16 - theta)

proc setToShearX*(oa: var ObjAffine; hx: Fixed) {.inline.} =
  oa.setToShearXRaw(-hx)

proc setToShearY*(oa: var ObjAffine; hy: Fixed) {.inline.} =
  oa.setToShearYRaw(-hy)

proc setToScaleAndRotation*(oa: var ObjAffine; sx, sy: Fixed; theta: uint16) {.inline.} =
  ## Set obj matrix to 2d scaling, then counter-clockwise rotation.
  ## 
  ## :oaff:  Object affine matrix to set.
  ## :sx:    Horizontal scale (zoom). .8 fixed point.
  ## :sy:    Vertical scale (zoom). .8 fixed point.
  ## :alpha: CCW angle. full-circle is `0x10000`.
  let x = ((1 shl 24) div sx.int) shr 8
  let y = ((1 shl 24) div sy.int) shr 8
  oa.setToScaleAndRotationRaw(x.Fixed, y.Fixed, 0'u16 - theta)


# SPRITE GETTERS/SETTERS
# ----------------------

{.push inline.}

# copy attr0,1,2 from one object into another
func setAttr*(obj: ObjAttrPtr, src: ObjAttr) = setAttr(obj, src.attr0, src.attr1, src.attr2)
func setAttr*(obj: var ObjAttr, src: ObjAttr) = setAttr(obj, src.attr0, src.attr1, src.attr2)

# getters

func x*(obj: ObjAttr): int = (obj.attr1 and 0x01FF'u16).int
func y*(obj: ObjAttr): int = (obj.attr0 and 0x00FF'u16).int
func pos*(obj: ObjAttr): Vec2i = vec2i(obj.x, obj.y)
func mode*(obj: ObjAttr): ObjMode = ((obj.attr0 and 0x0300'u16) shr 8).ObjMode
func fx*(obj: ObjAttr): ObjFxMode = ((obj.attr0 and 0x0C00'u16) shr 10).ObjFxMode
func mos*(obj: ObjAttr): bool = (obj.attr0 and 0x1000'u16) != 0
func is8bpp*(obj: ObjAttr): bool = (obj.attr0 and 0x2000'u16) != 0
func affId*(obj: ObjAttr): int = ((obj.attr1 and 0x3E00'u16) shr 9).int
func size*(obj: ObjAttr): ObjSize = (((obj.attr0 and 0xC000'u16) shr 12) or (obj.attr1 shr 14)).ObjSize
func hflip*(obj: ObjAttr): bool = (obj.attr1 and 0x1000'u16) != 0
func vflip*(obj: ObjAttr): bool = (obj.attr1 and 0x2000'u16) != 0
func tileId*(obj: ObjAttr): int = (obj.attr2 and 0x03FF'u16).int
func palId*(obj: ObjAttr): int = ((obj.attr2 and 0xF000'u16) shr 12).int
func prio*(obj: ObjAttr): int = ((obj.attr2 and 0x0C00'u16) shr 10).int

# setters

func `x=`*(obj: var ObjAttr; x: int) =
  obj.attr1 = (x.uint16 and 0x01FF'u16) or (obj.attr1 and not 0x01FF'u16)

func `y=`*(obj: var ObjAttr; y: int) =
  obj.attr0 = (y.uint16 and 0x00FF'u16) or (obj.attr0 and not 0x00FF'u16)

func `pos=`*(obj: var ObjAttr; v: Vec2i) =
  obj.x = v.x
  obj.y = v.y

func `tileId=`*(obj: var ObjAttr; tileId: int) =
  obj.attr2 = (tileId.uint16 and 0x03FF'u16) or (obj.attr2 and not 0x03FF'u16)

func `palId=`*(obj: var ObjAttr; palId: int) =
  obj.attr2 = ((palId.uint16 shl 12) and 0xF000'u16) or (obj.attr2 and not 0xF000'u16)

func `hflip=`*(obj: var ObjAttr; v: bool) =
  obj.attr1 = (v.uint16 shl 12) or (obj.attr1 and not 0x1000'u16)
  
func `vflip=`*(obj: var ObjAttr; v: bool) =
  obj.attr1 = (v.uint16 shl 13) or (obj.attr1 and not 0x2000'u16)

func `mode=`*(obj: var ObjAttr; v: ObjMode) =
  obj.attr0 = (v.uint16 shl 8) or (obj.attr0 and not 0x0300'u16)

func `fx=`*(obj: var ObjAttr; v: ObjFxMode) =
  obj.attr0 = (v.uint16 shl 10) or (obj.attr0 and not 0x0C00'u16)

func `mos=`*(obj: var ObjAttr; v: bool) =
  obj.attr0 = (v.uint16 shl 12) or (obj.attr0 and not 0x1000'u16)

func `is8bpp=`*(obj: var ObjAttr; v: bool) =
  obj.attr0 = (v.uint16 shl 13) or (obj.attr0 and not 0x2000'u16)

func `affId=`*(obj: var ObjAttr; affId: int) =
  obj.attr1 = ((affId.uint16 shl 9) and 0x3E00'u16) or (obj.attr1 and not 0x3E00'u16)

func `size=`*(obj: var ObjAttr; v: ObjSize) =
  let shape = (v.uint16 shl 12) and 0xC000'u16
  let size = (v.uint16 shl 14)
  obj.attr0 = shape or (obj.attr0 and not 0xC000'u16)
  obj.attr1 = size or (obj.attr1 and not 0xC000'u16)
  
func `prio=`*(obj: var ObjAttr; prio: int) =
  obj.attr2 = ((prio.uint16 shl 10) and 0x0C00'u16) or (obj.attr2 and not 0x0C00'u16)

{.pop.}
