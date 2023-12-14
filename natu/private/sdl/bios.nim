import std/math
import natu/math as nmath

# Reset Functions
# ---------------

proc SoftReset*() = doAssert(false, "Soft reset.")

proc RegisterRamReset*(flags: ResetFlags) =
  echo "RegisterRamReset!"

# Halt functions
# --------------

proc Halt*() {.error: "Unimplemented.".} =
  discard

proc Stop*() {.error: "Unimplemented.".} =
  discard

proc IntrWait*(clear: bool; irq: set[IrqIndex]) {.error: "Unimplemented.".} =
  discard

proc VBlankIntrWait*() =
  echo "VBlankIntrWait"

# Arithmetic
# ----------

proc Div*(num, den: int): int =
  num div den

proc DivArm*(den, num: int): int =
  num div den

proc Sqrt*(num: uint): uint =
  sqrt(num.float32).uint

const rad2gba = (0x10000 / Tau).float32

proc ArcTan*(dydx: FixedT[int16,14]): int16 =
  (arctan(dydx.toFloat32()) * rad2gba).int16

proc ArcTan2*(x, y: int16): uint16 =
  (arctan2(y.float32, x.float32) * rad2gba).uint16

# Memory copiers/fillers
# ----------------------

proc CpuSet*(src: pointer; dst: pointer; opts: CpuSetOptions) =
  if opts.stride == cssHalfwords:
    let src = cast[ptr UncheckedArray[uint16]](src)
    let dst = cast[ptr UncheckedArray[uint16]](dst)
    var j = 0
    for i in 0 ..< opts.count:
      dst[i] = src[j]
      if opts.mode == csmCopy:
        inc j
  else:
    let src = cast[ptr UncheckedArray[uint32]](src)
    let dst = cast[ptr UncheckedArray[uint32]](dst)
    var j = 0
    for i in 0 ..< opts.count:
      dst[i] = src[j]
      if opts.mode == csmCopy:
        inc j

proc CpuFastSet*(src: pointer; dst: pointer; opts: CpuFastSetOptions) =
  let count = ((opts.count + 7) shr 3) shl 3
  let src = cast[ptr UncheckedArray[uint32]](src)
  let dst = cast[ptr UncheckedArray[uint32]](dst)
  var j = 0
  for i in 0 ..< count:
    dst[i] = src[j]
    if opts.mode == csmCopy:
      inc j

proc BiosChecksum*(): uint32 =
  0x12345678'u32

# Rot/scale functions
# -------------------

# to make it stop complaining about missing types when we use the --header compiler switch.
var ObjAffineSetDummy {.exportc.}: ObjAffineSource
var BgAffineSetDummy {.exportc.}: BgAffineSource
  
proc ObjAffineSet*(src: ptr ObjAffineSource; dst: pointer; num: int; offset: int) {.error: "Unimplemented.".} =
  discard

proc BgAffineSet*(src: ptr BgAffineSource; dst: ptr BgAffineDest; num: int) {.error: "Unimplemented.".} =
  discard


# Decompression
# -------------
# (see GBATek for format details)

proc BitUnPack*(src: pointer; dst: pointer; bup: BitUnpackOptions) {.error: "Unimplemented.".} =
  discard

proc LZ77UnCompWram*(src: pointer; dst: pointer) {.error: "Unimplemented.".} =
  discard

proc LZ77UnCompVram*(src: pointer; dst: pointer) {.error: "Unimplemented.".} =
  discard

proc HuffUnComp*(src: pointer; dst: pointer) {.error: "Unimplemented.".} =
  discard

proc RLUnCompWram*(src: pointer; dst: pointer) {.error: "Unimplemented.".} =
  discard

proc RLUnCompVram*(src: pointer; dst: pointer) {.error: "Unimplemented.".} =
  discard

proc Diff8bitUnFilterWram*(src: pointer; dst: pointer) {.error: "Unimplemented.".} =
  discard

proc Diff8bitUnFilterVram*(src: pointer; dst: pointer) {.error: "Unimplemented.".} =
  discard

proc Diff16bitUnFilter*(src: pointer; dst: pointer) {.error: "Unimplemented.".} =
  discard


# Sound
# -----

proc SoundBias*(bias: uint32) {.error: "Unimplemented.".} =
  discard

proc SoundDriverInit*(src: pointer) {.error: "Unimplemented.".} =
  discard

proc SoundDriverMode*(mode: uint32) {.error: "Unimplemented.".} =
  discard

proc SoundDriverMain*() {.error: "Unimplemented.".} =
  discard

proc SoundDriverVSync*() {.error: "Unimplemented.".} =
  discard

proc SoundChannelClear*() {.error: "Unimplemented.".} =
  discard

proc MidiKey2Freq*(wa: pointer; mk: uint8; fp: uint8): uint32 {.error: "Unimplemented.".} =
  discard

proc MultiBoot*(mb: MultibootOptions; mode: MultibootMode): int {.error: "Unimplemented.".} =
  discard

proc HardReset*() {.error: "Unimplemented.".} =
  discard

proc SoundDriverVSyncOff*() {.error: "Unimplemented.".} =
  discard

proc SoundDriverVSyncOn*() {.error: "Unimplemented.".} =
  discard



# EXTRA BIOS ROUTINES
# -------------------
# Additional utilities from Tonc which are built atop the BIOS routines.
# You can find these in ``tonc_bios_ex.s``

proc VBlankIntrDelay*(count: uint) {.exportc.} =
  for i in 0..<count:
    VBlankIntrWait()

proc DivSafe*(num, den: int): int {.error: "Unimplemented.".} =
  discard

proc Mod*(num, den: int): int {.exportc: "Mod".} =
  num mod den

proc DivMod*(num, den: int): int {.error: "Unimplemented.".} =
  discard

proc DivAbs*(num, den: int): uint {.error: "Unimplemented.".} =
  discard

proc DivArmMod*(den, num: int): int {.error: "Unimplemented.".} =
  discard

proc DivArmAbs*(den, num: int): uint {.error: "Unimplemented.".} =
  discard

proc CpuFastFill*(wd: uint32; dst: pointer; words: uint) =
  let dst = cast[ptr UncheckedArray[uint32]](dst)
  for i in 0 ..< words:
    dst[i] = wd
