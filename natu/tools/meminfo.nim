import std/[strformat, strutils, tables, parseopt, parsecsv, os, osproc, strscans]

type
  Options = object
    filename: string
  
  SectionInfo = object
    idx: int
    name: string
    size: int
    vma: int   # virtual memory address  (see below)
    lma: int   # load memory address
    fileOff: int
    algnBase: int
    algnPow: int

#[
  https://stackoverflow.com/a/7289730/445113
  
  Every loadable or allocatable output section has two addresses.
  The first is the VMA, or virtual memory address. This is the address
  the section will have when the output file is run. The second is the
  LMA, or load memory address. This is the address at which the section
  will be loaded. In most cases the two addresses will be the same. An
  example of when they might be different is when a data section is
  loaded into ROM, and then copied into RAM when the program starts up
  (this technique is often used to initialize global variables in a ROM
  based system). In this case the ROM address would be the LMA, and the
  RAM address would be the VMA.
]#

proc run(opts: Options) =
  
  let p = startProcess(
    "arm-none-eabi-objdump",
    args = ["-h", opts.filename],
    options = { poUsePath },
  )
  
  var sections: Table[string, SectionInfo]
  
  for s in lines(p):
    var sec = SectionInfo()
    let matched = s.scanf(
      # e.g.
      # "  7 .data         00000934  030057e0  09df6850  01e157e0  2**3"
      "$s$i$s.$w$s$h$s$h$s$h$s$h$s$i**$i",
      sec.idx,
      sec.name,
      sec.size,
      sec.vma,
      sec.lma,
      sec.fileOff,
      sec.algnBase,
      sec.algnPow,
    )
    if matched:
      sections[sec.name] = sec
  
  const romMax = 32 * 1024 * 1024
  const ewramMax = 256 * 1024
  const iwramMax = 32 * 1024
  
  const romMaxM = romMax / (1024 * 1024)
  const ewramMaxK = ewramMax / 1024
  const iwramMaxK = iwramMax / 1024
  
  proc sum(args: varargs[string]): int =
    for s in args:
      if s in sections:
        result += sections[s].size
  
  var romUsage = sum(
    "gba_crt0",
    "text",
    "rodata",
    "ARM.extab",
    "ARM.exidx",
    "preinit_array",
    "init_array",
    "fini_array",
    
    # dkp stuff
    "crt0",
    "init",
    "plt",
    "fini",
    "ctors",
    "dtors",
    "eh_frame",
    "gcc_except_table",
  )
  var iwramUsage = sum(
    "bss",
    "data",
    "iwram",
    
    # dkp stuff, ignore overlays for now?
    "preinit_array",
    "init_array",
    "fini_array",
    "jcr",
  )
  var ewramUsage = sum(
    "sbss",
    "ewram",
  )
  
  let romUsageM = romUsage / (1024 * 1024)
  let iwramUsageK = iwramUsage / 1024
  let ewramUsageK = ewramUsage / 1024
  
  echo &"ROM:   {romUsageM:.2f} / {romMaxM.int} MiB ({100 * romUsage/romMax:.2f}%)"
  echo &"IWRAM: {iwramUsageK:.2f} / {iwramMaxK.int} KiB ({100 * iwramUsage/iwramMax:.2f}%)"
  echo &"EWRAM: {ewramUsageK:.2f} / {ewramMaxK.int} KiB ({100 * ewramUsage/ewramMax:.2f}%)"
  echo &"Available Stack: {(iwramMax - iwramUsage) / 1024 :.2f} KiB"
  echo &"Available Heap: {(ewramMax - ewramUsage) / 1024 :.2f} KiB"


proc meminfo*(p: var OptParser, progName: static[string] = "meminfo") =
  
  const helpMsg = """
Usage:
  """ & progName & """ filename.elf
"""
  var opts = Options(
    filename: "",
  )
  
  for kind, k, v in p.getopt():
    case kind
    of cmdLongOption, cmdShortOption:
      case k
      of "help": quit(helpMsg, 0)
      else: quit("Unrecognised option '" & k & "'\n" & helpMsg)
    of cmdArgument:
      opts.filename = k
    of cmdEnd:
      discard
  
  if opts.filename == "":
    quit("No filename specified.\n" & helpMsg, 0)
  elif not opts.filename.endsWith ".elf":
    quit("Please provide a .elf file.\n" & helpMsg, 0)
  
  run(opts)

when isMainModule:
  var p = initOptParser(shortNoVal = {}, longNoVal = @[])
  meminfo(p)
