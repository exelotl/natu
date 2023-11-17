//
//  Text system file
//
//! \file tonc_text.c
//! \author J Vijn
//! \date 20060605 - 20060605
//
// === NOTES ===
// * Since BitUnPack doesn't always work properly (VBA), I've put 
//   txt_bup_1toX in here to remedy that. Wish I didn't have to. 

#include "tonc_text.h"


// --------------------------------------------------------------------
// GLOBALS 
// --------------------------------------------------------------------


u8 txt_lut[256];

TXT_BASE __txt_base;
TXT_BASE *gptxt= &__txt_base;


// --------------------------------------------------------------------
// FUNCTIONS 
// --------------------------------------------------------------------


void txt_init_std()
{
	gptxt->dx= gptxt->dy= 8;

	gptxt->dst0= vid_mem;
	gptxt->font= (u32*)toncfontTiles;
	gptxt->chars= txt_lut;
	gptxt->cws= NULL;

	int ii;
	for(ii=0; ii<96; ii++)
		gptxt->chars[ii+32]= ii;
}

void txt_bup_1toX(void *dstv, const void *srcv, u32 len, int dstB, u32 base)
{
	u32 *srcL= (u32*)srcv;
	u32 *dstL= (u32*)dstv;

	len= (len*dstB+3)>>2;		// # dst words
	u32 bBase0= base&(1<<31);	// add to 0 too?
	base &= ~(1<<31);


	u32 srcBuf=0, srcShift=32;
	u32 dstBuf  , dstShift;

	while(len--)
	{
		if(srcShift >= 32)
		{
			srcBuf= *srcL++;
			srcShift= 0;
		}
		dstBuf=0;
		for(dstShift=0; dstShift<32; dstShift += dstB)
		{
			u32 wd= srcBuf&1;
			if(wd || bBase0)
				wd += base;
			dstBuf |= wd<<dstShift;

			srcBuf >>= 1;
			srcShift++;
		}

		*dstL++= dstBuf;
	}
}

// EOF
