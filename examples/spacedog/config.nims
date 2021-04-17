import os, strutils
import natu/config

const main = "src/spacedog.nim"        # path to project file
const name = splitFile(main).name      # name of ROM

put "natu.toolchain", "devkitarm"
put "natu.gameTitle", "SPACEDOG"       # max 12 chars, uppercase
put "natu.gameCode", "2NTP"            # 4 chars, see GBATEK for info

if projectPath() == thisDir() / main:
  # This runs only when compiling the project file:
  gbaCfg()                             # set C compiler + linker options for GBA target
  switch "os", "standalone"
  switch "gc", "none"
  switch "checks", "off"               # toggle assertions, bounds checking, etc.
  switch "path", projectDir()          # allow imports relative to the main file
  switch "header"                      # output "{project}.h"
  switch "nimcache", "nimcache"        # output C sources to local directory
  switch "cincludes", nimcacheDir()    # allow external C files to include "{project}.h"

task gfx, "convert sprite graphics":
  gfxConvert "gfx.nims"

task build, "builds the GBA rom":
  let args = commandLineParams()[1..^1].join(" ")
  gfxTask()
  echo "c " & args & " -o:" & name & ".elf " & thisDir() / main
  selfExec "c " & args & " -o:" & name & ".elf " & thisDir() / main
  # gbaStrip name & ".elf", name & ".gba"
  # gbaFix name & ".gba"

task clean, "removes build files":
  rmDir "nimcache"
  rmDir "res"
  rmFile name & ".gba"
  rmFile name & ".elf"
  rmFile name & ".elf.map"
  