//
//  Text system header file
//
//! \file tonc_text.h
//! \author J Vijn
//! \date 20060605 - 20060605
//
// === NOTES ===
//
/* === NOTES ===
	* 20070822: These routines have been superceded by TTE.
	* This file is NOT meant to contain the Mother Of All Text Systems.
	  Rather, this contains the bases to build text-systems on, 
	  whether they are map-based, bitmap-based or sprite-based. 
	* Text systems tend to be a little fickle, I'll probably add things 
	  over time.
	* On use. There are 'standard' initialisers, the txt_init_xxx 
	  things, that set up default conditions: using toncfont, 8x8 chars, 
	  palettes, that sort of thing. For the rest, just use xxx_puts to 
	  write a string and xxx_clrs to clear it again. If you want other 
	  fonts or an other charmap you can change it, within limits. 
*/


#ifndef TONC_TEXT
#define TONC_TEXT

#include "tonc_memmap.h"
#include "tonc_memdef.h"
#include "tonc_core.h"

/*!	\addtogroup grpText
	\deprecated While potentially still useful, TTE is considerably 
	more advanced. Use that instead.
*/

/*! \defgroup grpTextTile Tilemap text
*	\ingroup grpText
*/

/*! \defgroup grpTextBm Bitmap text
*	\ingroup grpText
*/

/*! \defgroup grpTextObj Object text
*	\ingroup grpText
*/


// --------------------------------------------------------------------
// CONSTANTS
// --------------------------------------------------------------------


#define toncfontTilesLen 768


// --------------------------------------------------------------------
// CLASSES 
// --------------------------------------------------------------------


//!
typedef struct tagTXT_BASE
{
	u16 *dst0;      //!< writing buffer starting point
	u32 *font;      // pointer to font used
	 u8 *chars;     // character map (chars as in letters, not tiles)
	 u8 *cws;       // char widths (for VWF)
	 u8  dx,dy;     // letter distances
	u16  flags;     // for later
	 u8  extra[12]; // ditto
} ALIGN4 TXT_BASE;


// --------------------------------------------------------------------
// GLOBALS 
// --------------------------------------------------------------------


extern const u32 toncfontTiles[192];

extern TXT_BASE __txt_base, *gptxt;
extern u8 txt_lut[256];

extern u16 *vid_page;


// --------------------------------------------------------------------
// PROTOTYPES 
// --------------------------------------------------------------------


// --- overall (tonc_text.c) ---

/*! \addtogroup grpText
	\brief	Text writers for all modes and objects.

	There are three types of text writers here:
	<ul>
	  <li>Tilemap (<code>se_</code> routines)
	  <li>Bitmap (<code>bm_</code> and <code>m<i>x</i>_</code> routines)
	  <li>Object (<code>obj_</code> routines)
	</ul>
	Each of these has an initializer, a char writer, and string writer
	and a string clearer. The general interface for all of these is
	<code>foo(x, y, string/char, special)</code>, Where x and y are the
	positions <b>in pixels</b>, and special depends on the mode-type:
	it can be a color, base screenentry or whatever.<br>
	The clearing routines also use a string parameter, which is used to
	indicate the exact area to clear. You're free to clear the whole
	buffer if you like.
*/
/*!	\{	*/

void txt_init_std();
void txt_bup_1toX(void *dstv, const void *srcv, u32 len, int bpp, u32 base);

/*!	\}	*/


//! \addtogroup grpTextTile
/*!	\{	*/

// --- Tilemap text (tonc_text_map.c) ---
void txt_init_se(int bgnr, u16 bgcnt, SCR_ENTRY se0, u32 clrs, u32 base);
void se_putc(int x, int y, int c, SCR_ENTRY se0);
void se_puts(int x, int y, const char *str, SCR_ENTRY se0);
void se_clrs(int x, int y, const char *str, SCR_ENTRY se0);

/*!	\}	*/


// --- Bitmap text (tonc_text_bm.c) ---

//! \addtogroup grpTextBm
/*!	\{	*/

//! \name Mode-independent functions
//\{
void bm_putc(int x, int y, int c, COLOR clr);
void bm_puts(int x, int y, const char *str, COLOR clr);
void bm_clrs(int x, int y, const char *str, COLOR clr);
//\}

//! \name Mode 3 functions
//\{
INLINE void m3_putc(int x, int y, int c, COLOR clr);
INLINE void m3_puts(int x, int y, const char *str, COLOR clr);
INLINE void m3_clrs(int x, int y, const char *str, COLOR clr);
//\}

//! \name Mode 4 functions
//\{
INLINE void m4_putc(int x, int y, int c, u8 clrid);
INLINE void m4_puts(int x, int y, const char *str, u8 clrid);
INLINE void m4_clrs(int x, int y, const char *str, u8 clrid);
//\}

//! \name Mode 5 functions
//\{
INLINE void m5_putc(int x, int y, int c, COLOR clr);
INLINE void m5_puts(int x, int y, const char *str, COLOR clr);
INLINE void m5_clrs(int x, int y, const char *str, COLOR clr);
//\}

// \name Internal routines
//\{
void bm16_putc(u16 *dst, int c, COLOR clr, int pitch);
void bm16_puts(u16 *dst, const char *str, COLOR clr, int pitch);
void bm16_clrs(u16 *dst, const char *str, COLOR clr, int pitch);

void bm8_putc(u16 *dst, int c, u8 clrid);
void bm8_puts(u16 *dst, const char *str, u8 clrid);
//\}


/*!	\}	*/


// --- Object text (tonc_text_oam.c) ---

//! \addtogroup grpTextObj
/*!	\{	*/

INLINE void obj_putc2(int x, int y, int c, u16 attr2, 
	OBJ_ATTR *obj0);
INLINE void obj_puts2(int x, int y, const char *str, u16 attr2, 
	OBJ_ATTR *obj0);

void txt_init_obj(OBJ_ATTR *obj0, u16 attr2, u32 clrs, u32 base);
void obj_putc(int x, int y, int c, u16 attr2);
void obj_puts(int x, int y, const char *str, u16 attr2);
void obj_clrs(int x, int y, const char *str);

/*!	\}	*/


// --------------------------------------------------------------------
// MACROS 
// --------------------------------------------------------------------

// === INLINES=========================================================


// --- Bitmap text ---

//! Write character \a c to (x, y) in color \a clr in mode 3
INLINE void m3_putc(int x, int y, int c, COLOR clr)
{	bm16_putc(&vid_mem[y*240+x], c, clr, 240);	}

//! Write string \a str to (x, y) in color \a clr in mode 3
INLINE void m3_puts(int x, int y, const char *str, COLOR clr)
{	bm16_puts(&vid_mem[y*240+x], str, clr, 240);	}

//! Clear the space used by string \a str at (x, y) in color \a clr in mode 3
INLINE void m3_clrs(int x, int y, const char *str, COLOR clr)
{	bm16_clrs(&vid_mem[y*240+x], str, clr, 240);	}



//! Write character \a c to (x, y) in color-index \a clrid in mode 4
INLINE void m4_putc(int x, int y, int c, u8 clrid)
{	bm8_putc(&vid_page[(y*240+x)>>1], c, clrid);	}

//! Write string \a str to (x, y) in color-index \a clrid in mode 4
INLINE void m4_puts(int x, int y, const char *str, u8 clrid)
{	bm8_puts(&vid_page[(y*240+x)>>1], str, clrid);	}

//! Clear the space used by string \a str at (x, y) in color-index \a clrid in mode 4
INLINE void m4_clrs(int x, int y, const char *str, u8 clrid)
{
	gptxt->dx >>= 1;
	bm16_clrs(&vid_page[(y*240+x)>>1], str, dup8(clrid), 120);	
	gptxt->dx <<= 1;
}

//! Write character \a c to (x, y) in color \a clr in mode 5
INLINE void m5_putc(int x, int y, int c, COLOR clr)
{	bm16_putc(&vid_page[y*160+x], c, clr, 160);	}

//! Write string \a str to (x, y) in color \a clr in mode 5
INLINE void m5_puts(int x, int y, const char *str, COLOR clr)
{	bm16_puts(&vid_page[y*160+x], str, clr, 160);	}

//! Clear the space used by string \a str at (x, y) in color \a clr in mode 5
INLINE void m5_clrs(int x, int y, const char *str, COLOR clr)
{	bm16_clrs(&vid_page[y*160+x], str, clr, 160);	}



// --- Object text ---

//! Write character \a c to (x, y) in color \a clr using objects \a obj0 and on
INLINE void obj_putc2(int x, int y, int c, u16 attr2, 
	OBJ_ATTR *obj0)
{
	gptxt->dst0= (u16*)obj0;
	obj_putc(x, y, c, attr2);
}

//! Write string \a str to (x, y) in color \a clr using objects \a obj0 and on
INLINE void obj_puts2(int x, int y, const char *str, u16 attr2, 
	OBJ_ATTR *obj0)
{
	gptxt->dst0= (u16*)obj0;
	obj_puts(x, y, str, attr2);
}

#endif // TONC_TEXT
