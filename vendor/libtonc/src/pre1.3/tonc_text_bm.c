//
//! \file tonc_text_bm.c
//!   bitmap modes text system
//! \date 20050317 - 20051009
//! \author cearn
//
// === NOTES ===

#include "tonc_core.h"
#include "tonc_text.h"


// --------------------------------------------------------------------
// FUNCTIONS 
// --------------------------------------------------------------------


// === BITMAP TEXT ====================================================

//! Write character \a c to (x, y) in color \a clr in modes 3,4 or 5.
void bm_putc(int x, int y, int c, COLOR clr)
{
	switch(REG_DISPCNT&7)
	{
	case 3:
		m3_putc(x, y, c, clr);		break;
	case 4:
		m4_putc(x, y, c, (u8)clr);	break;
	case 5:
		m5_putc(x, y, c, clr);		break;
	}
}

//! Internal 16bit char-printer for modes 3 and 5.
/*!	\param dst	Destination buffer to write to.
*	\param c	Character to print.
*	\param clr	Color to use.
*	\param pitch	Pitch (in pixels) of the destination buffer.
*/
void bm16_putc(u16 *dst, int ch, COLOR clr, int pitch)
{
	if(ch == '\n')		// line break
		return;

	int ix, iy;
	u32 row;
	u8 *pch= (u8*)&gptxt->font[2*gptxt->chars[ch]];

	for(iy=0; iy<8; iy++)
	{
		row= pch[iy];
		for(ix=0; row>0; row >>= 1, ix++)
			if(row&1)
				dst[iy*pitch+ix]= clr;
	}
}

//! Internal 8bit char-printer for mode 4.
/*!	\param dst	Destination buffer to write to.
*	\param c	Character to print.
*	\param clrid	Colorindex to use.
*	\note	\a dst <i>must</i> be halfword aligned for proper output.
*/
void bm8_putc(u16 *dst, int ch, u8 clrid)
{
	if(ch == '\n')
		return;

	int ix, iy;
	u32 row, pxs;

	// point to glyph; each line is one byte
	u8 *pch= (u8*)&gptxt->font[2*gptxt->chars[ch]];
	for(iy=0; iy<8; iy++)
	{
		row= pch[iy];
		for(ix=0; row>0; row >>= 2, ix++)
		{
			pxs= dst[iy*120+ix];
			if(row&1)
				pxs= (pxs&0xFF00) | clrid;
			if(row&2)
				pxs= (pxs&0x00FF) | (clrid<<8);

			dst[iy*120+ix]= pxs;
		}
	}
}


// --- put string ---


//! Write string \a str to (x, y) in color \a clr in modes 3,4 or 5.
void bm_puts(int x, int y, const char *str, COLOR clr)
{
	switch(REG_DISPCNT&7)
	{
	case 3:
		m3_puts(x, y, str, clr);		break;
	case 4:
		m4_puts(x, y, str, (u8)clr);	break;
	case 5:
		m5_puts(x, y, str, clr);		break;
	}
}

//! Internal 16bit string-printer for modes 3 and 5.
/*!	\param dst	Destination buffer to write to.
*	\param str	String to print.
*	\param clr	Color to use.
*	\param pitch	Pitch (in pixels) of the destination buffer.
*/
void bm16_puts(u16 *dst, const char *str, COLOR clr, int pitch)
{
	int c, x=0;
	u8 *pch;

	while((c=*str++) != 0)
	{
		if(c == '\n')		// line break
		{	
			dst += pitch*gptxt->dy;	
			x=0;	
		}
		else				// normal character
		{
			int ix, iy;
			u32 row;
			// point to glyph; each line is one byte
			pch= (u8*)&gptxt->font[2*gptxt->chars[c]];
			for(iy=0; iy<8; iy++)
			{
				row= pch[iy];
				for(ix=x; row>0; row >>= 1, ix++)
					if(row&1)
						dst[iy*pitch+ix]= clr;
			}
			x += gptxt->dx;
		}
	}
}

//! Internal 8bit string-printer for mode 4.
/*!	\param dst	Destination buffer to write to.
*	\param str	String to print.
*	\param clrid	Colorindex to use.
*	\note	\a dst <i>must</i> be halfword aligned for proper output.
*/
void bm8_puts(u16 *dst, const char *str, u8 clrid)
{
	int c, x=0, dx= gptxt->dx>>1;

	while((c=*str++) != 0)
	{
		if(c == '\n')		// line break
		{	
			dst += 120*gptxt->dy;	
			x=0;	
		}
		else				// normal character
		{
			int ix, iy;
			u32 row, pxs;

			// point to glyph; each line is one byte
			u8 *pch= (u8*)&gptxt->font[2*gptxt->chars[c]];
			for(iy=0; iy<8; iy++)
			{
				row= pch[iy];
				for(ix=x; row>0; row >>= 2, ix++)
				{
					pxs= dst[iy*120+ix];
					if(row&1)
						pxs= (pxs&0xFF00) | clrid;
					if(row&2)
						pxs= (pxs&0x00FF) | (clrid<<8);

					dst[iy*120+ix]= pxs;
				}
			}
			x += dx;
		}
	}
}


// --- clear a string ---


//! Clear string \a str from (x, y) in color \a clr in modes 3,4 or 5.
void bm_clrs(int x, int y, const char *str, COLOR clr)
{
	switch(REG_DISPCNT&7)
	{
	case 3:
		m3_clrs(x, y, str, clr);		break;
	case 4:
		m4_clrs(x, y, str, (u8)clr);	break;
	case 5:
		m5_clrs(x, y, str, clr);		break;
	}
}


// NOTE: it's not worth separating '\0' here, that just gives extra code
//! Internal 16bit string-clearer for modes 3 and 5.
/*!	\param dst	Destination buffer to write to.
*	\param str	String indicating the area to erase.
*	\param clr	Color to use.
*	\param pitch	Pitch (in pixels) of the destination buffer.
*/
void bm16_clrs(u16 *dst, const char *str, COLOR clr, int pitch)
{
	int c, nx=0, ny;

	while(1)
	{
		c= *str++;
		if(c=='\n' || c=='\0')
		{
			if(nx>0)
			{
				nx *= gptxt->dx;
				ny= gptxt->dy;
				while(ny--)
				{
					memset16(dst, clr, nx);
					dst += pitch;
				}
				nx=0;
			}
			else
				dst += gptxt->dy*pitch;
			if(c=='\0')
				return;
		}
		else
			nx++;
	}

}

// EOF
