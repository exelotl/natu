import os, strutils, algorithm
import natu/config

const main = "source/goodboy_gallery.nim"  # path to project file
const name = splitFile(main).name          # name of ROM

put "natu.gameTitle", "GALLERY"        # max 12 chars, uppercase
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

task graphics, "convert spritesheets":
  gfxConvert "graphics.nims"

task audio, "convert music and sounds":
  mmConvert "audio.nims"

task backgrounds, "convert background tilemaps":
  bgConvert "backgrounds.nims"

task build, "builds the GBA rom":
  let args = commandLineParams()[1..^1].join(" ")
  graphicsTask()
  audioTask()
  backgroundsTask()
  selfExec "c " & args & " -o:" & name & ".elf " & thisDir() / main
  gbaStrip name & ".elf", name & ".gba"
  gbaFix name & ".gba"

task clean, "removes build files":
  rmDir "nimcache"
  rmDir "output"
  rmFile name & ".gba"
  rmFile name & ".elf"
  rmFile name & ".elf.map"
  