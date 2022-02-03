import strutils, strformat, parseopt
import options, os, osproc, times
import trick
import ./common

include "templates/soundbank.nim.template"

proc mmConvert*(script, sfxdir, moddir, outdir: string, files: seq[string]) =
  var filePaths, sfxList, modList: seq[string]
  
  let outputBinPath = outdir / "soundbank.bin"
  let outputNimPath = outdir / "soundbank.nim"
  
  var newestModifiedIn = getLastModificationTime(script)
  var oldestModifiedOut = oldest(outputBinPath, outputNimPath)
  
  # collate and check modification dates of input files
  
  for f in files:
    
    let (_, name, ext) = splitFile(f)
    
    var inPath: string
    
    if ext == ".wav":
      inPath = sfxdir / f
      sfxList.add toCamelCase("sfx_" & name)
    elif ext in [".mod", ".xm", ".s3m", ".it"]:
      inPath = moddir / f
      modList.add toCamelCase("mod_" & name)
    else:
      raiseAssert("Unrecognised audio asset " & name & ext & ", only the following formats are accepted: .wav .mod .xm .s3m .it")
    
    doAssert(fileExists(inPath), "No such file " & inPath)
    newestModifiedIn = newest(newestModifiedIn, inPath, inPath.parentDir)
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
  """ & progName & """ --script:FILE --sfxdir:DIR --moddir:DIR --outdir:DIR <input files>

Invokes the maxmod utility program to generate a soundbank, and produces Nim-friendly output.

"""
  var
    files: seq[string]
    script: string
    sfxdir: string
    moddir: string
    outdir: string
  
  while true:
    next(p)
    case p.kind
    of cmdArgument:
      files.add p.key
    of cmdLongOption, cmdShortOption:
      case p.key
      of "script": script = p.val
      of "sfxdir": sfxdir = p.val
      of "moddir": moddir = p.val
      of "outdir": outdir = p.val
      of "h","help": quit(helpMsg, 0)
      else: quit("Unrecognised option '" & p.key & "'\n" & helpMsg)
    of cmdEnd:
      break
  
  if files.len == 0: quit("Please pass one or more input files.\n" & helpMsg, 0)
  if script == "": quit("Please specify --script\n" & helpMsg, 0)
  if sfxdir == "": quit("Please specify --sfxdir\n" & helpMsg, 0)
  if moddir == "": quit("Please specify --moddir\n" & helpMsg, 0)
  if outdir == "": quit("Please specify --outdir\n" & helpMsg, 0)
  
  mmConvert(script, sfxdir, moddir, outdir, files)

