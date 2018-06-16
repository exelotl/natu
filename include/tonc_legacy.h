//
//  Legacy #defines to keep old code working
//
//! \file tonc_legacy.h
//! \author J Vijn
//! \date 20070131 - 20070131
//
// === NOTES ===
// * Many names have changed in tonclib 1.3, which would break 
//   old code so hard. To make things a little easier, here is 
//   a list of redefines for compatibility. 
//   Note that the system is not perfect, but it will have to do.

#ifndef TONC_LEGACY
#define TONC_LEGACY

#define TONC_DROPPED(x)		[[x has been removed from tonclib. Sorry.]]


// --------------------------------------------------------------------
// pre v1.3 legacy
// --------------------------------------------------------------------

// === tonc_bios.h ===

#define RESET_SIO		RESET_REG_SIO
#define RESET_SOUND		RESET_REG_SOUND
#define RESET_OTHER		RESET_REG


// === tonc_core.h ===

#define BF_PREP			BFN_PREP
#define BF_GET			BFN_GET
#define BF_SET			BFN_SET

#define BF_PREP2		BFN_PREP2
#define BF_GET2			BFN_GET2
#define BF_SET2			BFN_SET2


// === tonc_memdef.h ===

#define BLD_BD			BLD_BACKDROP

#define	SSTAT_OFF		SSTAT_DISABLE
#define SSTAT_ON		SSTAT_ENABLE

#define DMA_DST_FIX		DMA_DST_FIXED
#define DMA_DST_RESET	DMA_DST_RELOAD
#define DMA_SRC_FIX		DMA_SRC_FIXED
#define DMA_AT_SPEC		DMA_AT_SPECIAL
#define DMA_ON			DMA_ENABLE

#define TM_ON			TM_ENABLE

#define IRQ_TM0			IRQ_TIMER0
#define IRQ_TM1			IRQ_TIMER1
#define IRQ_TM2			IRQ_TIMER2
#define IRQ_TM3			IRQ_TIMER3
#define IRQ_COM			IRQ_SERIAL
#define IRQ_KEYS		IRQ_KEYPAD
#define IRQ_CART		IRQ_GAMEPAK


// === tonc_types.h ===

#define CODE_IN_IWRAM		IWRAM_CODE
#define CODE_IN_IEWRAM		EWRAM_CODE

#define DATA_IN_IWRAM		IWRAM_DATA
#define DATA_IN_EWRAM		EWRAM_DATA
#define BSS_IN_EWRAM		EWRAM_BSS


// === tonc_video.h ===

// Old internal drawing routines.
void bm8_hline(u8 *dst, int width, u8 clrid);
void bm8_vline(u8 *dst, int height, u8 clrid, int pitch);
void bm8_rect(u8 *dst, int width, int height, u8 clrid, int pitch);
void bm8_frame(u8 *dst, int width, int height, u8 clrid, int pitch);

void bm16_hline(u16 *dst, int width, u16 clr);
void bm16_vline(u16 *dst, int height, u16 clr, int pitch);
void bm16_line(u16 *dst, int dx, int dy, COLOR clr, int pitch);
void bm16_rect(u16 *dst, int width, int height, u16 clr, int pitch);
void bm16_frame(u16 *dst, int width, int height, u16 clr, int pitch);

#define VID_WIDTH		SCREEN_WIDTH
#define VID_HEIGHT		SCREEN_HEIGHT


#define bg_aff_dflt		bg_aff_default


// --------------------------------------------------------------------
// pre v1.3b legacy
// --------------------------------------------------------------------


// Specials for OAM buffer.  

//! Declaration macro for shadow OAM
#define OAM_BUFFER_DECLARE(attr)				\
	extern attr OBJ_ATTR obj_buffer[128];		\
	extern OBJ_AFFINE * const obj_aff_buffer;

//! Definition macro for shadow OAM.
#define OAM_BUFFER_DEFINE(attr)					\
	attr OBJ_ATTR obj_buffer[128];				\
	OBJ_AFFINE * const obj_aff_buffer= (OBJ_AFFINE*)obj_buffer;


// === originally in: affine.h ========================================

#define BGAFF					AFF_DST
#define BGAFF_EX				AFF_DST_EX
#define oa_copy					obj_aff_copy
#define oa_transform			obj_aff_set
#define oa_identity				obj_aff_identity
#define oa_scale				obj_aff_scale
#define oa_shearx				obj_aff_shearx
#define oa_sheary				obj_aff_sheary
#define oa_rotate				obj_aff_rotate
#define oa_rotscale				obj_aff_rotscale

#define oa_postmultiply			obj_aff_postmul
#define oa_rotscale2			obj_aff_rotscale2
#define oa_scale_inv			obj_aff_scale_inv
#define oa_rotate_inv			obj_aff_rotate_inv
#define oa_shearx_inv			obj_aff_shearx_inv
#define oa_sheary_inv			obj_aff_sheary_inv
#define oa_rotscale_inv				TONC_DROPPED(oa_rotscale_inv)

#define bga_copy					TONC_DROPPED(bga_copy)
#define bga_transform			bg_aff_set
#define bga_identity			bg_aff_identity

#define bga_postmultiply		bg_aff_postmul
#define bga_rotscale			bg_aff_rotscale
#define bga_rotate				bg_aff_rotate
#define bga_rotscale2			bg_aff_rotscale2
#define bga_scale				bg_aff_scale
#define bga_shearx				bg_aff_shearx
#define bga_sheary				bg_aff_sheary
#define bga_rotate_inv				TONC_DROPPED(bga_rotate_inv)
#define bga_rotscale_inv			TONC_DROPPED(bga_rotscale_inv)
#define bga_scale_inv				TONC_DROPPED(bga_scale_inv)
#define bga_shearx_inv				TONC_DROPPED(bga_shearx_inv)
#define bga_sheary_inv				TONC_DROPPED(bga_sheary_inv)
#define bga_rs_ex				bg_rotscale_ex

#define BGA_STRIDE				BG_AFF_OFS
#define OA_STRIDE				OBJ_AFF_OFS


// === originally in: bg.h ============================================

#define BG_MOS					BG_MOSAIC
#define _BG_16C					BG_4BPP
#define BG_256C					BG_8BPP
#define _BG_REG_S32				BG_REG_32x32
#define BG_REG_WIDE				BG_REG_64x32
#define BG_REG_TALL				BG_REG_32x64
#define BG_REG_S64				BG_REG_64x64
#define _BG_AFF_S16				BG_AFF_16x16
#define BG_AFF_S32				BG_AFF_32x32
#define BG_AFF_S64				BG_AFF_64x64
#define BG_AFF_S128				BG_AFF_128x128
#define BG_CNT_BUILD			BG_BUILD

#define SE_16C_MASK				SE_PALBANK_MASK
#define SE_16C_SHIFT			SE_PALBANK_SHIFT
#define SE_16C					SE_PALBANK

#define SB_ENTRY				SCR_ENTRY
#define BGINFO						TONC_DROPPED(BGINFO)
#define BGPOINT					BG_POINT

#define bg_cnt_mem				REG_BGCNT
#define bg_ofs_mem				REG_BG_OFS
#define bga_ex_mem				REG_BG_AFFINE

#define map_fill				se_fill
#define map_fill_line			se_hline
#define map_fill_rect			se_rect

#define bg_sbb2cnt(x)			BF_PREP(x, BG_SBB)
#define bg_cbb2cnt(x)			BF_PREP(x, BG_CBB)
#define bg_pal2cnt(x)			BF_PREP(x, SE_PALBANK)
#define bg_cnt2sbb(y)			BF_GET(y, BG_SBB)
#define bg_cnt2cbb(y)			BF_GET(y, BG_CBB)
#define bg_cnt2pal(y)			BF_GET(y, SE_PALBANK)


// === originally in: color.h =========================================

#define _RGB15					RGB15
#define pal_bg_set					TONC_DROPPED(pal_bg_set)
#define pal_bg_mset					TONC_DROPPED(pal_bg_mset)
#define pal_bg_copy					TONC_DROPPED(pal_bg_copy)
#define pal_bg_rotate				TONC_DROPPED(pal_bg_rotate)
#define pal_obj_set					TONC_DROPPED(pal_obj_set)
#define pal_obj_mset				TONC_DROPPED(pal_obj_mset)
#define pal_obj_copy				TONC_DROPPED(pal_obj_copy)
#define pal_obj_rotate				TONC_DROPPED(pal_obj_rotate)


// === originally in: core.h ==========================================

#define BF_MSK					BF_PREP
#define BF_UNMSK				BF_GET
#define BF_INS					BF_SET
#define BF_MSK2					BF_PREP2
#define BF_UNMSK2				BF_GET2
#define BF_INS2					BF_SET2

#define INT2FIX					int2fx
#define FIX2INT					fx2int
#define FIX_FRAC				fx2ufrac
#define FIX_SCF					FIX_SCALEF
#define FIX_SCF_				FIX_SCALEF_INV
#define FIX2FLOAT				fx2float
#define FLOAT2FIX				float2fx


//#define SWAP					SWAP3
//#define CLAMP						TONC_DROPPED(CLAMP)
//#define REFLECT						TONC_DROPPED(REFLECT)
//#define WRAP						TONC_DROPPED(WRAP)

#define qrng(x)					qran_range(0, x)
#define qrng2					qran_range

#define GIT_CPY					GRIT_CPY
#define memrot16					TONC_DROPPED(memrot16)

#define _DMA_DST_INC			DMA_DST_INC
#define _DMA_SRC_INC			DMA_SRC_INC
#define _DMA_16					DMA_16
#define _DMA_AT_NOW				DMA_AT_NOW

#define dma_mem					REG_DMA
//#define DMA_ENABLE(ch)			dma_mem[ch].cnt |= DMA_ON
//#define DMA_DISABLE(ch)			dma_mem[ch].cnt &= ~DMA_ON
#define dma_memcpy				dma3_cpy
#define dma_memset				dma3_fill
#define DMA_FILL				dma_fill

#define TM_BASE_FREQ				0x01000000

#define _TM_FREQ_SYS			TM_FREQ_SYS
#define _TM_FREQ_1				TM_FREQ_1

#define PROF_START				profile_start
#define PROF_END				profile_stop


// === originally in: divlut ==========================================

#define DIV_SIZE					TONC_DROPPED(DIV_SIZE)
#define DIV						div_lut
//#define RECT						TONC_DROPPED(RECT)
#define rc_pos					rc_set_pos
#define rc_size					rc_set_size
#define rc_norm					rc_normalize


// === originally in: interrupts.h ====================================

#define IF_VBLANK				IRQ_VBLANK
#define IF_HBLANK				IRQ_HBLANK
#define IF_VCOUNT				IRQ_VCOUNT
#define IF_TM0					IRQ_TM0
#define IF_TM1					IRQ_TM1
#define IF_TM2					IRQ_TM2
#define IF_TM3					IRQ_TM3
#define IF_COM					IRQ_COM
#define IF_DMA0					IRQ_DMA0
#define IF_DMA1					IRQ_DMA1
#define IF_DMA2					IRQ_DMA2
#define IF_DMA3					IRQ_DMA3
#define IF_KEYS					IRQ_KEYS
#define IF_CART					IRQ_CART

#define IF_MASK						0x3FFF

#define IF_TM_MASK					TONC_DROPPED(IF_TM_MASK)
#define IF_TM_SHIFT					TONC_DROPPED(IF_TM_SHIFT)
#define IF_TM						TONC_DROPPED(IF_TM)
#define IF_DMA_MASK					TONC_DROPPED(IF_DMA_MASK)
#define IF_DMA_SHIFT				TONC_DROPPED(IF_DMA_SHIFT)
#define IF_DMA						TONC_DROPPED(IF_DMA)

#define IntrTable					TONC_DROPPED(IntrTable)
#define IntrMain				isr_master_nest
#define int_init				IRQ_INIT
#define int_dummy				NULL
#define int_enable_ex			irq_add
#define int_disable_ex			irq_delete
#define INT_ENABLE(x)				REG_IE |= x
#define INT_DISABLE(x)				REG_IE &= ~x


// === originally in: input.h =========================================

#define KEY_CNT_IRQ				KCNT_IRQ
#define _KEY_CNT_OR				KCNT_OR
#define KEY_CNT_AND				KCNT_AND
#define key_irq_cond(x)				REG_KEYCNT= x


// === originally in: luts.h ==========================================

#define SIN_MASK				511
#define lut_sin					lu_sin
#define lut_cos					lu_cos

// === originally in: oam.h ===========================================

#define OE_COUNT				128
#define OAE_COUNT				32

#define _OE_A0_AFF_OFF			ATTR0_REG
#define OE_A0_AFF_ON			ATTR0_AFF
#define OE_A0_HIDE				ATTR0_HIDE
#define OE_A0_DBL_BIT			ATTR0_AFF_DBL_BIT
#define OE_A0_AFF_DBL			ATTR0_AFF_DBL
#define OE_A0_BLEND				ATTR0_BLEND
#define OE_A0_WIN				ATTR0_WINDOW
#define OE_A0_MOS				ATTR0_MOSAIC
#define _OE_A0_16C				ATTR0_4BPP
#define OE_A0_256C				ATTR0_8BPP
#define _OE_A0_SQUARE			ATTR0_SQUARE
#define OE_A0_WIDE				ATTR0_WIDE
#define OE_A0_TALL				ATTR0_TALL
#define OE_A0_Y_MASK			ATTR0_Y_MASK
#define OE_A0_Y_SHIFT			ATTR0_Y_SHIFT
#define OE_A0_Y					ATTR0_Y
#define OE_A0_MODE_MASK			ATTR0_MODE_MASK
#define OE_A0_MODE_SHIFT		ATTR0_MODE_SHIFT
#define OE_A0_MODE				ATTR0_MODE
#define OE_A0_GFX_MASK				TONC_DROPPED(OE_A0_GFX_MASK)
#define OE_A0_GFX_SHIFT				TONC_DROPPED(OE_A0_GFX_SHIFT)
#define OE_A0_GFX					TONC_DROPPED(OE_A0_GFX)
#define OE_A0_SHAPE_MASK		ATTR0_SHAPE_MASK
#define OE_A0_SHAPE_SHIFT		ATTR0_SHAPE_SHIFT
#define OE_A0_SHAPE				ATTR0_SHAPE
#define OE_A0_BUILD				ATTR0_BUILD

#define OE_A1_HFLIP				ATTR1_HFLIP
#define OE_A1_VFLIP				ATTR1_VFLIP
#define _OE_A1_SIZE_8			ATTR1_SIZE_8
#define OE_A1_SIZE_16			ATTR1_SIZE_16
#define OE_A1_SIZE_32			ATTR1_SIZE_32
#define OE_A1_SIZE_64			ATTR1_SIZE_64
#define OE_A1_X_MASK			ATTR1_X_MASK
#define OE_A1_X_SHIFT			ATTR1_X_SHIFT
#define OE_A1_X					ATTR1_X
#define OE_A1_AFF_MASK			ATTR1_AFF_ID_MASK
#define OE_A1_AFF_SHIFT			ATTR1_AFF_ID_SHIFT
#define OE_A1_AFF				ATTR1_AFF_ID
#define OE_A1_FLIP_MASK			ATTR1_FLIP_MASK
#define OE_A1_FLIP_SHIFT		ATTR1_FLIP_SHIFT
#define OE_A1_FLIP				ATTR1_FLIP
#define OE_A1_SIZE_MASK			ATTR1_SIZE_MASK
#define OE_A1_SIZE_SHIFT		ATTR1_SIZE_SHIFT
#define OE_A1_SIZE				ATTR1_SIZE
#define OE_A1_BUILD_R			ATTR1_BUILDR
#define OE_A1_BUILD_A			ATTR1_BUILDA

#define OE_A2_ID_MASK			ATTR2_ID_MASK
#define OE_A2_ID_SHIFT			ATTR2_ID_SHIFT
#define OE_A2_ID				ATTR2_ID
#define OE_A2_PRIO_MASK			ATTR2_PRIO_MASK
#define OE_A2_PRIO_SHIFT		ATTR2_PRIO_SHIFT
#define OE_A2_PRIO				ATTR2_PRIO
#define OE_A2_16C_MASK			ATTR2_PALBANK_MASK
#define OE_A2_16C_SHIFT			ATTR2_PALBANK_SHIFT
#define OE_A2_16C				ATTR2_PALBANK
#define OE_A2_BUILD				ATTR2_BUILD

#define OAM_ENTRY				OBJ_ATTR
#define OAM_AFF_ENTRY			OBJ_AFFINE
#define oe_buffer					obj_buffer
#define oa_buffer					obj_aff_buffer

//#define oam_init					TONC_DROPPED(oam_init)
//#define oam_update				TONC_DROPPED(oam_update)
#define oe_oam2aff					TONC_DROPPED(oe_oam2aff)
#define oe_oam2prio					TONC_DROPPED(oe_oam2prio)
#define oe_oam2pal					TONC_DROPPED(oe_oam2pal)
#define oe_set_attr				obj_set_attr
#define oe_hide					obj_hide
#define oe_unhide				obj_unhide
#define oe_set_pos				obj_set_pos
#define oe_copy(dst, src)		obj_copy(dst, src, 1)
#define oam_update(start, num)	oam_copy(&oam_mem[start], &obj_buffer[start], num)
#define oe_update(start, num)	obj_copy(&oam_mem[start], &obj_buffer[start], num)
#define oe_rs_ex				obj_rotscale_ex
#define oa_update(start, num)	oj_aff_copy(&oam_mem[start], &obj_buffer[start], num)
#define oam_update_all()		oam_copy(oam_mem, obj_buffer, 128)
#define oe_update_all()			obj_copy(obj_mem, obj_buffer, 128)
#define oa_update_all()			obj_aff_copy(obj_aff, obj_aff_buffer, 32)
#define oe_aff2oam(x)			BF_PREP(x, ATTR1_AFF_ID)
#define oe_prio2oam(x)			BF_PREP(x, ATTR2_PRIO)
#define oe_pal2oam(x)			BF_PREP(x, ATTR2_PBANK)


// === originally in: regs.h ==========================================

#define REG_INTMAIN				REG_ISR_MAIN


// === originally in: swi.h ===========================================

#define BGAffineSource			BgAffineSource
#define BGAffineDest			BgAffineDest


// === originally in: text.h ==========================================

#define oe_putc2					obj_putc2
#define oe_puts2					obj_puts2
#define txt_init_oe					txt_init_obj
#define oe_putc						obj_putc
#define oe_puts						obj_puts
#define oe_clrs						obj_clrs


// === originally in: types.h =========================================

#define SB_ENTRY				SCR_ENTRY
#define SB_AFF_ENTRY			SCR_AFF_ENTRY


// === originally in: vid.h ===========================================

#define tile_mem_obj_hi			tile_mem[5]

#define _DCNT_MODE0				DCNT_MODE0
#define _DCNT_OBJ_2D			DCNT_OBJ_2D
#define DCNT_BG0_ON				DCNT_BG0
#define DCNT_BG1_ON				DCNT_BG1
#define DCNT_BG2_ON				DCNT_BG2
#define DCNT_BG3_ON				DCNT_BG3
#define DCNT_OBJ_ON				DCNT_OBJ
#define DCNT_WIN0_ON			DCNT_WIN0
#define DCNT_WIN1_ON			DCNT_WIN1
#define DCNT_WINOBJ_ON			DCNT_WINOBJ
#define DCNT_BG_MASK				TONC_DROPPED(DCNT_BG_MASK)
#define DCNT_BG_SHIFT				TONC_DROPPED(DCNT_BG_SHIFT)

#define vid_cnt						TONC_DROPPED(vid_cnt)
#define vid_set_mode(x)			BF_SET(REG_DISPCNT, DCNT_MODE)
#define vid_is_vblank				TONC_DROPPED(vid_is_vblank)
#define vid_irq_cond				TONC_DROPPED(vid_irq_cond)
#define _vid_vline8					TONC_DROPPED(_vid_vline8)
#define _vid_rect8					TONC_DROPPED(_vid_rect8)
#define _vid_rect16					TONC_DROPPED(_vid_rect16)

#define vid_mosaic				REG_MOSAIC= MOS_BUILD
#define bld_cnt					REG_BLDCNT= BLD_BUILD
#define bld_cnt_top(x)			BF_SET(REG_BLDCNT, _x, BLD_TOP)
#define bld_cnt_mode(x)			BF_SET(REG_BLDCNT, _x, BLD_MODE)
#define bld_cnt_bottom(x)		BF_SET(REG_BLDCNT, _x, BLD_BOT)
#define bld_set_weights			REG_BLDALPHA= BLDA_BUILD
#define bld_set_fade			REG_BLDY= BLDY_BUILD
#define win0_set_rect				TONC_DROPPED(win0_set_rect)
#define win1_set_rect				TONC_DROPPED(win1_set_rect)
#define win_in_cnt					TONC_DROPPED(win_in_cnt)
#define win0_cnt					TONC_DROPPED(win0_cnt)
#define win1_cnt					TONC_DROPPED(win1_cnt)
#define win_out_cnt					TONC_DROPPED(win_out_cnt)
#define win_obj_cnt					TONC_DROPPED(win_obj_cnt)


#endif // TONC_LEGACY

// EOF
