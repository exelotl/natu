import private/[acsl, types, memmap, core, math, bios, reg]
export types, core, math, bios, reg

# Exporting memmap arrays.
# (size constants are unnecessary because you can do e.g. sizeof(sramMem))

{.push warning[Deprecated]: off.}

# Palette
export
  bgColorMem,
  bgPalMem,
  objColorMem,
  objPalMem,
  palBgMem,
  palObjMem,
  palBgBank,
  palObjBank

# VRAM
export
  bgTileMem,
  bgTileMem8,
  objTileMem,
  objTileMem8,
  tileMem,
  tile8Mem,
  tileMemObj,
  tile8MemObj,
  seMem,
  seMat,
  vidMem,
  m3Mem,
  m4Mem,
  m5Mem,
  vidMemFront,
  vidMemBack,
  m4MemBack,
  m5MemBack

# OAM
export
  oamMem,
  objMem,
  objAffMem

# ROM
export romMem

# SRAM
export sramMem

{.pop.}
