import os, strutils
import std/compilesettings

let natuDir* = currentSourcePath().parentDir.parentDir

# ROM header info, should be overidden

put "natu.gameTitle", "UNTITLED"
put "natu.gameCode", "2NTP"

# C compiler options, may be overidden

put "natu.cflags.target", "-mthumb -mthumb-interwork"
put "natu.cflags.cpu", "-mcpu=arm7tdmi"
put "natu.cflags.perf", "-O2 -ffast-math"
put "natu.cflags.debug", "-g"

# silence some warnings that may occur in the generated C code,
# but are out of your control.
put "natu.cflags.noWarn", "-Wno-unused-variable -Wno-unused-but-set-variable -Wno-discarded-qualifiers -Wno-incompatible-pointer-types -Wno-stringop-overflow"

proc devkitPro*: string =
  result = getEnv("DEVKITPRO")
  when not defined(nimsuggest):
    doAssert(result != "", "Please set DEVKITPRO in your environment.")

proc devkitArm*: string =
  result = getEnv("DEVKITARM")
  when not defined(nimsuggest):
    doAssert(result != "", "Please set DEVKITARM in your environment.")

# detect toolchain

var useDkp = false
let gcc = findExe("arm-none-eabi-gcc")
if gcc == "":
  if getEnv("DEVKITPRO") != "" and getEnv("DEVKITARM") != "":
    useDkp = true
  else:
    doAssert(false, "Missing arm-none-eabi-gcc, please install it and make sure it's in your system PATH!")


proc natuExe*: string =
  result = getEnv("NATU_EXE")
  if result == "":
    result = natuDir/"natu".addFileExt(ExeExt)
    if dirExists(result):
      result = natuDir/"natu.out"  # unix-friendly fallback

proc gbaCfg* =
  
  if useDkp:
    echo "Using devkitARM's GCC."
  
  # set linker flags
  
  if not exists("natu.ldflags.script"):
    put "natu.ldflags.script", "-T " & natuDir & "/natu/private/gba_cart.ld"
  
  if not exists("natu.ldflags.specs"):
    put "natu.ldflags.specs", "-lnosys -Wl,--gc-sections"  # you could potentially pass a specs file here instead
  
  if not exists("natu.ldflags.target"):
    put "natu.ldflags.target", get("natu.cflags.target")
  
  if not exists("natu.ldflags.debug"):
    put "natu.ldflags.debug", get("natu.cflags.debug")
  
  if not exists("natu.ldflags.map"):
    # get the "--out:xxx" compiler option, if known
    # otherwise guess based on the name of the 'main' file.
    var name = querySetting(outFile)
    if name == "":
      name = projectName() & ".elf"
    put "natu.ldflags.map", "-Wl,-Map," & name & ".map"
  
  let cflags = [
    get("natu.cflags.target"),
    get("natu.cflags.cpu"),
    get("natu.cflags.debug"),
    get("natu.cflags.perf"),
    get("natu.cflags.noWarn"),
  ].join(" ")
  
  let ldflags = [
    get("natu.ldflags.script"),
    get("natu.ldflags.specs"),
    get("natu.ldflags.target"),
    get("natu.ldflags.debug"),
    get("natu.ldflags.map"),
  ].join(" ")
  
  # Set path to GCC and replace default flags
  put "gcc.path", if useDkp: devkitArm()/"bin" else: gcc.parentDir
  put "gcc.exe", "arm-none-eabi-gcc"
  put "gcc.linkerexe", "arm-none-eabi-gcc"
  put "gcc.options.linker", ldflags
  put "gcc.options.always", cflags
  
  # Only set switches that the developer will never need to override.
  switch "define", "gba"
  switch "define", "natuOutputDir:" & absolutePath("output")
  switch "cpu", "arm"
  switch "cc", "gcc"
  switch "lineTrace", "off"
  switch "stackTrace", "off"
  switch "excessiveStackTrace", "off"
  switch "cincludes", natuDir/"vendor/libtonc/include"
  switch "cincludes", natuDir/"vendor/maxmod/include"
  
  # Natu panic handler
  switch "import", natuDir/"natu/private/essentials"
  patchFile("stdlib", "fatal", natuDir/"natu/private/fatal")
  
  if useDkp:
    # Ensure subprocesses can see the DLLs in tools/bin
    putEnv "PATH", devkitPro()/"tools"/"bin" & PathSep & getEnv("PATH")


proc gbaStrip*(elfFile, gbaFile: string) =
  ## Invoke objcopy to create a raw binary file (all debug symbols removed)
  let cmd = if useDkp: devkitArm() / "bin/arm-none-eabi-objcopy"
            else: "arm-none-eabi-objcopy"
  exec cmd & " -O binary " & elfFile & " " & gbaFile

proc gbaFix*(gbaFile: string) =
  ## Invoke gbafix to set the ROM header
  exec natuExe() & " fix " & gbaFile &
    " -c:" & get("natu.gameCode") &
    " -t:" & get("natu.gameTitle").toUpperAscii()


# Asset conversion
# ----------------

template doInclude*(path: static string) =
  include `path`

proc row*(items: varargs[string, `$`]): string =
  items.join("\t")

func toCamelCase*(str: string, firstUpper = false): string =
  var makeUpper = firstUpper
  for i, c in str:
    if c notin Letters+Digits:
      makeUpper = true
    elif makeUpper:
      result.add(c.toUpperAscii())
      makeUpper = false
    else:
      result.add(c)


# Graphics
# --------

type ObjSize* = enum
  s8x8, s16x16, s32x32, s64x64,
  s16x8, s32x8, s32x16, s64x32,
  s8x16, s8x32, s16x32, s32x64

var natuGraphics*: seq[string]

proc readGraphics*(script: static string) =
  
  natuGraphics = @[]
  
  let natuCurrentDir = getCurrentDir()
  var natuPalCounter: int
  var natuIsSharingPal: bool
  
  template sharePal(body: untyped) =
    doAssert(not natuIsSharingPal, "sharePal cannot be nested.")
    natuIsSharingPal = true
    `body`
    natuIsSharingPal = false
    inc natuPalCounter
  
  proc graphic(name: string, size: ObjSize, bpp = 4) =
    let path = name.absolutePath.relativePath(natuCurrentDir)
    doAssert({'\t', '\n'} notin path, path & " contains invalid characters.")
    natuGraphics.add row(path, size, bpp, natuPalCounter)
    if not natuIsSharingPal:
      inc natuPalCounter
  
  doInclude(script)
  cd natuCurrentDir


proc gfxConvert*(script: static string) =
  readGraphics(script)
  let tsvFile = "output/graphics.tsv"
  mkDir(tsvFile.parentDir)
  writeFile(tsvFile, natuGraphics.join("\n"))
  exec natuExe() & " gfxconvert " & tsvFile & " --script:" & script & " --indir:. --outdir:output"


# Backgrounds
# -----------

type
  BgKind* = enum
    bkReg4bpp  ## Regular background, 16 colors per-tile
    bkReg8bpp  ## Regular background, 256 colors
    bkAff      ## Affine background, 256 colors
  
  BgFlag* = enum
    bfScreenblock
      ## For non-affine BGs, arrange the map data into blocks of 32x32 tiles.
    bfBlankTile
      ## First tile in the tileset will be empty - recommended for transparent BGs.
    bfAutoPal
      ## For 4bpp BGs, attempt to build a set of 16-color palettes from the image.
      ## If this flag is omitted, the PNG's own palette will be strictly followed, and
      ## each 8x8 tile in the image must only refer to colors from a single group of 16.
  
  BgRegionLayout* = enum
    Chr4c
      ## The tiles in the region are arranged in column-major order,
      ## 
      ## e.g::
      ## 
      ##    00  04  08  .
      ##    01  05  09  .
      ##    02  06  10  .
      ##    03  07  11
      ## 
    Chr4r
      ## The tiles in the region are arranged in row-major order,
      ## 
      ## e.g::
      ## 
      ##    00  01  02  03
      ##    04  05  06  07
      ##    08  09  10  11
      ##    . . .
  
  BgRegion* = (BgRegionLayout, int, int, int, int)

proc toUInt[T](s: set[T]): uint =
  ## Get internal representation of a (<= 32 bits) set in Nimscript.
  for n in s:
    result = result or (1'u shl ord(n))

var natuBackgrounds*: seq[string]

proc readBackgrounds*(script: static string) =
  
  natuBackgrounds = @[]
  
  let natuCurrentDir = getCurrentDir()
  
  proc background(
    name: string,
    kind: BgKind,
    palOffset = 0,
    tileOffset = 0,
    flags: set[BgFlag] = {},
    regions: openArray[BgRegion] = @[],
  ) =
    let path = name.absolutePath.relativePath(natuCurrentDir)
    doAssert({'\t', '\n'} notin path, path & " contains invalid characters.")
    natuBackgrounds.add row(path, kind, palOffset, tileOffset, flags.toUInt(), regions)
  
  doInclude(script)
  cd natuCurrentDir


proc bgConvert*(script: static string) =
  
  readBackgrounds(script)
  let tsvFile = "output/backgrounds.tsv"
  mkDir(tsvFile.parentDir)
  writeFile(tsvFile, natuBackgrounds.join("\n"))
  exec natuExe() & " bgconvert " & tsvFile & " --script:" & script & " --indir:. --outdir:output"


# Audio
# -----

var
  natuSamples*: seq[string]
  natuModules*: seq[string]

proc readAudio*(script: static string) =
  
  natuSamples = @[]
  natuModules = @[]
  
  let natuCurrentDir = getCurrentDir()
  
  proc sample(name: string) =
    let path = name.absolutePath.relativePath(natuCurrentDir)
    doAssert({'\t', '\n'} notin path, path & " contains invalid characters.")
    natuSamples.add path
  
  proc module(name: string) =
    let path = name.absolutePath.relativePath(natuCurrentDir)
    doAssert({'\t', '\n'} notin path, path & " contains invalid characters.")
    natuModules.add path
  
  doInclude(script)
  cd natuCurrentDir


proc mmConvert*(script: static string) =
  readAudio(script)
  mkDir("output")
  exec natuExe() & " mmconvert --script:$# --sfxdir:. --moddir:. --outdir:output $# $#" % [
    script,
    natuSamples.join(" "),
    natuModules.join(" "),
  ]
