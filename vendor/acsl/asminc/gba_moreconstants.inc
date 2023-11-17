@ Addresses relevant to BIOS
BIOS_INT_ACK	= 0x03FFFFF8
BIOS_INT_VEC	= 0x03FFFFFC

@ Bits of registers

@ DISPCNT bits
DC_MODE		= 0
DC_FRAME	= 4		@ Switch frame number (0 or 1) by this
DC_HBLANK_FREE	= 5
DC_OBJ_1D	= 6
DC_FORCEBLANK	= 7
DC_BG0EN	= 8
DC_BG1EN	= 9
DC_BG2EN	= 10
DC_BG3EN	= 11
DC_OBJEN	= 12
DC_WINDOW1	= 13
DC_WINDOW2	= 14
DC_OBJWINDOW	= 15

@ DISPSTAT bits

DS_VBLANK_FLAG	= 0
DS_HBLANK_FLAG	= 1
DS_VCOUNT_FLAG	= 2
DS_VBLANK_EN	= 3
DS_HBLANK_EN	= 4
DS_VCOUNT_EN	= 5
DS_VCOUNT	= 8		@ Shift VCount by this

@ BGxCNT bits

@ Regular BG sizes in modes 0-2
RSIZE_256x256	= 0
RSIZE_512x256	= 1
RSIZE_256x512	= 2
RSIZE_512x512	= 3
RSIZE_SHIFT	= 14
@ Affine BG sizes in modes 0-2
ASIZE_128x128	= 0
ASIZE_256x256	= 1
ASIZE_512x512	= 2
ASIZE_1024x1024	= 3
ASIZE_SHIFT	= 14

@ Base address for tile map
MAP_ADDR_RSH	= 3	@ *Right* shift the offset by this before using it in
			@ BGnCNT; values should be from 0x0000 to 0xF800 in
			@ steps of 0x0800.
@ 16- or 256- colour palette
BG_PAL256	= 7
@ Tile Image
TLIMG_0000	= 0	@ Shift left by TILIMG_SHIFT
TLIMG_4000	= 1
TLIMG_8000	= 2
TLIMG_C000	= 3
TLIMG_SHIFT	= 2
TLIMG_ADDR_RSH	= 12	@ Alternatively, use the address right-shifted by this
@ Priority
BG_PRIO_0	= 0
BG_PRIO_1	= 1
BG_PRIO_2	= 2
BG_PRIO_3	= 3


@ OAM
OAM0_Y		= 0		@ Shift Y by this(?)
OAM0_AFF	= 8
OAM0_DISABLE	= 9		@ applies when bit OAM0_AFF = 0
OAM0_DOUBLE	= 9		@ applies when bit OAM0_AFF = 1

OAM0_M_NORMAL	= 0
OAM0_M_SEMITR	= 1
OAM0_M_WINDOW	= 2
OAM0_M_SHIFT	= 10

OAM0_MOSAIC	= 12
OAM0_PAL256	= 13

OAM0_S_SQUARE	= 0
OAM0_S_HORIZ	= 1
OAM0_S_VERT	= 2
OAM0_S_SHIFT	= 14

OAM1_AFFPARAM	= 9		@ Shift affine transform parameter by this
OAM1_HFLIP	= 12
OAM1_VFLIP	= 13
OAM1_SIZE	= 14

OAM2_PRIO	= 10
OAM2_PALETTE	= 12		@ Shift palette number by this

@ Keys

KEY_BUTTON_A	= 0
KEY_BUTTON_B	= 1
KEY_SELECT	= 2
KEY_START	= 3
KEY_RIGHT	= 4
KEY_LEFT	= 5
KEY_UP		= 6
KEY_DOWN	= 7
KEY_BUTTON_R	= 8
KEY_BUTTON_L	= 9
