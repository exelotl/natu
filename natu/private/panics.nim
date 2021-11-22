{.warning[UnusedImport]: off.}
import ./common

{.emit:"""/*INCLUDESECTION*/
#include "tonc_memmap.h"
#include "tonc_memdef.h"
#include "tonc_core.h"
#include "tonc_video.h"
#include "tonc_tte.h"
#include "tonc_bios.h"
""".}

# TODO:
# rewrite this in pure Nim
# make it available to fatal.nim via importc
# put the "common" {.compile.} pragmas back in their relevant modules.

proc panic*(msg1: cstring; msg2: cstring = nil) {.exportc: "natuPanic", noreturn.} =
  {.emit:"""
    REG_IME = 0;
    RegisterRamReset(RESET_VRAM | RESET_REG_SOUND | RESET_REG);
    REG_DISPCNT = DCNT_BG0;
    
    int bgnr = 0;
    u16 bgcnt = BG_CBB(0) | BG_SBB(31);
    tte_init_chr4c(bgnr, bgcnt, 0xF000, 0x0201, CLR_ORANGE<<16|CLR_WHITE, &verdana9Font, NULL);
    
    pal_bg_bank[0][0] = RGB15(0,0,4);
    tte_set_pos(8, 8);
    tte_set_margins(8, 8, 232, 152);
    tte_write("AN ERROR OCCURRED:\n\n");
    tte_write(msg1);
    if (msg2) {
      tte_write(msg2);
    }
    while (1) {
      ASM_NOP();
    }
  """.}
