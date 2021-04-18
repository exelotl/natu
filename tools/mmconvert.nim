import strutils, strformat, parseopt
import options, os, osproc, times
import trick
from ./common import withFile

include "templates/soundbank.nim.template"

proc mmConvert*(script, sfxDir, modDir, outDir: string, files: seq[string]) =
  var filePaths, sfxList, modList: seq[string]
  
  # input and output locations are assumed to exist
  var newestModifiedIn = max(getLastModificationTime(sfxDir), getLastModificationTime(modDir))
  var oldestModifiedOut = getLastModificationTime(outdir)
  
  let outputBinPath = outdir / "soundbank.bin"
  let outputNimPath = outdir / "soundbank.nim"
  
  # get oldest modification date of all output files
  
  if fileExists(outputBinPath):
    let t = getLastModificationTime(outputBinPath)
    if t < oldestModifiedOut: oldestModifiedOut = t
  else:
    oldestModifiedOut = fromUnix(0)
  
  if fileExists(outputNimPath):
    let t = getLastModificationTime(outputNimPath)
    if t < oldestModifiedOut: oldestModifiedOut = t
  else:
    oldestModifiedOut = fromUnix(0)
  
  # account for the script itself possibly having changed
  
  if fileExists(script):
    let t = getLastModificationTime(script)
    if t > newestModifiedIn: newestModifiedIn = t
  
  # collate and check modification dates of input files
  
  for f in files:
    
    let (dir, name, ext) = splitFile(f)
    
    var inPath: string
    
    if ext == ".wav":
      inPath = sfxDir / f
      sfxList.add toCamelCase("sfx_" & name)
    elif ext in [".mod", ".xm", ".s3m", ".it"]:
      inPath = modDir / f
      modList.add toCamelCase("mod_" & name)
    else:
      raiseAssert("Unrecognised audio asset " & name & ext & ", only the following formats are accepted: .wav .mod .xm .s3m .it")
    
    if fileExists(inPath):
      let t = getLastModificationTime(inPath)
      if t > newestModifiedIn: newestModifiedIn = t
    else:
      raiseAssert "No such file " & inPath
    
    filePaths.add inPath
    
  
  # regenerate the output files if any input files have changed
  
  if newestModifiedIn > oldestModifiedOut:
    
    echo "Building soundbank:"
    
    # Find mmutil in system path
    var mmutilPath = findExe("mmutil")
    
    # If none was found, try devkitPro tools directory as a fallback?
    if mmutilPath == "" and existsEnv("DEVKITPRO"):
      mmutilPath = getEnv("DEVKITPRO")/"tools"/"bin"/"mmutil".addFileExt(ExeExt)
    
    proc mmutil(args: string) =
      doAssert(
        fileExists(mmutilPath),
        "Could not find mmutil executable! (mmutilPath = \"" & mmutilPath & "\")\n" &
        "Check you have a working devkitARM installation (including the gba-dev package group), " &
        "or try adding mmutil to your PATH environment variable."
      )
      let res = execCmd(mmutilPath & " " & args)
      if res != 0:
        raiseAssert("mmutil failed with code " & $res)
    
    mmutil "-o" & outputBinPath & " " & filePaths.join(" ")
    
    withFile(outputNimPath, fmWrite):
      file.writeSoundbankNim(sfxList, modList)
  
  else:
    echo "Skipping audio."
  

# Command Line Interface
# ----------------------

proc mmConvert*(p: var OptParser, progName: static[string] = "gfxconvert") =
  
  const helpMsg = """

Usage:
  """ & progName & """ --script:FILE --sfxDir:DIR --modDir:DIR --outDir:DIR <input files>

Invokes the maxmod utility program to generate a soundbank, and produces Nim-friendly output.

"""
  var
    files: seq[string]
    script: string
    sfxDir: string
    modDir: string
    outDir: string
  
  while true:
    next(p)
    case p.kind
    of cmdArgument:
      files.add p.key
    of cmdLongOption, cmdShortOption:
      case p.key
      of "script": script = p.val
      of "sfxDir": sfxDir = p.val
      of "modDir": modDir = p.val
      of "outDir": outdir = p.val
      of "h","help": quit(helpMsg, 0)
      else: quit("Unrecognised option '" & p.key & "'\n" & helpMsg)
    of cmdEnd:
      break
  
  if files.len == 0: quit("Please pass one or more input files.\n" & helpMsg, 0)
  if script == "": quit("Please specify --script\n" & helpMsg, 0)
  if sfxDir == "": quit("Please specify --sfxDir\n" & helpMsg, 0)
  if modDir == "": quit("Please specify --modDir\n" & helpMsg, 0)
  if outDir == "": quit("Please specify --outDir\n" & helpMsg, 0)
  
  mmConvert(script, sfxDir, modDir, outDir, files)

