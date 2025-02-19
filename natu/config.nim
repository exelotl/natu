import os, strutils
import std/compilesettings

let natuDir* = currentSourcePath().parentDir.parentDir

# Config gets loaded twice:
# 1) with 'config.nims' as the project directory.
# 2) with 'path/to/my_game.nim' as the project directory.
# 
# We want to use (1) as the root for , so use the environment
# to make sure it only gets set once.

if not existsEnv("natuConfigRoot"):
  putEnv("natuConfigRoot", projectDir())

let root = getEnv("natuConfigRoot")

switch "define", "natuOutputDir:" & root/"output"
switch "define", "natuConfigDir:" & root/"config"
switch "define", "natuSharedDir:" & root/"shared"

# ROM header info, should be overidden

put "natu.gameTitle", "UNTITLED"
put "natu.gameCode", "2NTP"

# C compiler options, may be overidden

put "natu.cflags.target", "-mthumb -mthumb-interwork"
put "natu.cflags.cpu", "-mcpu=arm7tdmi"
put "natu.cflags.perf", "-O2 -ffast-math"
put "natu.cflags.debug", "-g"
put "natu.cflags.stdlib", "-nostdinc -isystem " & natuDir / "vendor/acsl/include"

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


proc natuExe*: string =
  result = getEnv("NATU_EXE")
  if result == "":
    result = natuDir/"natu".addFileExt(ExeExt)
    if dirExists(result):
      result = natuDir/"natu.out"  # unix-friendly fallback

proc gbaCfg* =
  
  if useDkp:
    echo "Using devkitARM's GCC."
  elif gcc == "":
    doAssert(false, "Missing arm-none-eabi-gcc, please install it and make sure it's in your system PATH!")
  
  # set linker flags
  
  if not exists("natu.ldflags.script"):
    put "natu.ldflags.script", "-T " & natuDir & "/natu/private/gba/gba_cart.ld"
  
  if not exists("natu.ldflags.specs"):
    put "natu.ldflags.specs", "-nostdlib -lgcc -Wl,--gc-sections"  # you could potentially pass a specs file here instead
  
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
    get("natu.cflags.stdlib"),
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
  switch "cpu", "arm"
  switch "cc", "gcc"
  switch "lineTrace", "off"
  switch "stackTrace", "off"
  switch "excessiveStackTrace", "off"
  switch "threads", "off"
  switch "cincludes", natuDir/"vendor/libtonc/include"
  switch "cincludes", natuDir/"vendor/maxmod/include"
  
  # Natu panic handler
  switch "import", natuDir/"natu/private/gba/essentials"
  patchFile("stdlib", "fatal", natuDir/"natu/private/fatal")
  
  if useDkp:
    # Ensure subprocesses can see the DLLs in tools/bin
    putEnv "PATH", devkitPro()/"tools"/"bin" & PathSep & getEnv("PATH")

proc sdlCfg*(w, h: int) =
  echo "Building for PC."
  switch "passC", "-fPIC -DNON_GBA_TARGET"
  put "gcc.options.always", "-Wno-unused-variable -Wno-unused-but-set-variable -Wno-discarded-qualifiers -Wno-incompatible-pointer-types -Wno-stringop-overflow"
  switch "define", "natuLcdWidth:" & $w
  switch "define", "natuLcdHeight:" & $h
  switch "passL", "-lm"
  switch "cpu", "amd64"
  switch "threads", "off"
  # switch "import", natuDir/"natu/private/sdl/applib"
  switch "app", "lib"
  switch "nimMainPrefix", "natu"
  switch "noMain"
  switch "cincludes", natuDir/"vendor/libtonc/include"
  switch "cincludes", natuDir/"vendor/maxmod/include"
  switch "lineTrace", "off"
  switch "stackTrace", "off"
  switch "excessiveStackTrace", "off"
  patchFile("stdlib", "fatal", natuDir/"natu/private/fatal")
  when defined(windows):
    patchFile("stdlib", "dynlib", natuDir/"natu/private/win/dynlib")

proc gbaStrip*(elfFile, gbaFile: string) =
  ## Invoke objcopy to create a raw binary file (all debug symbols removed)
  let cmd = if useDkp: devkitArm() / "bin/arm-none-eabi-objcopy"
            else: "arm-none-eabi-objcopy"
  exec cmd & " -O binary " & elfFile & " " & gbaFile

proc gbaFix*(gbaFile: string) =
  ## Invoke gbafix to set the ROM header
  let gameCode = get("natu.gameCode")
  let gameTitle = get("natu.gameTitle")
  let makerCode = get("natu.makerCode")
  let gameVersion = get("natu.gameVersion")
  let pad = get("natu.pad")
  
  var args = gbaFile
  if gameCode != "":  args &= " -c:" & gameCode
  if gameTitle != "": args &= " -t:" & gameTitle.toUpperAscii()
  if makerCode != "": args &= " -m:" & makerCode
  if gameVersion != "": args &= " -r:" & gameVersion
  if pad != "": args &= (if parseBool(pad): " -p" else: "")
  
  exec natuExe() & " fix " & args

proc printMemInfo*(elfFile: string) =
  ## Invoke natu info to print out GBA memory usage info about an elf using objdump.
  echo "-------------------------------"
  exec natuExe() & " info " & elfFile
  echo "-------------------------------"


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


proc toUInt[T](s: set[T]): uint =
  ## Get internal representation of a (<= 32 bits) set in Nimscript.
  for n in s:
    result = result or (1'u shl ord(n))


# Graphics
# --------

type ObjSize* = enum
  s8x8, s16x16, s32x32, s64x64,
  s16x8, s32x8, s32x16, s64x32,
  s8x16, s8x32, s16x32, s32x64

type GraphicFlag* = enum
  StrictPal
  PalOnly

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
  
  proc graphic(
    name: string,
    size: ObjSize,
    bpp = 4,
    flags: set[GraphicFlag] = {},
    strictPal = false
  ) =
    let path = name.absolutePath.relativePath(natuCurrentDir)
    doAssert({'\t', '\n'} notin path, path & " contains invalid characters.")
    var flags = flags
    if strictPal:
      echo "`strictPal` is deprecated, use flags={StrictPal} instead."
      flags.incl StrictPal  # legacy compatibiltiy
    natuGraphics.add row(path, size, bpp, natuPalCounter, flags.toUInt())
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
  
  CompressionKind* = enum
    None
    Rle

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
    tileComp = None,
    mapComp = None,
  ) =
    let path = name.absolutePath.relativePath(natuCurrentDir)
    doAssert({'\t', '\n'} notin path, path & " contains invalid characters.")
    natuBackgrounds.add row(path, kind, palOffset, tileOffset, flags.toUInt(), regions, tileComp, mapComp)
  
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

proc mixConvert*(script: static string) =
  readAudio(script)
  mkDir("output")
  exec natuExe() & " mixconvert --script:$# --sfxdir:. --moddir:. --outdir:output $# $#" % [
    script,
    natuSamples.join(" "),
    natuModules.join(" "),
  ]
