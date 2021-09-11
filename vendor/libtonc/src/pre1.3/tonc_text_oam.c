//
//  Object text system file
//
//! \file tonc_text_oam.c
//! \author J Vijn
//! \date 20060605 - 20060605
//
// === NOTES ===

#include "tonc_core.h"
#include "tonc_oam.h"
#include "tonc_text.h"


// --------------------------------------------------------------------
// FUNCTIONS 
// --------------------------------------------------------------------



//! Sets up internals for fixed-width object text
/*!	\param obj0		Pointer to an object buffer to use for the characters.
*	\param attr2	Base attr2. This allows a greater range in
*	  capabilities, like offset tile-starts and palettes. 
*	\param clrs		Colors to use for the text. The palette entries
*	  used depends on \a se0 and \a bupofs.
*	\param bupofs	Flags for font bit-unpacking. Basically indicates
*	  pixel values (and hence palette use).
*/
void txt_init_obj(OBJ_ATTR *obj0, u16 attr2, u32 clrs, u32 bupofs)
{
	gptxt->dst0= (u16*)obj0;
	
	// What the hell am I doing? Shading my 1bpp font :p
	// (A 0xnm offset for a 1-4 bup gives m+1 for the real nybbles 
	//  and n for the empty nybble on its right)
	COLOR *pbank= pal_obj_bank[BFN_GET(attr2, ATTR2_PALBANK)];
	pbank[(bupofs+1)&15]= clrs&0xFFFF;
	pbank[(bupofs>>4)&15]= clrs>>16;
	
	//ASM_CMT("bup");
	// bup the tiles
	//BUP bup= { toncfontTilesLen, 1, 4, bupofs};
	//BitUnPack(toncfontTiles, &tile_mem[4][tileofs], &bup);
	txt_bup_1toX(&tile_mem[4][attr2&ATTR2_ID_MASK], toncfontTiles, 
		toncfontTilesLen, 4, bupofs);
}

//!	Print character \a c with objects (x, y) with base \a attr2
/*!	\param x	x-coordinate in pixels
*	\param y	y-coordinate in pixels.
*	\param c	Character to print.
*	\param attr2	Base attr2, for offset font-tile starts and palettes.
*/
void obj_putc(int x, int y, int c, u16 attr2)
{
	if(c == '\n')
		return;

	OBJ_ATTR *obj= (OBJ_ATTR*)gptxt->dst0;

	obj->attr0= y & ATTR0_Y_MASK;
	obj->attr1= x & ATTR1_X_MASK;
	obj->attr2= gptxt->chars[c] + attr2;	
}

//!	Print string \a str with objects at pixel (x, y) with base \a attr2
/*!	\param x	x-coordinate in pixels
*	\param y	y-coordinate in pixels.
*	\param str	String to print.
*	\param attr2	Base attr2, for offset font-tile starts and palettes.
*/
void obj_puts(int x, int y, const char *str, u16 attr2)
{
	int c, x0= x;
	OBJ_ATTR *obj= (OBJ_ATTR*)gptxt->dst0;

	while((c=*str++) != 0)
	{
		if(c == '\n')	// line break
		{	y += gptxt->dy; x= x0; }
		else
		{
			if(c != ' ')
			{
				obj->attr0= y & ATTR0_Y_MASK;
				obj->attr1= x & ATTR1_X_MASK;
				obj->attr2= gptxt->chars[c] + attr2;
				obj++;
			}
			x += gptxt->dx;
		}
	}	
}

//!	Clear an object-string \a str
/*!	\param x	x-coordinate in pixels.
*	\param y	y-coordinate in pixels.
*	\param str	String indicating which area is used.
*/
void obj_clrs(int x, int y, const char *str)
{
	int c;
	OBJ_ATTR *obj= (OBJ_ATTR*)gptxt->dst0;

	while((c=*str++) != 0)
	{
		if(c != '\n' && c != ' ')
			obj_hide(obj++);
	}	
}

// EOF
