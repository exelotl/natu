when not isMainModule:
  {.error: "Natu is now modular. " &
    "Please import natu/[core, video, oam, input, irq, tte]".}

import parseopt, strutils, strscans
import tools/[gbafix]

const version = static:
  var res = "0.0.0"
  for line in staticExec("nimble dump").splitLines:
    var v: string
    if scanf(line, "version: \"$*\"", v):
      res = v
      break
  res

const helpMsg = """
Natu """ & version & """ Project Tool

This tool lets you quickly create a new GBA project.

Commands:
  natu init                Create a GBA project in the current directory

Extras:
  natu graphics            Generate sprite gfx data for current project
  natu audio               Generate maxmod soundbank for current project
  natu backgrounds         Generate BG img, map, pal data for current project
  natu fix <file.gba>      Fix a GBA ROM's header (logo + checksum)
  natu help                Show this dialogue
  natu help <command>      Show help for a specific command

Note: "Extras" are mostly for internal use.
They are invoked by your project's `config.nims` as part of the build process.
You can replace them with your own solutions (e.g. grit) if you prefer.
"""

var p = initOptParser()
var cmd: string

# parse a single arg to find out the subcommand.
for kind, k, v in p.getopt():
  case kind
  of cmdArgument:
    cmd = k
    break
  of cmdLongOption, cmdShortOption:
    case k
    of "h","help": quit(helpMsg, 0)
    else: quit("Unrecognised option '" & k & "'\n" & helpMsg)
  of cmdEnd:
    discard

proc help(p: var OptParser) =
  # show help for specific subcommand
  p.next()
  if p.kind == cmdArgument:
    var helpFlag = initOptParser("--help")
    case p.key
    of "fix": gbafix(helpFlag, "natu fix")
    else: quit(helpMsg, 0)
  else:
    quit(helpMsg, 0)

# run subcommand
case cmd
of "init": quit("Not implemented")
of "graphics": quit("Not implemented")
of "audio": quit("Not implemented")
of "backgrounds": quit("Not implemented")
of "fix": gbafix(p, "natu fix")
of "help": help(p)
else: quit(helpMsg, 0)
