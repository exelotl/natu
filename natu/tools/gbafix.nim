import strutils, options, math, os, parseopt

const logo = [
  0x24'u8,0xFF,0xAE,0x51,0x69,0x9A,0xA2,0x21,0x3D,0x84,0x82,0x0A,0x84,0xE4,0x09,
  0xAD,0x11,0x24,0x8B,0x98,0xC0,0x81,0x7F,0x21,0xA3,0x52,0xBE,0x19,0x93,0x09,0xCE,
  0x20,0x10,0x46,0x4A,0x4A,0xF8,0x27,0x31,0xEC,0x58,0xC7,0xE8,0x33,0x82,0xE3,0xCE,
  0xBF,0x85,0xF4,0xDF,0x94,0xCE,0x4B,0x09,0xC1,0x94,0x56,0x8A,0xC0,0x13,0x72,0xA7,
  0xFC,0x9F,0x84,0x4D,0x73,0xA3,0xCA,0x9A,0x61,0x58,0x97,0xA3,0x27,0xFC,0x03,0x98,
  0x76,0x23,0x1D,0xC7,0x61,0x03,0x04,0xAE,0x56,0xBF,0x38,0x84,0x00,0x40,0xA7,0x0E,
  0xFD,0xFF,0x52,0xFE,0x03,0x6F,0x95,0x30,0xF1,0x97,0xFB,0xC0,0x85,0x60,0xD6,0x80,
  0x25,0xA9,0x63,0xBE,0x03,0x01,0x4E,0x38,0xE2,0xF9,0xA2,0x34,0xFF,0xBB,0x3E,0x03,
  0x44,0x78,0x00,0x90,0xCB,0x88,0x11,0x3A,0x94,0x65,0xC0,0x7C,0x63,0x87,0xF0,0x3C,
  0xAF,0xD6,0x25,0xE4,0x8B,0x38,0x0A,0xAC,0x72,0x21,0xD4,0xF8,0x07
]

type GbaHeader* = object
  startCode*: array[4, byte]  ## entry point
  logo*: array[156, byte]     ## logo data
  title*: array[12, char]     ## name in upper case ASCII
  gameCode*: array[4, char]   ## matches the sticker on the cart. Format "UTTD"
  makerCode*: array[2, char]  ## commercial developer e.g. "01" = Nintendo
  fixed*: byte                ## 0x96
  unitCode*: byte             ## 0x00
  deviceType*: byte           ## 0x00 or 0x80 (for debug hardware)
  unused*: array[7, byte]
  gameVersion*: byte          ## version number, usually 0
  complement*: byte           ## must be calculated once all other fields are set
  unused2*: array[2, byte]

proc calculateChecksum*(h: GbaHeader): byte =
  let bytes = cast[ptr array[sizeof(h), byte]](unsafeAddr h)
  var c: byte
  for b in bytes[0xA0..0xBD]:
    c += b
  0'u8 - (0x19'u8 + c)

proc padToArray[N:static[int],T](s: string): array[N,T] =
  for i,c in s[0 ..< min(s.len, N)]:
    result[i] = c.T

proc gbafix*(
  filename: string,
  title = none(string),
  gameCode = none(string),
  makerCode = none(string),
  gameVersion = none(int),
  pad = false
) =
  let f = open(filename, fmReadWriteExisting)
  
  # read header
  f.setFilePos(0)
  var h: GbaHeader
  doAssert f.readBuffer(addr h, sizeof(h)) == sizeof(h)
  
  # modify header
  h.logo = logo
  h.fixed = 0x96
  if title.isSome:
    h.title = padToArray[12, char](title.get)
  elif h.title == default(array[12, char]):
    h.title = padToArray[12, char](splitFile(filename).name.toUpperAscii())
  if gameCode.isSome:
    h.gameCode = padToArray[4, char](gameCode.get)
  if makerCode.isSome:
    h.makerCode = padToArray[2, char](makerCode.get)
  if gameVersion.isSome:
    h.gameVersion = gameVersion.get.byte
  h.deviceType = 0x00
  h.complement = calculateChecksum(h)
  
  # write header
  f.setFilePos(0)
  doAssert f.writeBuffer(addr h, sizeof(h)) == sizeof(h)
  
  # add padding
  if pad:
    let size = f.getFileSize().int
    f.setFilePos(0, fspEnd)
    for _ in size..<nextPowerOfTwo(size):
      f.write(0'u8)
  
  f.close()

proc gbafix*(p: var OptParser, progName: static[string] = "gbafix") =
  
  const helpMsg = """
Usage:
  """ & progName & """ filename.gba [options]
Options:
  -t, --title:NAME      Set game title (max 12 chars). Defaults to filename if not already present in ROM.
  -c, --gameCode:CODE   Set game code (4 chars, same as "AGB-XXXX" on the game packaging).
  -m, --makerCode:CODE  Set maker code (2 chars).
  -r, --gameVersion:N   Set game version (0..255).
  -p, --pad             Pad file to next power of two.
"""
  
  var
    filename: string
    title: Option[string]
    gameCode: Option[string]
    makerCode: Option[string]
    gameVersion: Option[int]
    pad: bool
  
  for kind, k, v in p.getopt():
    case kind
    of cmdArgument:
      filename = k
    of cmdLongOption, cmdShortOption:
      case k
      of "t","title": title = some(v)
      of "c","gameCode": gameCode = some(v)
      of "m","makerCode": makerCode = some(v)
      of "r","gameVersion": gameVersion = some(parseInt(v))
      of "p","pad": pad = true
      of "h","help": quit(helpMsg, 0)
      else: quit("Unrecognised option '" & k & "'\n" & helpMsg)
    of cmdEnd:
      discard
  if filename == "":
    quit("Please specify a GBA rom.\n" & helpMsg, 0)
  
  gbafix(filename, title, gameCode, makerCode, gameVersion, pad)
  echo "ROM fixed!"

when isMainModule:
  var p = initOptParser(shortNoVal = {'p', 'h'}, longNoVal = @["pad", "help"])
  gbafix(p)
