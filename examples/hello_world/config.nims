import os, strutils
import natu/config

const main = "helloworld.nim"
const name = splitFile(main).name

put "natu.toolchain", "devkitarm"
put "natu.gameTitle", "HELLO"
put "natu.gameCode", "0NTP"

if projectPath() == thisDir() / main:
  # This runs only when compiling the main file
  gbaCfg()
  switch "cc", "gcc"
  switch "cpu", "arm"
  switch "os", "standalone"
  switch "gc", "none"
  switch "checks", "off"            # disable assertions, bounds checking, etc.
  switch "path", projectDir()       # allow imports relative to the main file
  switch "header"                   # output "{name}.h"
  switch "nimcache", "nimcache"     # output C sources to local directory
  switch "cincludes", nimcacheDir() # allow external C files to include "{name}.h"

task build, "builds the GBA rom":
  let args = commandLineParams()[1..^1].join(" ")
  selfExec "c " & args & " -o:" & name & ".elf " & thisDir() / main
  gbaStrip name & ".elf", name & ".gba"
  gbaFix name & ".gba"

task clean, "removes build files":
  rmDir "nimcache"
  rmFile name & ".gba"
  rmFile name & ".elf"
  rmFile name & ".elf.map"
