import os, strutils

let natuDir* = currentSourcePath().parentDir.parentDir

put "natu.gameTitle", "untitled"
put "natu.gameCode", "0NTP"

# common options

put "natu.cflags.target", "-mthumb -mthumb-interwork"
put "natu.cflags.cpu", "-mcpu=arm7tdmi -mtune=arm7tdmi"
put "natu.cflags.perf", "-fomit-frame-pointer -ffast-math"

# TODO: check how much these two are actually needed nowadays:

# silence some warnings that may occur in the generated C code,
# but are out of your control.
put "natu.cflags.noWarn", "-Wno-unused-variable -Wno-unused-but-set-variable -Wno-discarded-qualifiers"

# Nim compiler used to hang on too many warnings/errors (https://github.com/nim-lang/Nim/issues/8648)
# so I'm keeping this around just in case.
put "natu.cflags.limitErrors", "-fmax-errors=1"

when not defined(nimsuggest):
  doAssert(existsEnv("DEVKITARM"), "Please set DEVKITARM in your environment.")
  doAssert(existsEnv("DEVKITPRO"), "Please set DEVKITPRO in your environment.")

proc gbaCfg*() =
  
  doAssert(get("natu.toolchain") == "devkitarm", "Only \"devkitarm\" toolchain is supported for now.")
  
  let devkitArm = getEnv("DEVKITARM")
  
  # set linker flags (these are dependent on other options)
  
  if not exists("natu.ldflags.specs"):
    put "natu.ldflags.specs", "-specs=" & devkitArm & "/arm-none-eabi/lib/gba.specs"
  
  if not exists("natu.ldflags.target"):
    put "natu.ldflags.target", get("natu.cflags.target")
  
  if not exists("natu.ldflags.map"):
    put "natu.ldflags.map", "-Wl,-Map," & get("natu.gameTitle") & ".elf.map"
  
  let cflags = [
    get("natu.cflags.target"),
    get("natu.cflags.cpu"),
    get("natu.cflags.perf"),
    get("natu.cflags.noWarn"),
    get("natu.cflags.limitErrors"),
  ].join(" ")
  
  let ldflags = [
    get("natu.ldflags.specs"),
    get("natu.ldflags.target"),
    get("natu.ldflags.map"),
  ].join(" ")
  
  # Work with --gc:arc --os:any
  
  put "arm.any.gcc.path", devkitArm / "bin"
  put "arm.any.gcc.exe", "arm-none-eabi-gcc"
  put "arm.any.gcc.linkerexe", "arm-none-eabi-gcc"
  put "arm.any.gcc.options.linker", ldflags
  put "arm.any.gcc.options.always", cflags
  
  # Work with --gc:none --os:standalone
  
  put "arm.standalone.gcc.path", devkitArm / "bin"
  put "arm.standalone.gcc.exe", "arm-none-eabi-gcc"
  put "arm.standalone.gcc.linkerexe", "arm-none-eabi-gcc"
  put "arm.standalone.gcc.options.linker", ldflags
  put "arm.standalone.gcc.options.always", cflags
  
  # Don't set switches that influence the Nim compiler's behaviour
  # only those that a developer will never want to override.
  switch "define", "gba"
  switch "cincludes", natuDir/"vendor/libtonc/include"
  switch "cincludes", natuDir/"vendor/maxmod/include"
  

proc gbaStrip*(elfFile, gbaFile: string) =
  ## Invoke objcopy to create a raw binary file (all debug symbols removed)
  exec getEnv("DEVKITARM") / "bin/arm-none-eabi-objcopy -O binary " & elfFile & " " & gbaFile

proc gbaFix*(gbaFile: string) =
  ## Invoke gbafix to set the ROM header
  exec getEnv("DEVKITPRO") / "tools/bin/gbafix " &
    gbaFile &
    " -c" & get("natu.gameCode") &
    " -t" & get("natu.gameTitle").toUpperAscii()
