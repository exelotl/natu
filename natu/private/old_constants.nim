# Stuff that was removed from the API but may be nice in a legacy module?

# Video
# -----

# Alpha blend layers (use with REG_BLDMOD)
const
  LAYER_BG0* = 0x0001
  LAYER_BG1* = 0x0002
  LAYER_BG2* = 0x0004
  LAYER_BG3* = 0x0008
  LAYER_OBJ* = 0x0010
  LAYER_BD* = 0x0020

# Color components
const
  CLR_MASK*:uint32 = 0x001F
  RED_MASK*:uint32 = 0x001F
  RED_SHIFT*:uint32 = 0
  GREEN_MASK*:uint32 = 0x03E0
  GREEN_SHIFT*:uint32 = 5
  BLUE_MASK*:uint32 = 0x7C00
  BLUE_SHIFT*:uint32 = 10
