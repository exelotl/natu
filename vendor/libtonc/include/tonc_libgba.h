//
// tonc-libgba compatibility header
//
//! \file tonc_libgba.h
//! \author J Vijn
//! \date 20070921 - 20070921
/* === NOTES ===
  * Only the parts that have some overlap are covered here. 
*/

/* libgba copyright header:
	Copyright 2003-2007 by Dave Murphy.

	This library is free software; you can redistribute it and/or
	modify it under the terms of the GNU Library General Public
	License as published by the Free Software Foundation; either
	version 2 of the License, or (at your option) any later version.

	This library is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
	Library General Public License for more details.

	You should have received a copy of the GNU Library General Public
	License along with this library; if not, write to the Free Software
	Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307
	USA.

	Please report all bugs and problems through the bug tracker at
	"http://sourceforge.net/tracker/?group_id=114505&atid=668551".
*/
 

#ifndef TONC_LIBGBA
#define TONC_LIBGBA

#include "tonc_memmap.h"


// --------------------------------------------------------------------
//# fade.h
// --------------------------------------------------------------------

// --------------------------------------------------------------------
//# gba_affine.h (semi-complete)
//	ISSUE: member name incompatibility
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// gba_base.h (complete)
// --------------------------------------------------------------------

#define VRAM			MEM_VRAM
#define IWRAM			MEM_IWRAM
#define EWRAM			MEM_EWRAM
#define EWRAM_END		(MEM_EWRAM+EWRAM_SIZE)
#define SRAM			MEM_SRAM

#define SystemCall		swi_call

#define FILL			CS_FILL
#define COPY16			CS_CPY16
#define COPY32			CS_CPY32


// --------------------------------------------------------------------
//# gba_compression.h (semi-complete)
//	ISSUE: BUP member incompatilibity
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// gba_dma.h (complete)
// --------------------------------------------------------------------

//#define DMA_DST_INC			DMA_DST_INC
//#define DMA_DST_DEC			DMA_DST_DEC
//#define DMA_DST_FIXED		DMA_DST_FIXED
//#define DMA_DST_RELOAD		DMA_DST_RELOAD
//#define DMA_SRC_INC			DMA_SRC_INC
//#define DMA_SRC_DEC			DMA_SRC_DEC
//#define DMA_SRC_FIXED		DMA_SRC_FIXED
//#define DMA_REPEAT			DMA_REPEAT
#define DMA16				DMA_16
#define DMA32				DMA_32
#define GAMEPAK_DRQ			DMA_GAMEPAK
#define DMA_IMMEDIATE		DMA_AT_NOW
#define DMA_VBLANK			DMA_AT_VBLANK
#define DMA_HBLANK			DMA_AT_HBLANK
//#define DMA_SPECIAL			DMA_AT_SPECIAL
//#define DMA_IRQ				DMA_IRQ
//#define DMA_ENABLE			DMA_ON


#define DMA_Copy(channel, source, dest, mode)		\
DMA_TRANSFER(dest, source, mode, channel, DMA_ON)

static inline void dmaCopy(const void *source, void *dest, u32 size)
{
	DMA_Copy(3, source, dest, DMA16 | (size>>1));
}

#define	DMA0COPY( source, dest, mode) DMA_Copy(0,(source),(dest),(mode))
#define	DMA1COPY( source, dest, mode) DMA_Copy(1,(source),(dest),(mode))
#define	DMA2COPY( source, dest, mode) DMA_Copy(2,(source),(dest),(mode))
#define	DMA3COPY( source, dest, mode) DMA_Copy(3,(source),(dest),(mode))


// --------------------------------------------------------------------
// gba_input.h (complete (hopefully))
// Note the subtle change in meaning:
//	"Held"	actually means being down.
//	"Down"	means *going* down, not being down
//	"Up" means *going* up, not being up.
// --------------------------------------------------------------------

//#define KEY_A				KEY_A
//#define KEY_B				KEY_B
//#define KEY_SELECT			KEY_SELECT
//#define KEY_START			KEY_START
//#define KEY_RIGHT			KEY_RIGHT
//#define KEY_LEFT			KEY_LEFT
//#define KEY_UP				KEY_UP
//#define KEY_DOWN			KEY_DOWN
//#define KEY_R				KEY_R
//#define KEY_L				KEY_L
#define DPAD 				KEY_DIR

#define KEYIRQ_ENABLE		KCNT_IRQ
#define KEYIRQ_OR			KCNT_OR
#define KEYIRQ_AND			KCNT_AND


#define scanKeys			key_poll
#define keysDown()			key_hit(KEY_FULL)
#define keysDownRepeat()	key_repeat(KEY_FULL)
#define keysUp()			key_released(KEY_FULL)
#define keysHeld()			key_is_down(KEY_FULL)
#define setRepeat			key_repeat_limits


// --------------------------------------------------------------------
//# gba_interrupt.h
//	ISSUE:: the libgba irq functions works slightly different than 
//	mine. This has yet to be resolved
// --------------------------------------------------------------------

typedef void (*IntFn)(void);

#define INT_VECTOR			REG_ISR_MAIN

//#define IRQ_VBLANK			IRQ_VBLANK
//#define IRQ_HBLANK			IRQ_HBLANK
//#define IRQ_VCOUNT			IRQ_VCOUNT
//#define IRQ_TIMER0			IRQ_TM0
//#define IRQ_TIMER1			IRQ_TM1
//#define IRQ_TIMER2			IRQ_TM2
//#define IRQ_TIMER3			IRQ_TM3
//#define IRQ_SERIAL			IRQ_COM
//#define IRQ_DMA0			IRQ_DMA0
//#define IRQ_DMA1			IRQ_DMA1
//#define IRQ_DMA2			IRQ_DMA2
//#define IRQ_DMA3			IRQ_DMA3
//#define IRQ_KEYPAD			IRQ_KEYS
//#define IRQ_GAMEPAK			IRQ_CART

//# TODO: actual irq functions


// --------------------------------------------------------------------
// gba_multiboot.h (complete)
// --------------------------------------------------------------------

#define MODE32_NORMAL		MBOOT_NORMAL
#define MODE16_MULTI		MBOOT_MULTI
#define MODE32_2MHZ			MBOOT_FAST


// --------------------------------------------------------------------
// gba_sio.h
//	TODO: move to tonc_memdef.h probably
// --------------------------------------------------------------------

//! \name	SIOCNT bits
//\{ 
#define SIO_8BIT			0x0000	//!< Normal 8-bit communication mode
#define SIO_32BIT			0x1000	//!< Normal 32-bit communication mode
#define SIO_MULTI			0x2000	//!< Multi-play communication mode
#define SIO_UART			0x3000	//!< UART communication mode
#define SIO_IRQ				0x4000	//!< Enable serial irq
//\}				
				
//!	\name	Baud rate settings				
//\{
#define SIO_9600			0x0000	
#define SIO_38400			0x0001	
#define SIO_57600			0x0002	
#define SIO_115200			0x0003	
				
#define SIO_CLK_INT			(1<<0)	//!< Select internal clock
#define SIO_2MHZ_CLK		(1<<1)	//!< Select 2MHz clock
#define SIO_RDY				(1<<2)	//!< Opponent SO state
#define SIO_SO_HIGH			(1<<3)	//!< Our SO state
#define SIO_START			(1<<7)	
//\}				
				
//! \name	SIO modes set with REG_RCNT				
//\{
#define R_NORMAL			0x0000	
#define R_MULTI				0x0000	
#define R_UART				0x0000	
#define R_GPIO				0x8000	
#define R_JOYBUS			0xC000		
//\}
					
//! \name	General purpose mode control bits used with REG_RCNT					
//\{
#define	GPIO_SC				0x0001	// Data
#define	GPIO_SD				0x0002		
#define	GPIO_SI				0x0004		
#define	GPIO_SO				0x0008	
	
#define	GPIO_SC_IO			0x0010	// Select I/O	
#define	GPIO_SD_IO			0x0020		
#define	GPIO_SI_IO			0x0040		
#define	GPIO_SO_IO			0x0080
		
#define	GPIO_SC_INPUT		0x0000	// Input setting	
#define	GPIO_SD_INPUT		0x0000		
#define	GPIO_SI_INPUT		0x0000		
#define	GPIO_SO_INPUT		0x0000
	
#define	GPIO_SC_OUTPUT		0x0010	// Output setting
#define	GPIO_SD_OUTPUT		0x0020	
#define	GPIO_SI_OUTPUT		0x0040	
#define	GPIO_SO_OUTPUT		0x0080	
//\}


// --------------------------------------------------------------------
// gba_sound.h
//	TODO: move structs to tonc_sound.h or tonc_bios.h
// --------------------------------------------------------------------

typedef struct {
	u16 type;
	u16 stat;
	u32 freq;
	u32 loop;
	u32 size;
	s8 data[1];
} WaveData;

typedef struct {
	u8 Status;
	u8 reserved1;
	u8 RightVol;
	u8 LeftVol;
	u8 Attack;
	u8 Decay;
	u8 Sustain;
	u8 Release;
	u8 reserved2[24];
	u32 fr;
	WaveData *wp;
	u32 reserved3[6];
} SoundChannel;

#define PCM_DMA_BUF 1584
#define MAX_DIRECTSOUND_CHANNELS 12

typedef struct {
	u32 ident;
	vu8 DmaCount;
	u8 reverb;
	u8 maxchn;
	u8 masvol;
	u8 freq;
	u8 mode;
	u8 r2[6];
	u32 r3[16];
	SoundChannel vchn[MAX_DIRECTSOUND_CHANNELS];
	s8 pcmbuf[PCM_DMA_BUF*2];
} SoundArea;


#define SND1_L_ENABLE		SDMG_LSQR1
#define SND2_L_ENABLE		SDMG_LSQR2
#define SND3_L_ENABLE		SDMG_LWAVE
#define SND4_L_ENABLE		SDMG_LNOISE

#define SND1_R_ENABLE		SDMG_RSQR1
#define SND2_R_ENABLE		SDMG_RSQR2
#define SND3_R_ENABLE		SDMG_RWAVE
#define SND4_R_ENABLE		SDMG_RNOISE


#define SNDA_VOL_50			SDS_A50
#define SNDA_VOL_100		SDS_A100
#define SNDB_VOL_50			SDS_B50
#define SNDB_VOL_100		SDS_B100
#define SNDA_R_ENABLE		SDS_AR
#define SNDA_L_ENABLE		SDS_AL
#define SNDA_RESET_FIFO		SDS_ARESET
#define SNDB_R_ENABLE		SDS_BR
#define SNDB_L_ENABLE		SDS_BL
#define SNDB_RESET_FIFO		SDS_BRESET


// *almost* REG_WAVE_RAM, but that's vu32*
#define WAVE_RAM	((vu16*)(REG_BASE+0x0090))


//!	\name	Sound 3 control bits
//\{
#define SOUND3_STEP32		(0<<5)	// Use two banks of 32 steps each
#define SOUND3_STEP64		(1<<5)	// Use one bank of 64 steps
#define SOUND3_SETBANK(n)	(n<<6)	// Bank to play 0 or 1 (non set bank is written to)
#define SOUND3_PLAY			(1<<7)	// Output sound
#define SOUND3_STOP			(0<<7)	// Stop sound output
//\}


// void SoundDriverInit(SoundArea *sa);
// u32  MidiKey2Freq(WaveData *wa, u8 mk, u8 fp);


// --------------------------------------------------------------------
// gba_sprites.h (complete)
// --------------------------------------------------------------------

#define OBJATTR				OBJ_ATTR
#define OBJAFFINE			OBJ_AFFINE

typedef struct SpriteEntry {
	u16 attribute[3];
	u16 dummy;
} ALIGN(4) SpriteEntry;


#define OAM					oam_mem
#define OBJ_BASE_ADR		((void*)(tile_mem[4]))
#define SPRITE_GFX			(( u16*)(tile_mem[4]))
#define BITMAP_OBJ_BASE_ADR	((void*)(tile_mem[5]))

#define SQUARE				(ATTR0_SQUARE>>14)
#define WIDE				(ATTR0_WIDE>>14)
#define TALL				(ATTR0_TALL>>14)


enum SPRITE_SIZECODE {
		Sprite_8x8  = 0, Sprite_16x16, Sprite_32x32, Sprite_64x64,
		Sprite_16x8 = 0, Sprite_32x8 , Sprite_32x16, Sprite_64x32,
		Sprite_8x16 = 0, Sprite_8x32 , Sprite_16x32, Sprite_32x64
};

// === Oam bits, set 1 ===

#define ATTR0_NORMAL			ATTR0_REG
#define ATTR0_ROTSCALE			ATTR0_AFF
#define ATTR0_DISABLED			ATTR0_HIDE
#define ATTR0_ROTSCALE_DOUBLE	ATTR0_AFF_DBL_BIT
//#define ATTR0_MOSAIC			ATTR0_MOSAIC
#define ATTR0_COLOR_16			ATTR0_4BPP
#define ATTR0_COLOR_256			ATTR0_8BPP
//#define ATTR0_SQUARE			ATTR0_SQUARE
//#define ATTR0_WIDE				ATTR0_WIDE
//#define ATTR0_TALL				ATTR0_TALL


#define ATTR1_FLIP_X		ATTR1_HFLIP
#define ATTR1_FLIP_Y		ATTR1_VFLIP
//#define ATTR1_SIZE_8		ATTR1_SIZE_8
//#define ATTR1_SIZE_16		ATTR1_SIZE_16
//#define ATTR1_SIZE_32		ATTR1_SIZE_32
//#define ATTR1_SIZE_64		ATTR1_SIZE_64

#define ATTR1_ROTDATA(n)	ATTR1_AFF_ID(m)

#define ATTR2_PRIORITY(n)	ATTR2_PRIO(m)
#define ATTR2_PALETTE(n)	ATTR2_PALBANK(m)


// === OAM bits, set 2 ===

#define OBJ_ROT_SCALE_ON	ATTR0_AFF
#define OBJ_DISABLE			ATTR0_HIDE

#define OBJ_DOUBLE			ATTR0_AFF_DBL_BIT
#define OBJ_TRANSLUCENT		ATTR0_BLEND
#define OBJ_OBJWINDOW		ATTR0_WINDOW
#define OBJ_MOSAIC			ATTR0_MOSAIC
#define OBJ_16_COLOR		ATTR0_4BPP
#define OBJ_256_COLOR		ATTR0_8BPP
#define OBJ_SQUARE			ATTR0_SQUARE
#define OBJ_WIDE			ATTR0_WIDE
#define OBJ_TALL			ATTR0_TALL


#define OBJ_Y(m)			ATTR0_Y(m)
#define OBJ_MODE(m)			((m)<<10)
#define OBJ_SHAPE(m)		ATTR0_SHAPE(m)

#define OBJ_HFLIP			ATTR1_HFLIP
#define OBJ_VFLIP			ATTR1_VFLIP
#define OBJ_X(m)			ATTR1_X(m)
#define OBJ_ROT_SCALE(m)	ATTR1_AFF_ID(m)
#define OBJ_SIZE(m)			ATTR1_SIZE(m)

#define OBJ_CHAR(m)			ATTR2_ID(m)
#define OBJ_PRIORITY(m)		ATTR2_PRIO(m)
#define OBJ_PALETTE(m)		ATTR2_PALBANK(m)


// --------------------------------------------------------------------
// gba_systemcalls.h (complete)
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// gba_timers.h (cpmplete)
// --------------------------------------------------------------------

#define TIMER_COUNT			TM_CASCADE
#define TIMER_IRQ			TM_IRQ
#define TIMER_START			TM_ENABLE


// --------------------------------------------------------------------
// gba_types.h (complete)
// --------------------------------------------------------------------

// --------------------------------------------------------------------
// gba_video.h (complete)
// --------------------------------------------------------------------

// === Palettes ===
#define BG_COLORS			pal_bg_mem
#define BG_PALETTE			pal_bg_mem

#define OBJ_COLORS			pal_obj_mem
#define SPRITE_PALETTE		pal_obj_mem


// === REG_DISPCNT bits ===
#define MODE_0				DCNT_MODE0
#define MODE_1				DCNT_MODE1
#define MODE_2				DCNT_MODE2
#define MODE_3				DCNT_MODE3
#define MODE_4				DCNT_MODE4
#define MODE_5				DCNT_MODE5
#define BACKBUFFER			DCNT_PAGE
#define OBJ_1D_MAP			DCNT_OBJ_1D
#define LCDC_OFF			DCNT_BLANK
#define BG0_ENABLE			DCNT_BG0
#define BG1_ENABLE			DCNT_BG1
#define BG2_ENABLE			DCNT_BG2
#define BG3_ENABLE			DCNT_BG3
#define OBJ_ENABLE			DCNT_OBJ
#define WIN0_ENABLE			DCNT_WIN0
#define WIN1_ENABLE			DCNT_WIN1
#define OBJ_WIN_ENABLE		DCNT_WINOBJ
#define BG_ALL_ENABLE		(0x0F00)

static inline void SetMode(int mode)	{	REG_DISPCNT= mode;	}


// === REG_DISPSTAT bits ===
#define LCDC_VBL_FLAG		DSTAT_IN_VBL
#define LCDC_HBL_FLAG		DSTAT_IN_HBL
#define LCDC_VCNT_FLAG		DSTAT_IN_VCT
#define LCDC_VBL			DSTAT_VBL_IRQ
#define LCDC_HBL			DSTAT_HBL_IRQ
#define LCDC_VCNT			DSTAT_VCT_IRQ

#define VCOUNT				DSTAT_VCT


// === REG_BGxyz things ===
#define bg_scroll			BG_POINT

#define BGCTRL				REG_BGCNT
#define BG_OFFSET			REG_BG_OFS

//#define BG_MOSAIC			BG_MOSAIC
#define BG_16_COLOR			BG_4BPP
#define BG_256_COLOR		BG_8BPP
//#define BG_WRAP			BG_WRAP
#define BG_SIZE_0			BG_SIZE0
#define BG_SIZE_1			BG_SIZE1
#define BG_SIZE_2			BG_SIZE2
#define BG_SIZE_3			BG_SIZE3

#define BG_WID_32			BG_SIZE_0
#define BG_WID_64			BG_SIZE_1
#define BG_HT_32			BG_SIZE_0
#define BG_HT_64			BG_SIZE_2

#define TEXTBG_SIZE_256x256		BG_REG_32x32
#define TEXTBG_SIZE_512x256		BG_REG_64x32
#define TEXTBG_SIZE_256x512		BG_REG_32x64
#define TEXTBG_SIZE_512x512		BG_REG_64x64
#define ROTBG_SIZE_128x128		BG_AFF_16x16
#define ROTBG_SIZE_256x256		BG_AFF_32x32
#define ROTBG_SIZE_512x512		BG_AFF_64x64
#define ROTBG_SIZE_1024x1024	BG_AFF_128x128

#define BG_PRIORITY(m)		BG_PRIO(m)
#define BG_TILE_BASE(m)		BG_CBB(m)
#define BG_MAP_BASE(m)		BG_SBB(m)
//#define BG_SIZE(m)			BG_SIZE(m)

#define TILE_BASE(m)		BG_CBB(m)
#define MAP_BASE(m)			BG_SBB(m)


// === VRAM memmap ===
#define CHAR_BASE_ADR(m)		(void*)(tile_mem[m])
#define CHAR_BASE_BLOCK(m)		(void*)(tile_mem[m])
#define TILE_BASE_ADR(m)		(void*)(tile_mem[m])
#define MAP_BASE_ADR(m)			(void*)(se_mem[m])
#define SCREEN_BASE_BLOCK(m)	(void*)(se_mem[m])

#define MODE3_LINE			M3LINE
#define MODE5_LINE			M5LINE

#define MODE3_FB			m3_mem
#define MODE5_FB			m5_mem
#define MODE5_BB			m5_mem_back


// === Miscy ===
#define RGB5				RGB15
#define RGB8(r,g,b)			( ((r)>>3) | (((g)>>3)<<5) | (((b)>>3)<<10) )


#endif // TONC_LIBGBA

// EOF
