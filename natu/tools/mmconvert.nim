import strutils, strformat, parseopt
import options, os, osproc, times
import trick
import ./common

proc writeSoundbankNim(f: File; sfxList, modList: seq[string]) =
  include "templates/soundbank.nim.template"

proc writeSdlSoundbankNim(f: File; sfxFilePaths, modFilePaths, sfxList, modList: seq[string]) =
  include "templates/sdl_soundbank.nim.template"

proc mmConvert*(script, sfxdir, moddir, outdir: string, files: seq[string], sdl: bool) =
  var sfxFilePaths, modFilePaths, sfxList, modList: seq[string]
  
  let outputBinPath = outdir / "soundbank.bin"
  let outputNimPath = outdir / "soundbank.nim"
  let outputNimPathSdl = outdir / "sdl_soundbank.nim"
  
  var newestModifiedIn = getLastModificationTime(script)
  var oldestModifiedOut = oldest(outputBinPath, outputNimPath, outputNimPathSdl)
  
  # collate and check modification dates of input files
  
  let modExts = if sdl: @[".ogg", ".mod", ".xm", ".s3m", ".it"]
                else: @[".mod", ".xm", ".s3m", ".it"]
  
  for f in files:
    
    let (_, name, ext) = splitFile(f)
    
    var inPath: string
    
    if ext == ".wav":
      inPath = sfxdir / f
      sfxList.add toCamelCase("sfx_" & name)
      sfxFilePaths.add inPath
    elif ext in modExts:
      inPath = moddir / f
      modList.add toCamelCase("mod_" & name)
      modFilePaths.add inPath
    else:
      raiseAssert("Unrecognised audio asset " & name & ext & ", only the following formats are accepted: .wav " & modExts.join(" "))
    
    doAssert(fileExists(inPath), "No such file " & inPath)
    newestModifiedIn = newest(newestModifiedIn, inPath, inPath.parentDir)
  
  
  # regenerate the output files if any input files have changed
  
  if newestModifiedIn > oldestModifiedOut:
    
    if sdl:
      echo "Building sound list:"
      
      withFile(outputNimPathSdl, fmWrite):
        file.writeSdlSoundbankNim(sfxFilePaths, modFilePaths, sfxList, modList)
    
    else:
      echo "Building soundbank:"
      
      var mmutilPath = getAppDir() / "mmutil".addFileExt(ExeExt)
      
      if not fileExists(mmutilPath):
        # Find mmutil in system path
        mmutilPath = findExe("mmutil")
        
        # If none was found, try devkitPro tools directory as a fallback?
        if mmutilPath == "" and existsEnv("DEVKITPRO"):
          mmutilPath = getEnv("DEVKITPRO")/"tools"/"bin"/"mmutil".addFileExt(ExeExt)
      
      proc mmutil(args: string) =
        doAssert(
          fileExists(mmutilPath),
          "Could not find mmutil executable! (mmutilPath = \"" & mmutilPath & "\")\n" &
          "Ensure the directory containing the mmutil executable is in your PATH, or try reinstalling Natu."
        )
        let res = execCmd(mmutilPath & " " & args)
        if res != 0:
          raiseAssert("mmutil failed with code " & $res)
      
      mmutil "-o" & outputBinPath & " " & sfxFilePaths.join(" ") & " " & modFilePaths.join(" ")
      
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
    sdl: bool = false
  
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
      of "sdl": sdl = p.val == "" or parseBool(p.val)
      of "h","help": quit(helpMsg, 0)
      else: quit("Unrecognised option '" & p.key & "'\n" & helpMsg)
    of cmdEnd:
      break
  
  if files.len == 0: quit("Please pass one or more input files.\n" & helpMsg, 0)
  if script == "": quit("Please specify --script\n" & helpMsg, 0)
  if sfxdir == "": quit("Please specify --sfxdir\n" & helpMsg, 0)
  if moddir == "": quit("Please specify --moddir\n" & helpMsg, 0)
  if outdir == "": quit("Please specify --outdir\n" & helpMsg, 0)
  
  mmConvert(script, sfxdir, moddir, outdir, files, sdl)

