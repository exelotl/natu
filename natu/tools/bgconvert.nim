import strutils, strformat, parseopt, strscans, algorithm, marshal
import options, os, times
import trick
import ./common

type
  BgKind = enum
    bkReg4bpp  ## Regular background, 16 colors per-tile
    bkReg8bpp  ## Regular background, 256 colors
    bkAff      ## Affine background, 256 colors
  
  BgFlag = enum
    bfScreenblock
    bfBlankTile
    bfAutoPal
  
  CompressionKind = enum
    None
    Rle
  
  BgRow = object
    ## Just the stuff parsed from the tsv
    pngPath: string
    name: string
    kind: BgKind
    palOffset: int      ## First palette ID
    tileOffset: int     ## First tile ID
    flags: set[BgFlag]  ## Misc. conversion options
    regions: seq[BgRegion]
    tileComp: CompressionKind
    mapComp: CompressionKind
  
  BgData = object
    # Everything in this object will be serialised (marshalled) and stored in
    # the generated .c file. On the next build, some of these fields will be
    # compared to the stored ones, and the BG will be regenerated if they differ.
    kind: BgKind
    w, h: int
    imgWords: uint16
    mapWords: uint16
    palHalfwords: uint16
    palOffset: uint16
    tileOffset: uint16
    flags: set[BgFlag]
    regions: seq[BgRegion]
    tileComp: CompressionKind
    mapComp: CompressionKind
  
  BgRegionLayout = enum
    Chr4c
    Chr4r
  
  BgRegion = (BgRegionLayout, int, int, int, int)


proc parseRegions*(regions: string): seq[BgRegion] =
  if regions.len > 2:
    for s in regions[2..^2].split("), ("):
      var layout: string
      var x1, y1, x2, y2: int
      doAssert scanf(s, "$w, $i, $i, $i, $i", layout, x1, y1, x2, y2), "Could not parse BgRegion '" & s & "'"
      result.add (parseEnum[BgRegionLayout](layout), x1, y1, x2, y2)

proc applyRegion*(bg4: var Bg4, region: BgRegion) =
  
  # todo: assert region is within bounds of bg4.
  
  let (layout, x1, y1, x2, y2) = region
  let (gx1, gy1, gx2, gy2) = (x1 shr 3, y1 shr 3, x2 shr 3, y2 shr 3)
  var regionTiles: seq[Tile4]
  var deleteList: seq[int]
  var refCount = newSeq[int](bg4.img.len)
  
  # Count how many times each tile in the image data is referred to.
  for se in bg4.map:
    inc refCount[se.tid]
  
  template addTile(x, y: int) =
    
    # Decrease the ref count for a tile in the region, and
    # mark for deletion if nobody else is referring to it.
    let i = x + y * bg4.w
    var se = bg4.map[i]
    let tid = se.tid
    dec refCount[tid]
    if refCount[tid] == 0:
      deleteList.add(tid)
    
    # Make a copy of the img data for a tile in the region.
    var tile = bg4.img[tid]
    if se.hflip:
      tile = tile.flipX()
    if se.vflip:
      tile = tile.flipY()
    regionTiles.add(tile)
  
  template replaceTileInMap(x, y, startTid, j: int) =
    let i = x + y * bg4.w
    var se = bg4.map[i]
    se.hflip = false
    se.vflip = false
    se.tid = startTid + j
    bg4.map[i] = se
    bg4.img.add regionTiles[j]
  
  case layout
  of Chr4c:
    for x in gx1..gx2:
      for y in gy1..gy2:
        addTile(x, y)
  of Chr4r:
    for y in gy1..gy2:
      for x in gx1..gx2:
        addTile(x, y)
  
  # Delete tiles from the map and img data.
  deleteList.sort(Descending)
  for tid in deleteList:
    bg4.img.delete(tid)
    for se in mitems(bg4.map):
      if se.tid >= tid:
        se.tid = se.tid - 1
  
  let startTid = bg4.img.len
  
  case layout
  of Chr4c:
    var j = 0
    for x in gx1..gx2:
      for y in gy1..gy2:
        replaceTileInMap(x, y, startTid, j)
        inc j
  of Chr4r:
    var j = 0
    for y in gy1..gy2:
      for x in gx1..gx2:
        replaceTileInMap(x, y, startTid, j)
        inc j

proc applyOffsets(bg4: var Bg4; flags: set[BgFlag]; palOffset, tileOffset: int) =
  if palOffset > 0:
    for se in mitems(bg4.map):
      se.palbank = se.palbank + palOffset
  if tileOffset > 0:
    for se in mitems(bg4.map):
      if (se.tid > 0) or (bfBlankTile notin flags):
        se.tid = se.tid + tileOffset

proc applyOffsets(bg8: var Bg8; flags: set[BgFlag]; palOffset, tileOffset: int) =
  if palOffset > 0:
    for tile in mitems(bg8.img):
      for pixel in mitems(tile):
        if pixel != 0:
          pixel += (palOffset * 16).uint8
  if tileOffset > 0:
    for se in mitems(bg8.map):
      if (se.tid > 0) or (bfBlankTile notin flags):
        se.tid = se.tid + tileOffset

proc applyOffsets(bgAff: var BgAff; flags: set[BgFlag]; palOffset, tileOffset: int) =
  if palOffset > 0:
    for tile in mitems(bgAff.img):
      for pixel in mitems(tile):
        if pixel != 0:
          pixel += (palOffset * 16).uint8
  if tileOffset > 0:
    for id in mitems(bgAff.map):
      var n = id.int
      if (n > 0) or (bfBlankTile notin flags):
        n += tileOffset
        doAssert(n in 0..255, &"tileOffset of {tileOffset} pushes tile {id} outside the range 0..255")
      id = n.uint8

proc writeBackgroundC(f: File; name, img, map, pal: string; data: BgData) =
  include "templates/background.c.template"

proc writeBackgroundsC(f: File; bgRows: seq[BgRow]) =
  include "templates/backgrounds.c.template"

proc writeBackgroundsNim(f: File; bgRows: seq[BgRow]; bgDatas: seq[BgData]) =
  include "templates/backgrounds.nim.template"


proc bgConvert*(tsvPath, script, indir, outdir: string) =
  
  var bgRows: seq[BgRow]
  
  let outputBgDir = outdir / "backgrounds"
  let outputCPath = outdir / "backgrounds.c"
  let outputNimPath = outdir / "backgrounds.nim"
  
  var newestModifiedIn = getLastModificationTime(script)
  var oldestModifiedOut = oldest(outputCPath, outputNimPath, outputBgDir)
  
  createDir(outputBgDir)
  
  # parse items from .tsv and check their modification dates
  
  for row in tsvRows(tsvPath):
    
    let (dir, name, ext) = splitFile(row[0])
    doAssert ext in ["", ".png"], "Only PNG files accepted (" & name & ext & ")"
    
    let pngPath = indir / dir / name & ".png"
    doAssert(fileExists(pngPath), "No such file " & pngPath)
    newestModifiedIn = newest(newestModifiedIn, pngPath, pngPath.parentDir)
    
    let bgName = "bg" & name.toCamelCase(firstUpper=true)
    bgRows.add BgRow(
      pngPath: pngPath,
      name: bgName,
      kind: parseEnum[BgKind](row[1]),
      palOffset: parseInt(row[2]),
      tileOffset: parseInt(row[3]),
      flags: cast[set[BgFlag]](parseUInt(row[4])),
      regions: parseRegions(row[5]),
      tileComp: parseEnum[CompressionKind](row[6]),
      mapComp: parseEnum[CompressionKind](row[7])
    )
    oldestModifiedOut = oldest(oldestModifiedOut, outputBgDir / bgName & ".c")
  
  # regenerate the output files if any input files have changed:
  
  if newestModifiedIn > oldestModifiedOut:
    
    echo "Converting backgrounds:"
    
    var bgDatas: seq[BgData]
    
    for row in bgRows:
      
      let bgCPath = outputBgDir / row.name & ".c"
      
      var data: BgData
      var convert = false
      
      if fileExists(bgCPath):
        if getLastModificationTime(row.pngPath) > getLastModificationTime(bgCPath):
          convert = true
        else:
          # re-read properties from last time we converted this BG
          withFile bgCPath, fmRead:
            file.setFilePos(3)
            data = to[BgData](file.readLine())
            convert =
              row.kind != data.kind or
              row.flags != data.flags or
              row.palOffset != data.palOffset.int or
              row.tileOffset != data.tileOffset.int or
              row.regions != data.regions or
              row.tileComp != data.tileComp or
              row.mapComp != data.mapComp
      else:
        convert = true
      
      if convert:
        echo row.pngPath

        # convert the BG
        
        if row.regions.len > 0:
          doAssert row.kind == bkReg4bpp,
            "Regions can only be used with 4bpp backgrounds."
        
        var w, h: int
        var img, map, pal: string
        
        case row.kind
        of bkReg4bpp:
          var bg4 = loadBg4(
            row.pngPath,
            indexed = (bfAutoPal notin row.flags),
            firstBlank = (bfBlankTile in row.flags),
          )
          for region in row.regions:
            bg4.applyRegion(region)
          bg4.applyOffsets(row.flags, row.palOffset, row.tileOffset)
          (w, h) = (bg4.w, bg4.h)
          
          if row.regions.len > 0 and bfScreenblock in row.flags:
            doAssert w == 32, "Regions cannot be used with backgrounds arranged into screenblocks that are wider than 1 screenblock."
          
          img = bg4.img.toBytes()
          pal = joinPalettes(bg4.pals).toBytes()
          map = if bfScreenblock in row.flags:
                  bg4.map.toScreenblocks(bg4.w).toBytes()
                else:
                  bg4.map.toBytes()
        
        of bkReg8bpp:
          
          doAssert(bfAutoPal notin row.flags, "Auto palette reduction is for 4bpp backgrounds only.")
          
          var bg8 = loadBg8(
            row.pngPath,
            firstBlank = (bfBlankTile in row.flags),
          )
          bg8.applyOffsets(row.flags, row.palOffset, row.tileOffset)
          (w, h) = (bg8.w, bg8.h)
          img = bg8.img.toBytes()
          pal = bg8.pal.toBytes()
          map = if bfScreenblock in row.flags:
                  bg8.map.toScreenblocks(bg8.w).toBytes()
                else:
                  bg8.map.toBytes()
        
        of bkAff:
          doAssert(bfScreenblock notin row.flags, "Affine BGs don't use screenblocks.")
          doAssert(bfAutoPal notin row.flags, "Auto palette reduction is for 4bpp backgrounds only.")
          
          var bgAff = loadBgAff(
            row.pngPath,
            firstBlank = (bfBlankTile in row.flags),
          )
          bgAff.applyOffsets(row.flags, row.palOffset, row.tileOffset)
          (w, h) = (bgAff.w, bgAff.h)
          img = bgAff.img.toBytes()
          pal = bgAff.pal.toBytes()
          map = bgAff.map.toBytes()
        
        # compression
        case row.tileComp
        of None: discard
        of Rle: img = rleCompress(img)
        
        case row.mapComp
        of None: discard
        of Rle: map = rleCompress(map)
        
        # update and write data
        data = BgData(
          kind: row.kind,
          w: w, h: h,
          imgWords: (img.len div 4).uint16,
          mapWords: (map.len div 4).uint16,
          palHalfwords: (pal.len div 2).uint16,
          palOffset: row.palOffset.uint16,
          tileOffset: row.tileOffset.uint16,
          flags: row.flags,
          regions: row.regions,
          tileComp: row.tileComp,
          mapComp: row.mapComp
        )
        withFile bgCPath, fmWrite:
          file.writeBackgroundC(row.name, img, map, pal, data)
      
      # push to list
      bgDatas.add(data)
    
    withFile outputCPath, fmWrite:
      file.writeBackgroundsC(bgRows)
    withFile outputNimPath, fmWrite:
      file.writeBackgroundsNim(bgRows, bgDatas)
  
  else:
    echo "Skipping backgrounds."


# Command Line Interface
# ----------------------

proc bgConvert*(p: var OptParser, progName: static[string] = "bgconvert") =
  
  const helpMsg = """

Usage:
  """ & progName & """ filename.tsv --indir:DIR --outdir:DIR

Desc
"""
  
  var
    filename: string
    indir: string
    outdir: string
    script: string
  
  while true:
    next(p)
    case p.kind
    of cmdArgument:
      filename = p.key
    of cmdLongOption, cmdShortOption:
      case p.key
      of "script": script = p.val
      of "indir": indir = p.val
      of "outdir": outdir = p.val
      of "h","help": quit(helpMsg, 0)
      else: quit("Unrecognised option '" & p.key & "'\n" & helpMsg)
    of cmdEnd:
      break
  
  if filename == "": quit("Please pass in a .tsv file\n" & helpMsg, 0)
  if script == "": quit("Please specify the bg script\n" & helpMsg, 0)
  if indir == "": quit("Please specify the input directory\n" & helpMsg, 0)
  if outdir == "": quit("Please specify the output directory\n" & helpMsg, 0)
  
  bgConvert(filename, script, indir, outdir)

