import os, strutils
import natu/config

const main = "main.nim"
const title = "hello_world"
const gameCode = "0NTP"

put "natu.toolchain", "devkitarm"
put "natu.gameTitle", title
put "natu.gameCode", gameCode

if projectPath() == thisDir() / main:
  # This runs only when compiling the main file
  gbaCfg()
  switch "cc", "gcc"
  switch "cpu", "arm"
  switch "os", "standalone"
  switch "gc", "none"
  switch "out", title & ".elf"
  switch "lineTrace", "off"
  switch "stackTrace", "off"
  switch "checks", "off"
  switch "debugInfo", "on"
  switch "opt", "speed"
  switch "path", projectDir()    # allow imports relative to the main file
  switch "header"                # output "main.h", which C files can include
  switch "nimCache", "nimcache"  # output C sources to local directory
  switch "cincludes", thisDir() / "nimcache"

task build, "builds the GBA rom":
  let args = commandLineParams()[1..^1].join(" ")
  selfExec "c " & args & " " & thisDir() / main
  gbaStrip(title & ".elf", title & ".gba")
  gbaFix(title & ".gba")

task clean, "removes build files":
  rmDir "nimcache"
  rmFile title & ".gba"
  rmFile title & ".elf"
  rmFile title & ".elf.map"
