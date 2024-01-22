{.compile: "./bios.c".}

const rleHeaderTag = 0x30

proc RLUnComp_Impl(src: pointer; dst: pointer) {.exportc.} =
  let src = cast[ptr UncheckedArray[byte]](src)
  let dst = cast[ptr UncheckedArray[byte]](dst)
  
  assert(src[0] == rleHeaderTag)
  
  let dstLen = 
    (src[1].cint) or
    (src[2].cint shl 8) or
    (src[3].cint shl 16)
  
  var srci = 4
  var dsti = 0
  
  while dsti < dstLen:
    let b = src[srci].byte
    inc srci
    
    if (b and 0x80) != 0:
      # compressed run
      let size = min((b and 0x7f).cint + 3, dstLen - dsti)
      for j in 0..<size:
        dst[dsti] = src[srci]
        inc dsti
      inc srci
    else:
      # noncompressed run
      let size = min(b.cint + 1, dstLen - dsti)
      for j in 0..<size:
        dst[dsti] = src[srci]
        inc dsti
        inc srci
