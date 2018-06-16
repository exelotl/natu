//
//  Map text system file
//
//! \file tonc_text_map.c
//! \author J Vijn
//! \date 20060605 - 20060605
//
// === NOTES ===

#include "tonc_memdef.h"
#include "tonc_core.h"
#include "tonc_text.h"


// --------------------------------------------------------------------
// FUNCTIONS 
// --------------------------------------------------------------------


// === TILE BG TEXT ===================================================

//! Sets up internals for fixed-width tilemap text
/*!	\param bgnr	Number of background to be used for text.
*	\param bgcnt	Background control flags.
*	\param se0		Base screen entry. This allows a greater range in
*	  capabilities, like offset tile-starts and palettes.
*	\param clrs		Colors to use for the text. The palette entries
*	  used depends on \a se0 and \a bupofs.
*	\param bupofs	Flags for font bit-unpacking. Basically indicates
*	  pixel values (and hence palette use).
*/
void txt_init_se(int bgnr, u16 bgcnt, SCR_ENTRY se0, u32 clrs, u32 bupofs)
{
	REG_BGCNT[bgnr]= bgcnt;
	gptxt->dst0= se_mem[BFN_GET(bgcnt, BG_SBB)];	

	//ASM_CMT("pal");
	// prep palette
	int bpp= (bgcnt&BG_8BPP) ? 8 : 4;
	if(bpp==4)
	{
		// Add shading to my 4bit fonts in an uber-1337 way
		// Are you expected to understand this? 
		//   Nah, didn't think so either :P
		COLOR *palbank= pal_bg_bank[BFN_GET(se0, SE_PALBANK)];
		palbank[(bupofs+1)&15]= clrs&0xFFFF;
		palbank[(bupofs>>4)&15]= clrs>>16;
	}
	else
		pal_bg_mem[(bupofs+1)&255]= clrs&0xFFFF;
	
	// account for tile-size difference
	se0 &= SE_ID_MASK;
	if(bpp==8)
		se0 *= 2;
	//ASM_CMT("bup");
	// bup the tiles
	//BUP bup= { toncfontTilesLen, 1, bpp, base };
	//BitUnPack(toncfontTiles, &tile_mem[BFN_GET(bgcnt, BG_CBB)][tileofs], &bup);
	txt_bup_1toX(&tile_mem[BFN_GET(bgcnt, BG_CBB)][se0],
		toncfontTiles, toncfontTilesLen, bpp, bupofs);

}

//!	Print character \a c on a tilemap at pixel (x, y) with base SE \a se0
/*!	\param x	x-coordinate in pixels (rounded down to 8s).
*	\param y	y-coordinate in pixels (rounded down to 8s).
*	\param c	Character to print.
*	\param se0	Base screen entry, for offset font-tile starts and palettes.
*/
void se_putc(int x, int y, int c, SCR_ENTRY se0)
{
	if(c == '\n')
		return;

	SCR_ENTRY *dst= &gptxt->dst0[(y>>3)*32+(x>>3)];
	*dst= gptxt->chars[c] + se0;
}

//!	Print string \a str on a tilemap at pixel (x, y) with base SE \a se0
/*!	\param x	x-coordinate in pixels (rounded down to 8s).
*	\param y	y-coordinate in pixels (rounded down to 8s).
*	\param str	String to print.
*	\param se0	Base screen entry, for offset font-tile starts and palettes.
*/
void se_puts(int x, int y, const char *str, SCR_ENTRY se0)
{
	int c;
	SCR_ENTRY *dst= &gptxt->dst0[(y>>3)*32+(x>>3)];

	x=0;
	while((c=*str++) != 0)
	{
		if(c == '\n')	// line break
		{	dst += (x&~31) + 32;	x= 0;	}
		else
			dst[x++] = (gptxt->chars[c]) + se0;
	}	
}

//!	Clear string \a str from a tilemap at pixel (x, y) with SE \a se0
/*!	\param x	x-coordinate in pixels (rounded down to 8s).
*	\param y	y-coordinate in pixels (rounded down to 8s).
*	\param str	String indicating which area is used.
*	\param se0	Screen entry to clear with
*/
void se_clrs(int x, int y, const char *str, SCR_ENTRY se0)
{
	int c;
	SCR_ENTRY *dst= &gptxt->dst0[(y>>3)*32+(x>>3)];

	x=0;
	while((c=*str++) != 0)
	{
		if(c == '\n')	// line break
		{	dst += (x&~31) + 32;	x= 0;	}
		else
			dst[x++] = se0;
	}	
}

// EOF
