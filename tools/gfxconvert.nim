import strutils, strscans, strformat, parseopt
import options, math, os, times
import trick
from ./common import withFile, tsvRows

type
  GraphicRow = object
    ## Just the stuff parsed from the tsv
    pngPath: string
    name: string
    w, h: int
    bpp: GfxBpp
    palNum: int
  
  GraphicData = object
    ## Data to be output as Nim code
    bpp: int
    size: ObjSize
    w, h: int
    imgPos: int
    imgWords: int
    palNum: int
    palPos: int
    palHalfwords: int
    frames: int
    frameWords: int
  
  ObjSize = enum
    s8x8, s16x16, s32x32, s64x64,
    s16x8, s32x8, s32x16, s64x32,
    s8x16, s8x32, s16x32, s32x64


include "templates/graphics.c.template"
include "templates/graphics.nim.template"


proc gfxConvert*(tsvPath, script, indir, outdir: string) =
  var gfxRows: seq[GraphicRow]
  
  # input and output locations are assumed to exist
  var newestModifiedIn = getLastModificationTime(indir)
  var oldestModifiedOut = getLastModificationTime(outdir)
  
  let outputCPath = outdir / "gfx.c"
  let outputNimPath = outdir / "gfx.nim"
  
  # get oldest modification date of all output files
  
  if fileExists(outputCPath):
    let t = getLastModificationTime(outputCPath)
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
  
  # parse graphics from .tsv and check their modification dates
  
  for row in tsvRows(tsvPath):
    
    let (dir, name, ext) = splitFile(row[0])
    doAssert ext in ["", ".png"], "Only PNG files accepted (" & name & ext & ")"
    
    let pngPath = indir / dir / name & ".png"
    if fileExists(pngPath):
      let t = getLastModificationTime(pngPath)
      if t > newestModifiedIn: newestModifiedIn = t
    else:
      raiseAssert "No such file " & pngPath
    
    var w, h: int
    let scanned = scanf(row[1], "s$ix$i", w, h)
    doAssert scanned
    
    gfxRows.add GraphicRow(
      pngPath: pngPath,
      name: "gfx" & name.toCamelCase(firstUpper=true),
      w: w,
      h: h,
      bpp: parseInt(row[2]).GfxBpp,
      palNum: parseInt(row[3])
    )
  
  # regenerate the output files if any input files have changed:
  
  if newestModifiedIn > oldestModifiedOut:
    
    echo "Converting graphics:"
    var
      palData = ""  # binary data of all sprite palettes in the game
      imgData = ""  # binary data of all sprite images in the game
      gfxDatas: seq[GraphicData]
      currentPal = @[clrEmpty]
      namesInCurrentPal: seq[string]  # all gfx names with a shared pal are added here (only for troubleshooting really)
      lastPalGroup = 0
    
    # to append and reset the current palette
    proc flushSharedPalette =
      doAssert(
        currentPal.len <= 16,
        "Palette has {currentPal.len} colors, max is 16. Used by: {namesInCurrentPal}\nPalette = {currentPal}".fmt
      )
      let palBytes = currentPal.toBytes()
      palData.add(palBytes)
      var i = gfxDatas.len-1
      while i >= 0 and gfxDatas[i].palNum == lastPalGroup:
        gfxDatas[i].palHalfwords = currentPal.len
        dec i
      currentPal = @[clrEmpty]
      namesInCurrentPal = @[]
    
    for g in gfxRows:
      echo g.pngPath
      
      if g.palNum != lastPalGroup:
        # this graphic has a new palette
        flushSharedPalette()
        lastPalGroup = g.palNum
      
      # convert the graphic
      var info = GfxInfo(
        pal: currentPal,
        bpp: g.bpp,
        layout: gfxTiles,
      )
      let data = pngToBin(g.pngPath, info, buildPal=true)
      
      doAssert(info.width == g.w, "PNG width ({info.width}) should match the graphic width ({g.w}). Spritesheets must be provided as a vertical strip.".fmt)
      
      # Won't work yet because trick doesn't set the height?
      # doAssert((info.height mod g.h) == 0, "PNG height should be a multiple of the graphic height. Spritesheets must be provided as a vertical strip.")
      
      let pixelsPerByte = 8 div ord(g.bpp)
      let frameLen = (g.w * g.h) div pixelsPerByte
      let size = parseEnum[ObjSize]("s" & $g.w & "x" & $g.h)
      currentPal = info.pal
      namesInCurrentPal.add(g.pngPath.extractFilename())
      
      
      # push data necessary for codegen
      gfxDatas.add GraphicData(
        bpp: ord(g.bpp),
        size: size,
        w: g.w,
        h: g.h,
        imgPos: imgData.len,
        imgWords: data.len div 4,
        palNum: lastPalGroup,
        palPos: palData.len,
        palHalfwords: -1,  # calculated retroactively by flushSharedPalette
        frames: data.len div frameLen,
        frameWords: frameLen div 4,
      )
      imgData.add(data)
    
    flushSharedPalette()
    
    withFile(outputNimPath, fmWrite):
      file.writeGraphicsNim(gfxRows, gfxDatas, lastPalGroup + 1, palData.len, imgData.len)
    
    withFile(outputCPath, fmWrite):
      file.writeGraphicsC(imgData, palData)
  
  else:
    # skip gfx conversion.
    echo "Nothing to do."
    discard
    
    

proc gfxConvert*(p: var OptParser, progName: static[string] = "gfxconvert") =
  
  const helpMsg = """

Takes intermediate config output in tsv format and uses it to convert graphics.

Usage:
  """ & progName & """ filename.tsv --indir:DIR --outdir:DIR

"""
  
  var
    filename: string
    indir: string
    outdir: string
    script: string
  
  for kind, k, v in p.getopt():
    case kind
    of cmdArgument:
      filename = k
    of cmdLongOption, cmdShortOption:
      case k
      of "script": script = v
      of "indir": indir = v
      of "outdir": outdir = v
      of "h","help": quit(helpMsg, 0)
      else: quit("Unrecognised option '" & k & "'\n" & helpMsg)
    of cmdEnd:
      discard
  
  if filename == "": quit("Please pass in a .tsv file\n" & helpMsg, 0)
  if script == "": quit("Please specify the gfx script\n" & helpMsg, 0)
  if indir == "": quit("Please specify the input directory\n" & helpMsg, 0)
  if outdir == "": quit("Please specify the output directory\n" & helpMsg, 0)
  
  gfxconvert(filename, script, indir, outdir)
  echo "ROM fixed!"

when isMainModule:
  var p = initOptParser(shortNoVal = {'p', 'h'}, longNoVal = @["pad", "help"])
  gbafix(p)
