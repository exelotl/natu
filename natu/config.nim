import os, strutils
import std/compilesettings

let natuDir* = currentSourcePath().parentDir.parentDir

# ROM header info, should be overidden

put "natu.gameTitle", "UNTITLED"
put "natu.gameCode", "2NTP"

# C compiler options, may be overidden

put "natu.cflags.target", "-mthumb -mthumb-interwork"
put "natu.cflags.cpu", "-mcpu=arm7tdmi -mtune=arm7tdmi"
put "natu.cflags.perf", "-O2 -ffast-math"
put "natu.cflags.debug", "-g"

# TODO: check how much these two are actually needed nowadays:

# silence some warnings that may occur in the generated C code,
# but are out of your control.
put "natu.cflags.noWarn", "-Wno-unused-variable -Wno-unused-but-set-variable -Wno-discarded-qualifiers"

# Nim compiler used to hang on too many warnings/errors (https://github.com/nim-lang/Nim/issues/8648)
# so I'm keeping this around just in case.
put "natu.cflags.limitErrors", "-fmax-errors=1"

proc devkitPro*: string =
  result = getEnv("DEVKITPRO")
  when not defined(nimsuggest):
    doAssert(result != "", "Please set DEVKITPRO in your environment.")

proc devkitArm*: string =
  result = getEnv("DEVKITARM")
  when not defined(nimsuggest):
    doAssert(result != "", "Please set DEVKITARM in your environment.")

proc natuExe*: string =
  getEnv("NATU_EXE", default="natu")

proc gbaCfg* =
  
  doAssert(get("natu.toolchain") == "devkitarm", "Only \"devkitarm\" toolchain is supported for now.")
  
  # set linker flags
  
  if not exists("natu.ldflags.specs"):
    put "natu.ldflags.specs", "-specs=" & devkitArm() & "/arm-none-eabi/lib/gba.specs"
  
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
    get("natu.cflags.limitErrors"),
  ].join(" ")
  
  let ldflags = [
    get("natu.ldflags.specs"),
    get("natu.ldflags.target"),
    get("natu.ldflags.debug"),
    get("natu.ldflags.map"),
  ].join(" ")
  
  # Work with --gc:arc --os:any
  
  put "arm.any.gcc.path", devkitArm() / "bin"
  put "arm.any.gcc.exe", "arm-none-eabi-gcc"
  put "arm.any.gcc.linkerexe", "arm-none-eabi-gcc"
  put "arm.any.gcc.options.linker", ldflags
  put "arm.any.gcc.options.always", cflags
  
  # Work with --gc:none --os:standalone
  
  put "arm.standalone.gcc.path", devkitArm() / "bin"
  put "arm.standalone.gcc.exe", "arm-none-eabi-gcc"
  put "arm.standalone.gcc.linkerexe", "arm-none-eabi-gcc"
  put "arm.standalone.gcc.options.linker", ldflags
  put "arm.standalone.gcc.options.always", cflags
  
  # Only set switches that the developer will never need to override.
  switch "define", "gba"
  switch "cpu", "arm"
  switch "cc", "gcc"
  switch "lineTrace", "off"
  switch "stackTrace", "off"
  switch "cincludes", natuDir/"vendor/libtonc/include"
  switch "cincludes", natuDir/"vendor/maxmod/include"
  
  # Ensure subprocesses can see the DLLs in tools/bin
  putEnv "PATH", devkitPro()/"tools"/"bin" & PathSep & getEnv("PATH")


proc gbaStrip*(elfFile, gbaFile: string) =
  ## Invoke objcopy to create a raw binary file (all debug symbols removed)
  exec devkitArm() / "bin/arm-none-eabi-objcopy -O binary " & elfFile & " " & gbaFile

proc gbaFix*(gbaFile: string) =
  ## Invoke gbafix to set the ROM header
  exec devkitPro() / "tools/bin/gbafix " &
    gbaFile &
    " -c" & get("natu.gameCode") &
    " -t" & get("natu.gameTitle").toUpperAscii()


func toCamelCase(name: string): string =
  var upper = false
  for c in name:
    if c == '_': upper = true
    elif upper:
      result.add(c.toUpperAscii())
      upper = false
    else:
      result.add(c.toLowerAscii())

proc createMaxmodSoundbank*(files: seq[string], binFile = "soundbank.bin", nimFile = "soundbank.nim") {.deprecated.} =
  ## Invoke `mmutil` to create a soundbank file.
  ## Also output a Nim file equivalent to the header file that
  ## mmutil would usually produce when given the -h option.
  
  exec devkitPro() / "tools/bin/mmutil -o" & binFile & " " & files.join(" ")
  
  var sfxList, modList: seq[string]
  
  for f in files:
    let (_, name, ext) = splitFile(f)
    
    if ext == ".wav":
      sfxList.add toCamelCase("sfx_" & name)
    
    elif ext in [".mod", ".xm", ".s3m", ".it"]:
      modList.add toCamelCase("mod_" & name)
  
  writeFile nimFile, """
import natu/maxmod

let soundbankBin* = static staticRead("$1").cstring

type
  SampleId* {.size: 4.} = enum
$2
  ModuleId* {.size: 4.} = enum
$3

# Allow implicit conversion:
converter toMmSampleId*(id: SampleId): MmSampleId {.inline.} = id.MmSampleId
converter toMmModuleId*(id: ModuleId): MmModuleId {.inline.} = id.MmModuleId
""" % [
    relativePath(binFile, nimFile.parentDir).replace('\\', '/'),
    sfxList.join("\n").indent(4),
    modList.join("\n").indent(4),
  ]


template doInclude*(path: static string) =
  include `path`


# Graphics
# --------

type ObjSize* = enum
  s8x8, s16x16, s32x32, s64x64,
  s16x8, s32x8, s32x16, s64x32,
  s8x16, s8x32, s16x32, s32x64

proc gfxConvert*(script: static string) =
  var
    natuOutput: seq[string]
    natuPalCounter: int
    natuIsSharingPal: bool
  
  template sharePal(body: untyped) =
    doAssert(not natuIsSharingPal, "sharePal cannot be nested.")
    natuIsSharingPal = true
    `body`
    natuIsSharingPal = false
    inc natuPalCounter
  
  proc graphic(name: string, size: ObjSize, bpp = 4) =
    doAssert({'\t', '\n'} notin name, name & " contains invalid characters.")
    natuOutput.add name & '\t' & $size & '\t' & $bpp & '\t' & $natuPalCounter
    if not natuIsSharingPal:
      inc natuPalCounter
  
  var
    indir = "graphics"
    outdir = "output"
  
  doInclude(script)
  
  let tsvFile = outdir/"gfxconvert.tsv"
  mkDir(outdir)
  writeFile(tsvFile, natuOutput.join("\n"))
  exec natuExe() & " gfxconvert " & tsvFile & " --script:" & script & " --indir:" & indir & " --outdir:" & outdir
  rmFile(tsvFile)


proc mmConvert*(script: static string) =
  var
    natuMmList: seq[string]
  
  proc sample(name: string) =
    doAssert({'\t', '\n'} notin name, name & " contains invalid characters.")
    natuMmList.add name
  
  proc module(name: string) =
    doAssert({'\t', '\n'} notin name, name & " contains invalid characters.")
    natuMmList.add name
  
  var
    sfxDir = "samples"
    modDir = "modules"
    outDir = "output"
  
  doInclude(script)
  
  mkDir(outdir)
  exec natuExe() & " mmconvert --script:$# --sfxDir:$# --modDir:$# --outDir:$# $#" % [
    script,
    sfxDir,
    modDir,
    outDir,
    natuMmList.join(" ")
  ]
