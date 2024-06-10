#[
############################################################################
#                                                          __              #
#                ____ ___  ____ __  ______ ___  ____  ____/ /              #
#               / __ `__ \/ __ `/ |/ / __ `__ \/ __ \/ __  /               #
#              / / / / / / /_/ />  </ / / / / / /_/ / /_/ /                #
#             /_/ /_/ /_/\__,_/_/|_/_/ /_/ /_/\____/\__,_/                 #
#                                                                          #
#                             GBA Definitions                              #
#                                                                          #
#         Copyright (c) 2008, Mukunda Johnson (mukunda@maxmod.org)         #
#                                                                          #
# Permission to use, copy, modify, and/or distribute this software for any #
# purpose with or without fee is hereby granted, provided that the above   #
# copyright notice and this permission notice appear in all copies.        #
#                                                                          #
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES #
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF         #
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR  #
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES   #
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN    #
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF  #
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.           #
############################################################################
]#

from ./math import FixedN
import natu/private/common

when natuPlatform != "gba":
  {.error: "Maxmod is only supported on the gba platform.".}


const thisDir = currentSourcePath()[0..^11]
const mmPath = thisDir & "../vendor/maxmod"
const mmAsmFlags = "-g -x assembler-with-cpp -DSYS_GBA -DUSE_IWRAM -I" & mmPath & "/asm_include"

{.compile(mmPath & "/source/mm_effect.s", mmAsmFlags).}
{.compile(mmPath & "/source/mm_main.s", mmAsmFlags).}
{.compile(mmPath & "/source/mm_mas.s", mmAsmFlags).}
{.compile(mmPath & "/source/mm_mas_arm.s", mmAsmFlags).}
{.compile(mmPath & "/source_gba/mm_init_default.s", mmAsmFlags).}
{.compile(mmPath & "/source_gba/mm_mixer_gba.s", mmAsmFlags).}

# Types
# -----

type
  MmSoundbankPtr* = distinct cstring
    ## Pointer to soundbank data


# Soundbank is auto-included from the user's project:

doInclude natuOutputDir & "/soundbank.nim"


type
  MmSfxHandle* = distinct uint16
  
  MmFnPtr* = proc () {.nimcall.}
  MmCallback* = proc (msg: uint; param: uint): uint {.nimcall.}
  
  MmPlaybackMode* {.size: 4.} = enum
    mmPlayLoop
    mmPlayOnce
  
  MmMixMode* {.size: 4.} = enum
    mmMix8kHz   ## 8121 Hz
    mmMix10kHz  ## 10512 Hz
    mmMix13kHz  ## 13379 Hz
    mmMix16kHz  ## 15768 Hz
    mmMix18kHz  ## 18157 Hz
    mmMix21kHz  ## 21024 Hz
    mmMix27kHz  ## 26758 Hz
    mmMix31kHz  ## 31536 Hz
  
  MmSoundEffect* {.bycopy.} = object
    id*: uint32          ## sample ID (defined in soundbank header)
    rate*: uint16          
    handle*: MmSfxHandle ## sound handle
    volume*: uint8       ## volume, 0..255
    panning*: uint8      ## panning, 0..255
  
  MmGbaSystem* {.bycopy.} = object
    mixingMode*: MmMixMode
    modChannelCount*: uint32
    mixChannelCount*: uint32
    moduleChannels*: pointer
    activeChannels*: pointer
    mixingChannels*: pointer
    mixingMemory*: pointer
    waveMemory*: pointer
    soundbank*: MmSoundbankPtr
  
  MmModLayer* {.bycopy.} = object
    tick*: uint8         ## current tick count
    row*: uint8          ## current row being played
    position*: uint8     ## module sequence position
    nrows*: uint8        ## number of rows in current pattern
    globalVolume*: uint8 ## global volume multiplier
    speed*: uint8        ## speed of module (ticks/row)
    active*: uint8       ## module is active
    bpm*: uint8          ## tempo of module
  
  MmVoice* {.bycopy.} = object
    
    # data source information
    source*: pointer     ## address to sample data
    length*: uint32      ## length of sample data OR loop length (expressed in WORDS)
    loopStart*: uint16   ## loop start position (expressed in WORDS)
    
    timer*: uint16       ## frequency divider
    flags*: MmVoiceFlags ## update flags
    format*: uint8       ## source format (0: 8-bit, 1: 16-bit, 2: adpcm)
    repeat*: uint8       ## repeat mode (0: manual, 1: forward loop, 2: one shot)
    
    volume*: uint8       ## volume setting (0->127)
    divider*: uint8      ## divider setting (0->3 = /1, /2, /4, /16)
    
    panning*: uint8      ## panning setting (0->127)
    index*: uint8        ## index of voice (0->15)
  
  MmVoiceFlag* = enum
    mmvfUnused = 0  ## (unused?)
    mmvfFreq = 1    ## update frequency when this flag is set
    mmvfVolume = 2  ## update volume
    mmvfPanning = 3 ## update panning
    mmvfSource = 4  ## update source and start note
    mmvfStop = 5    ## stop voice (cut sound)
  
  MmVoiceFlags* {.size: 1.} = set[MmVoiceFlag]


# Precalculated mix buffer lengths (in bytes)
const
  mmMixLen8kHz* = 544    # (8121 hz)
  mmMixLen10kHz* = 704   # (10512 hz)
  mmMixLen13kHz* = 896   # (13379 hz)
  mmMixLen16kHz* = 1056  # (15768 hz)
  mmMixLen18kHz* = 1216  # (18157 hz)
  mmMixLen21kHz* = 1408  # (21024 hz)
  mmMixLen27kHz* = 1792  # (26758 hz)
  mmMixLen31kHz* = 2112  # (31536 hz)

# Measurements of channel types (bytes)
const
  mmSizeofModCh* = 40
  mmSizeofActCh* = 28
  mmSizeofMixCh* = 24

proc `==`*(a, b: MmSfxHandle): bool {.borrow.}

proc init*(soundbank: MmSoundbankPtr; channels: uint) {.importc:"mmInitDefault".}
  ## Initialize Maxmod with default settings.
  ## 
  ## :soundbank:
  ##   Memory address of soundbank (in ROM).
  ##   A soundbank file can be created with the Maxmod Utility (or generated by Natu when you run `nim build`)
  ## 
  ## :channels:
  ##   Number of module/mixing channels to allocate.
  ##   Must be greater or equal to the channel count in your modules.
  ## 
  ##   For GBA, this function uses these default settings (and allocates memory):
  ##   16kHz mixing rate, channel buffers in EWRAM, wave buffer in EWRAM, and
  ##   mixing buffer in IWRAM.

proc init*(setup: ptr MmGbaSystem) {.importc:"mmInit".}
  ## Initialize system. Call once at startup.

proc vblank*() {.importc:"mmVBlank".}
  ## This procedure must be linked directly to the VBlank IRQ, or be the very first
  ## thing that runs in your custom VBlank handler.
  ## 
  ## During this procedure, the sound DMA is reset. The timing is extremely critical, so
  ## make sure that it is not interrupted, otherwise garbage may be heard in the output.

proc setVBlankHandler*(function: MmFnPtr) {.importc:"mmSetVBlankHandler", deprecated:"Just make sure `maxmod.vblank` is the first thing that gets called.".}
  ## Install user vblank handler.
  ## 
  ## :function:
  ##   Pointer to your VBlank handler.

proc setEventHandler*(handler: MmCallback) {.importc:"mmSetEventHandler".}
  ## Install handler to receive song events.
  ## 
  ## Use this function to receive song events. Song events occur in two situations:
  ## One is by special pattern data in a module (which is triggered by ``SFx``/``EFx`` commands).
  ## The other occurs when a module finishes playback (in `mmPlayOnce` mode).
  ## 
  ## During the song event, Maxmod is in the middle of module processing. Avoid
  ## using any Maxmod related functions during your song event handler since they
  ## may cause problems in this situation. 

proc frame*() {.importc:"mmFrame".}
  ## This is the main work routine that processes music and updates the sound output.
  ## 
  ## This function must be called every frame. If a call is missed, garbage will be
  ## heard in the output and module processing will be delayed.


# Module Playback
# ---------------

proc start*(id: Module; mode: MmPlaybackMode = mmPlayLoop) {.importc:"mmStart".}
  ## Start module playback.
  ## 
  ## :id:   ID of module to play.
  ## :mode: Playback mode (`mmPlayLoop` or `mmPlayOnce`)

proc pause*() {.importc:"mmPause".}
  ## Pause module playback, resume with `maxmod.resume()`

proc resume*() {.importc:"mmResume".}
  ## Resume module playback, pause with `maxmod.pause()`

proc stop*() {.importc:"mmStop".}
  ## Stop module playback. start again with `maxmod.start()`.

proc setPosition*(position: uint) {.importc:"mmPosition".}
  ## Jumps to the pattern at the given index in the song's pattern order table,
  ## and starts playing that pattern from the beginning.
  ## 
  ## :position:  New position in the song.

proc getPosition*(): uint {.importc:"mmGetPosition".}
  ## Get playback position (i.e. the index of the current pattern).

proc active*(): bool {.importc:"mmActive".}
  ## Returns true if module is playing.

proc jingle*(id: Module) {.importc:"mmJingle".}
  ## Play module as jingle. Jingles are limited to 4 channels only.
  ## 
  ## :id:  ID of module (defined in ``output/soundbank.nim`` which is generated for your project)

proc activeSub*(): bool {.importc:"mmActiveSub".}
  ## Returns true if a jingle is actively playing.

proc setModuleVolume*(volume: FixedN[10]) {.importc:"mmSetModuleVolume".}
  ## Set volume scaler for music.
  ## 
  ## :volume:
  ##   Multipler for the overall volume of the song, ranging from `0.0 .. 1.0` (silent .. normal).

proc setJingleVolume*(volume: FixedN[10]) {.importc:"mmSetJingleVolume".}
  ## Set volume scaler for jingles.
  ## 
  ## :volume:
  ##   Multipler for the overall volume of the jingle, ranging from `0.0 .. 1.0` (silent .. normal).

proc setModuleTempo*(tempo: FixedN[10]) {.importc:"mmSetModuleTempo".}
  ## Set tempo of playback.
  ## 
  ## :tempo:
  ##   Multiplier for the overall tempo of the song, ranging from `0.5 .. 2.0`

proc setModulePitch*(pitch: FixedN[10]) {.importc:"mmSetModulePitch".}
  ## Set pitch of playback.
  ## 
  ## :pitch:
  ##   Multiplier for the overall pitch of the song, ranging from `0.5 .. 2.0`.

# TODO: check types of mode and layer.

proc playModule*(address: pointer; mode: uint; layer: uint) {.importc:"mmPlayModule".}
  ## Play direct MAS file


# Sound Effects
# -------------

proc effect*(id: Sample): MmSfxHandle {.importc:"mmEffect", discardable.}
  ## Play a sound effect at its default frequency with full volume and centered panning.
  ## 
  ## **Parameters:**
  ## 
  ## :id:
  ##   Sound effect ID. (defined in ``output/soundbank.nim`` which is generated for your project)

# TODO: link to page about asset conversion ^

proc effectEx*(sound: ptr MmSoundEffect): MmSfxHandle {.importc:"mmEffectEx", discardable.}
  ## Play a sound effect with all parameters.
  ## 
  ## **Parameters:**
  ## 
  ## :sound:
  ##   Sound effect attributes.

proc setVolume*(handle: MmSfxHandle; volume: FixedN[8]) {.importc:"mmEffectVolume".}
  ## Set the volume of a sound effect.
  ## 
  ## **Parameters:**
  ## 
  ## :handle:
  ##   Sound effect handle.
  ## 
  ## :volume:
  ##   Effect volume ranging from `0.0 ..< 1.0` (underlying value from `0 .. 255`)

proc setPanning*(handle: MmSfxHandle; panning: FixedN[8]) {.importc:"mmEffectPanning".}
  ## Set the panning of a sound effect.
  ## 
  ## **Parameters:**
  ## 
  ## :handle:
  ##   Sound effect handle.
  ## 
  ## :panning:
  ##   `0.0 ..< 1.0` = `left .. right`

proc setRate*(handle: MmSfxHandle; rate: FixedN[10]) {.importc:"mmEffectRate".}
  ## Set the playback rate of an effect.
  ## 
  ## **Parameters:**
  ## 
  ## :handle:
  ##   Sound effect handle.
  ## 
  ## :rate:
  ##   Absolute playback rate, ranging from `0.0 ..< 64.0`.

proc scaleRate*(handle: MmSfxHandle; factor: FixedN[10]) {.importc:"mmEffectScaleRate".}
  ## Scale the playback rate of an effect.
  ## 
  ## **Parameters:**
  ## 
  ## :handle:
  ##   Sound effect handle.
  ## 
  ## :factor:
  ##   Amount by which to multiply the playback rate, ranging from `0.0 ..< 64.0`.

proc cancel*(handle: MmSfxHandle) {.importc:"mmEffectCancel".}
  ## Stop sound effect.
  ## 
  ## **Parameters:**
  ## 
  ## :handle:
  ##   Sound effect handle.

proc release*(handle: MmSfxHandle) {.importc:"mmEffectRelease".}
  ## Release sound effect (invalidate handle and allow interruption)
  ## 
  ## **Parameters:**
  ## 
  ## :handle:
  ##   Sound effect handle.

proc active*(handle: MmSfxHandle): bool {.importc:"mmEffectActive".}
  ## Indicates if a sound effect is active or not.
  ## 
  ## **Parameters:**
  ## 
  ## :handle:
  ##   Sound effect handle.

proc setEffectsVolume*(volume: FixedN[8]) {.importc:"mmSetEffectsVolume".}
  ## Set master volume scale for effect playback.
  ## 
  ## **Parameters:**
  ## 
  ## :volume:
  ##   `0.0 ..< 1.0` representing 0% to 100% volume.

proc cancelAllEffects*() {.importc:"mmEffectCancelAll".}
  ## Stop all sound effects


# Playback events
# ---------------

const mmcbSongMessage* = 0x0000002A'u32
  ## This happens when Maxmod reads a `SFx` (or mod/xm `EFx`) effect from a module.
  ## 
  ## `param` will contain the number specified in the effect (e.g. `3` for `EF3`).

const mmcbSongFinished* = 0x0000002B'u32
  ## This happens when a module has finished playing, which can happen if you passed
  ## `mmPlayOnce` to `maxmod.start`, or when playing a jingle.
  ## 
  ## `param` will be `0` if the main module has ended, or `1` if the sub module (jingle)
  ## has ended.
