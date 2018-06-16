//
//  Bitmap mode functionality
//
//! \file tonc_bitmap.c
//! \author J Vijn
//! \date 20060604 - 20060604
//
/* === NOTES ===
	* 20070822. These are old routines, which have been replaced by 
		'bmp8_' and 'bmp16' variants.
*/

#include "tonc_memmap.h"
#include "tonc_core.h"
#include "tonc_video.h"

// --- Internal drawing routines --------------------------------------

// --- 8bit bitmap ---

//! Draw a horizontal line in 8bit mode; internal routine.
/*!	\param dst		Destination buffer.
*	\param width	Length of line. 
*	\param clrid	Color index to draw.
*	\note	Does not do normalization or bounds checks.
*/
void bm8_hline(u8 *dst, int width, u8 clrid)
{
	// TODO: add normalization

	u16 *phw= (u16*)((u32)dst&~1);
	if( (u32)dst&1 )
	{
		*phw= (*phw & 0xFF) + (clrid<<8);
		width--;	phw++;
	}
	if(width&1)
		phw[width>>1]= (phw[width>>1]&~0xFF) + clrid;
	width >>= 1;
	if(width)
		memset16(phw, dup8(clrid), width);
}

//! Draw a vertical line in 8bit mode; internal routine.
/*!	\param dst		Destination buffer.
*	\param height	Length of line. 
*	\param clrid	Color index to draw.
*	\param pitch	Pitch of buffer.
*	\note	Does not do normalization or bounds checks.
*/
void bm8_vline(u8 *dst, int height, u8 clrid, int pitch)
{
	u16 *phw= (u16*)((u32)dst&~1);
	pitch >>= 1;
	if( (u32)dst&1 )
	{
		while(height--)
		{	*phw= (*phw& 0xFF) + (clrid<<8);	phw += pitch;	}
	}
	else
	{
		while(height--)
		{	*phw= (*phw&~0xFF) + clrid;			phw += pitch;	}
	}
}

//! Draw a rectangle in 8bit mode; internal routine.
/*!	\param dst		Destination buffer.
*	\param width	Rectangle width.
*	\param height	Rectangle height. 
*	\param clrid	Color index to draw.
*	\param pitch	Pitch of buffer.
*	\note	Does not do normalization or bounds checks.
*/
void bm8_rect(u8 *dst, int width, int height, u8 clrid, int pitch)
{
	int h;
	u16 *dst16, pxl;
	pitch >>= 1;
	if( (u32)dst&1 )	// crap, unaligned pixel on left
	{
		dst16= (u16*)((u32)dst&~1);
		h= height;
		while(h--)
		{	*dst16= (*dst16&0xFF)|(clrid<<8);	dst16 += pitch;	}
		// adjust for drawn line
		width--;
		dst++;
	}
	// dst is even here

	if(width&1)			// crap, unaligned pixel on right
	{
		dst16= (u16*)&dst[width&~1];
		h= height;
		while(h--)
		{	*dst16= (*dst16&0xFF00)|clrid;	dst16 += pitch;	}
		// no adjustment required ... yet
	}

	width >>= 1;
	if(width == 0)
		return;
	
	dst16= (u16*)dst;
	pxl= clrid|(clrid<<8);

	while(height--)		// main stint
	{
		memset16(dst16, pxl, width);
		dst16 += pitch;
	}
}

//! Draw a rectangle border in 8bit mode; internal routine
/*!	\param dst		Destination buffer.
*	\param width	Frame width.
*	\param height	Frame height. 
*	\param clrid	Color index to draw.
*	\param pitch	Pitch of buffer.
*	\note	Does not do normalization or bounds checks.
*/
void bm8_frame(u8 *dst, int width, int height, u8 clrid, int pitch)
{
	// left and right lines
	bm8_vline(dst, height, clrid, pitch);
	bm8_vline(&dst[width-1], height, clrid, pitch);

	if((u32)dst&1)
	{	dst++;	width--;	}
	width >>= 1;
	if(width==0)
		return;
	// top and bottom lines (if necessary)
	memset16(dst, dup8(clrid), width);
	if(height>1)
		memset16(&dst[pitch], dup8(clrid), width);
}

// --- 16bit bitmap ---

//! Draw a horizontal line in 16bit mode; internal routine
/*!	\param dst		Destination buffer.
*	\param width	Length of line.
*	\param clr		Color to draw.
*	\note	Does not do normalization or bounds checks.
*/
void bm16_hline(u16 *dst, int width, u16 clr)
{
	memset16(dst, clr, width);
}

//! Draw a vertical line in 16bit mode; internal routine
/*!	\param dst		Destination buffer.
*	\param height	Length of line.
*	\param clr		Color to draw.
*	\param pitch	Pitch of buffer.
*	\note	Does not do normalization or bounds checks.
*/
void bm16_vline(u16 *dst, int height, u16 clr, int pitch)
{
	while(height--)
	{
		*dst= clr;
		dst += pitch;
	}
}

//! Draw a line in 16bit mode; internal routine
/*!	\param dst		Destination buffer.
*	\param dx		Horizontal line length.
*	\param dy		Vertical line length.
*	\param clr		Color to draw.
*	\param pitch	Pitch of buffer.
*/
void bm16_line(u16 *dst, int dx, int dy, COLOR clr, int pitch)
{
	int ii, xstep, ystep, dd;
	
	// --- Normalization ---

	if(dx<0)
	{	xstep= -1;	dx= -dx;	}
	else
		xstep= +1;

	if(dy<0)
	{	ystep= -pitch;	dy= -dy;	}
	else
		ystep= +pitch;

	// --- Drawing ---

	if(dy == 0)			// Horizontal
	{
		for(ii=0; ii<=dx; ii++)
			dst[ii*xstep]= clr;
	}
	else if(dx == 0)	// Vertical
	{
		for(ii=0; ii<=dy; ii++)
			dst[ii*ystep]= clr;
	}
	else if(dx>=dy)		// Diagonal, slope <= 1
	{
		dd= 2*dy - dx;

		for(ii=0; ii<=dx; ii++)
		{
			*dst= clr;
			if(dd >= 0)
			{	dd -= 2*dx;	dst += ystep;	}

			dd += 2*dy;
			dst += xstep;
		}				
	}
	else				// Diagonal, slope > 1
	{
		dd= 2*dx - dy;

		for(ii=0; ii<=dy; ii++)
		{
			*dst= clr;
			if(dd >= 0)
			{	dd -= 2*dy;	dst += xstep;	}

			dd += 2*dx;
			dst += ystep;
		}		
	}
}


//! Draw a rectangle in 16bit mode; internal routine.
/*!	\param dst		Destination buffer.
*	\param width	Rectangle width.
*	\param height	Rectangle height. 
*	\param clr		Color to draw.
*	\param pitch	Pitch of buffer.
*	\note	No bound checks; normalization switches TL and RB coords
*/
void bm16_rect(u16 *dst, int width, int height, u16 clr, int pitch)
{
	if(width<0)
	{	dst += width;			width= -width;		}

	if(height<0)
	{	dst += height*pitch;	height= -height;	}
	
	while(height--)
	{
		memset16(dst, clr, width);
		dst += pitch;
	}
}

//! Draw a rectangle border in 16bit mode; internal routine.
/*!	\param dst		Destination buffer.
*	\param width	Frame width.
*	\param height	Frame height. 
*	\param clr		Color to draw.
*	\param pitch	Pitch of buffer.
*	\note	No bound checks; normalization switches TL and RB coords
*/
void bm16_frame(u16 *dst, int width, int height, u16 clr, int pitch)
{
	if(width<0)
	{	dst += width;			width= -width;		}

	if(height<0)
	{	dst += height*pitch;	height= -height;	}

	// top line
	memset16(dst, clr, width);
	if(height<2)
		return;

	dst += pitch;
	// center lines
	while(--height)
	{
		*dst= clr;
		dst[width-1]= clr;
		dst += pitch;
	}
	// bottom line
	memset16(dst, clr, width);
}
