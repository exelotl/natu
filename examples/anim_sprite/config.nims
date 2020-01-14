import os except existsDir
import strformat

const name = "anim_sprite"
const main = "main"

doAssert(existsEnv("DEVKITARM"), "Please set DEVKITARM in your environment.")
doAssert(existsEnv("DEVKITPRO"), "Please set DEVKITPRO in your environment.")

let devkitPro = getEnv("DEVKITPRO")
let devkitArm = getEnv("DEVKITARM")
let libtonc = devkitPro & "/libtonc"
let libgba = devkitPro & "/libgba"

doAssert(existsDir(libtonc), libtonc & " does not exist")

proc gbaCfg() =
  let libs = "-ltonc -lmm"
  let arch = "-mthumb -mthumb-interwork"
  let specs = "-specs={devkitArm}/arm-none-eabi/lib/gba.specs".fmt
  let omitWarnings = "-Wno-unused-variable -Wno-unused-but-set-variable -Wno-discarded-qualifiers"
  let maxErrors = "-fmax-errors=1"
  let cflags = "-g -Wall -O3 -mcpu=arm7tdmi -mtune=arm7tdmi -fomit-frame-pointer -ffast-math {arch} {omitWarnings} {maxErrors}".fmt
  let ldflags = "{libs} {specs} -g {arch} -Wl,-Map,{name}.elf.map".fmt
  
  switch "cpu", "arm"
  switch "os", "standalone"
  switch "gc", "none"
  switch "cc", "gcc"
  switch "header"
  switch "out", name & ".elf"
  switch "path", projectDir()
  switch "nimCache", "nimcache"  # output C sources to local directory
  switch "lineTrace", "off"
  switch "stackTrace", "off"
  switch "checks", "off"
  switch "define", "release"
  switch "cincludes", projectDir()/"../nimcache"
  switch "cincludes", libtonc/"include"
  switch "cincludes", libgba/"include"
  switch "cincludes", devkitArm/"arm-none-eabi/include"
  switch "clibdir", libtonc/"lib"
  switch "clibdir", libgba/"lib"
  
  put "arm.standalone.gcc.path", devkitArm/"bin"
  put "arm.standalone.gcc.exe", "arm-none-eabi-gcc"
  put "arm.standalone.gcc.linkerexe", "arm-none-eabi-gcc"
  put "arm.standalone.gcc.options.linker", ldflags
  put "arm.standalone.gcc.options.always", cflags

if projectName() == lastPathPart(main):
  gbaCfg()

task build, "builds the GBA rom":
  selfExec "c {main}".fmt
  exec "{devkitArm}/bin/arm-none-eabi-objcopy -O binary {name}.elf {name}.gba".fmt
  exec "{devkitPro}/tools/bin/gbafix {name}.gba".fmt

task clean, "removes build files":
  rmDir "nimcache"
  rmFile "{name}.gba".fmt
  rmFile "{name}.elf".fmt
  rmFile "{name}.elf.map".fmt
  rmFile "{name}.sav".fmt
