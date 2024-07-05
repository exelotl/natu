# parallel to `mmconvert.nim` but for the SDL-based mixer
import std/[strutils, strformat, parseopt, options, os, osproc, times, streams, tables]
import trick, riff
import ./common

type
  LoopKind* = enum
    LoopNone
    LoopForward
    LoopPingPong
  SampleInfo* = object
    dataStart: uint32   # measured in floats
    dataEnd: uint32     # .. (exclusive)
    channels: uint16
    sampleRate: uint32
    loopKind: LoopKind
    loopStart: uint32  # measured in samples (mono or stereo)
    loopEnd: uint32    # ..
  ModuleInfo* = object
    tags: seq[string]
    paths: seq[string]

proc writeSdlSoundbankNim(
  f: File;
  modInfo: OrderedTable[string, ModuleInfo];
  sfxList: seq[string];
  sfxInfo: seq[SampleInfo];
  sampleDataLen: int
) =
  include "templates/sdl_soundbank.nim.template"

proc writeSdlSoundbankC(f: File; data: string) =
  include "templates/sdl_soundbank.c.template"

iterator mutate[T](a: var T): var T =
  yield a

proc mixConvert*(script, sfxdir, moddir, outdir: string, files: seq[string]) =
  var sfxFilePaths, sfxList: seq[string]
  var sfxInfo: seq[SampleInfo]
  var modInfo: OrderedTable[string, ModuleInfo]  # mapping from modFoo -> collection of tags & paths.
  
  let outputNimPath = outdir / "sdl_soundbank.nim"
  let outputCPath = outdir / "sdl_soundbank.c"
  
  var newestModifiedIn = getLastModificationTime(script)
  var oldestModifiedOut = oldest(outputNimPath, outputCPath)
  
  # collate and check modification dates of input files
  
  let modExts = [".ogg", ".mod", ".xm", ".s3m", ".it"]
  
  for f in files:
    let parts = f.rsplit('#', maxsplit=1)
    let (_, name, ext) = splitFile(parts[0])
    let filepath = parts[0]
    let tag = if parts.len > 1: parts[1] else: ""
    
    var inPath: string
    
    if ext == ".wav":
      inPath = sfxdir / filepath
      sfxList.add toCamelCase("sfx_" & name)
      sfxFilePaths.add inPath
    elif ext in modExts:
      inPath = moddir / filepath
      let name = toCamelCase("mod_" & name)
      let info = addr modInfo.mgetOrPut(name, ModuleInfo())
      info.tags.add(tag)
      info.paths.add(inPath)
      
    else:
      raiseAssert(&"Unrecognised audio asset {name}{ext} only the following formats are accepted: .wav " & modExts.join(" "))
    
    doAssert(fileExists(inPath), "No such file " & inPath)
    newestModifiedIn = newest(newestModifiedIn, inPath, inPath.parentDir)
  
  
  # regenerate the output files if any input files have changed
  
  if newestModifiedIn > oldestModifiedOut:
    
    echo "Building sdl soundbank:"
    
    var outStream = newStringStream()
    
    for f in sfxFilePaths:
      
      let f = f
      echo f
      
      # var rootChunk, fmtChunk, dataChunk, smplChunk: ChunkInfo
      var rr = openRiffFile(f)
      var isWaveFile = false
      
      # sampler chunk
      var loopType: uint32
      var loopStart: uint32
      var loopEnd: uint32
      
      # format chunk
      var compressionCode: uint16
      var channels: uint16
      var blockAlign: uint32
      var sampleRate: uint32
      var bitDepth: uint16
      
      # data chunk
      var size: uint32
      var data: string
      
      proc check(chunk: ChunkInfo) =
        case chunk.id
        of "RIFF":
          doAssert(chunk.formatTypeId == "WAVE", &"got {rr.currentChunk.formatTypeId} for {f}")
          isWaveFile = true
        of "fmt ":
          compressionCode = rr.read(uint16)  # compression code
          doAssert(
            compressionCode == 1 or               # PCM (general)
            compressionCode == 3,                 # IEEE float
            &"got {compressionCode} for {f}"
          )
          channels = rr.read(uint16)         # number of channels
          sampleRate = rr.read(uint32)       # sample rate (Hz)
          discard rr.read(uint32)            # average bytes per second
          blockAlign = rr.read(uint16)       # block align (size of a sample on 1 channel * num channels)
          bitDepth = rr.read(uint16)         # bits per sample
          
        of "smpl":
          discard rr.read(uint32)  # manufacturer
          discard rr.read(uint32)  # product
          discard rr.read(uint32)  # sample period
          discard rr.read(uint32)  # midi unity note
          discard rr.read(uint32)  # midi pitch fraction
          discard rr.read(uint32)  # smpte format
          discard rr.read(uint32)  # smpte offset
          let numSampleLoops = rr.read(uint32)
          discard rr.read(uint32)  # sample data
          if numSampleLoops > 0:
            doAssert(numSampleLoops == 1, &"{f} contains multiple loop points, which is unsupported.")
            discard rr.read(uint32)         # cue point ID
            loopType = rr.read(uint32) + 1  # 0 = none, 1 = forward, 2 = bidirectional
            loopStart = rr.read(uint32)     # loop start
            loopEnd = rr.read(uint32)       # loop end
            discard rr.read(uint32)         # fraction
            discard rr.read(uint32)         # play count
            
        of "data":
          size = chunk.size
          # size = rr.read(uint32)    # data size in bytes
          for i in 0..<size:
            data.add(rr.read(char))
      
      # parse the RIFF chunks:
      try:
        doAssert(rr.currentChunk.id == "RIFF", &"got {rr.currentChunk.id} for {f}")
        check(rr.currentChunk)
        # the root RIFF chunk is a group chunk so it must be entered
        if rr.hasSubChunks():
          check(rr.enterGroup())
          # iterate through all top-level chunks inside the root RIFF group chunk
          while rr.hasNextChunk():
            check(rr.nextChunk())
      finally:
        rr.close()
    
      var sample = SampleInfo(
        loopKind: loopType.LoopKind,
        loopStart: loopStart,
        loopEnd: loopEnd,
        channels: channels,
        sampleRate: sampleRate,
        dataStart: (outStream.data.len div sizeof(float32)).uint32
      )
      
      var inStream = newStringStream(data)
      
      case bitDepth
      of 8:
        # 8-bit unsigned
        for i in 0..<size:
          let n = inStream.readUint8().int - 127
          outStream.write(n.float32 / 128f)
      of 16:
        # 16-bit signed
        let numShorts = size.int div sizeof(int16)
        for i in 0..<numShorts:
          let n = inStream.readInt16()
          outStream.write(n.float32 / 32768f)
      of 32:
        # 32-bit float
        let numFloats = size.int div sizeof(float32)
        for i in 0..<numFloats:
          outStream.write(inStream.readFloat32)
      else:
        raiseAssert(&"{f} has unsupported bit depth '{bitDepth}'")
        
      sample.dataEnd = (outStream.data.len div sizeof(float32)).uint32
      
      sfxInfo.add sample
    
    withFile(outputNimPath, fmWrite):
      file.writeSdlSoundbankNim(modInfo, sfxList, sfxInfo, outStream.data.len)
    
    withFile(outputCPath, fmWrite):
      file.writeSdlSoundbankC(outStream.data)
  
  else:
    echo "Skipping audio."
  

# Command Line Interface
# ----------------------

proc mixConvert*(p: var OptParser, progName: static[string] = "mixconvert") =
  
  const helpMsg = """

Usage:
  """ & progName & """ --script:FILE --sfxdir:DIR --moddir:DIR --outdir:DIR <input files>

Generates soundbank C and Nim files for PC builds of the game.

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
  
  mixConvert(script, sfxdir, moddir, outdir, files)

