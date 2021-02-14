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
  MmModuleId* = distinct uint32
    ## ID of a song in the soundbank
  MmSampleId* = distinct uint32
    ## ID of a sample in the soundbank
  
  MmSfxHandle* = distinct uint16
  
  MmFnPtr* = proc () {.nimcall.}
  MmCallback* = proc (msg: uint; param: uint): uint {.nimcall.}
  
  MmPlaybackMode* {.size: 4.} = enum
    mmPlayLoop
    mmPlayOnce
  
  MmMixMode* {.size: 4.} = enum
    mmMix8Khz
    mmMix10Khz
    mmMix13Khz
    mmMix16Khz
    mmMix18Khz
    mmMix21Khz
    mmMix27Khz
    mmMix31Khz
  
  MmSoundEffect* {.importc: "mm_sound_effect", header:"mm_types.h", bycopy.} = object
    id* {.importc: "id".}: uint32              ## sample ID (defined in soundbank header)
    rate* {.importc: "rate".}: uint16          
    handle* {.importc: "handle".}: MmSfxHandle ## sound handle
    volume* {.importc: "volume".}: uint8       ## volume, 0..255
    panning* {.importc: "panning".}: uint8     ## panning, 0..255
  
  MmGbaSystem* {.importc: "mm_gba_system", header:"mm_types.h", bycopy.} = object
    mixingMode* {.importc: "mixing_mode".}: MmMixMode
    modChannelCount* {.importc: "mod_channel_count".}: uint32
    mixChannelCount* {.importc: "mix_channel_count".}: uint32
    moduleChannels* {.importc: "module_channels".}: pointer
    activeChannels* {.importc: "active_channels".}: pointer
    mixingChannels* {.importc: "mixing_channels".}: pointer
    mixingMemory* {.importc: "mixing_memory".}: pointer
    waveMemory* {.importc: "wave_memory".}: pointer
    soundbank* {.importc: "soundbank".}: pointer
  
  MmModLayer* {.importc: "mm_modlayer", header:"mm_types.h", bycopy.} = object
    tick* {.importc: "tick".}: uint8                   ## current tick count
    row* {.importc: "row".}: uint8                     ## current row being played
    position* {.importc: "position".}: uint8           ## module sequence position
    nrows* {.importc: "nrows".}: uint8                 ## number of rows in current pattern
    globalVolume* {.importc: "global_volume".}: uint8  ## global volume multiplier
    speed* {.importc: "speed".}: uint8                 ## speed of module (ticks/row)
    active* {.importc: "active".}: uint8               ## module is active
    bpm* {.importc: "bpm".}: uint8                     ## tempo of module
  
  MmVoice* {.importc: "mm_voice", header:"mm_types.h", bycopy.} = object
    
    # data source information
    source* {.importc: "source".}: pointer        ## address to sample data
    length* {.importc: "length".}: uint32         ## length of sample data OR loop length (expressed in WORDS)
    loopStart* {.importc: "loop_start".}: uint16  ## loop start position (expressed in WORDS)
    
    timer* {.importc: "timer".}: uint16       ## frequency divider
    flags* {.importc: "flags".}: MmVoiceFlags ## update flags
    format* {.importc: "format".}: uint8      ## source format (0: 8-bit, 1: 16-bit, 2: adpcm)
    repeat* {.importc: "repeat".}: uint8      ## repeat mode (0: manual, 1: forward loop, 2: one shot)
    
    volume* {.importc: "volume".}: uint8   ## volume setting (0->127)
    divider* {.importc: "divider".}: uint8 ## divider setting (0->3 = /1, /2, /4, /16)
    
    panning* {.importc: "panning".}: uint8 ## panning setting (0->127)
    index* {.importc: "index".}: uint8     ## index of voice (0->15)
  
  MmVoiceFlag* = enum
    mmvfUnused = 0  # (todo: figure out if this bit is used for something)
    mmvfFreq = 1    ## update frequency when this flag is set
    mmvfVolume = 2  ## update volume
    mmvfPanning = 3 ## update panning
    mmvfSource = 4  ## update source and start note
    mmvfStop = 5    ## stop voice (cut sound)
  
  MmVoiceFlags* {.size: 1.} = set[MmVoiceFlag]


# Precalculated mix buffer lengths (in bytes)
const
  mmMixLen8Khz* = 544    # (8121 hz)
  mmMixLen10Khz* = 704   # (10512 hz)
  mmMixLen13Khz* = 896   # (13379 hz)
  mmMixLen16Khz* = 1056  # (15768 hz)
  mmMixLen18Khz* = 1216  # (18157 hz)
  mmMixLen21Khz* = 1408  # (21024 hz)
  mmMixLen27Khz* = 1792  # (26758 hz)
  mmMixLen31Khz* = 2112  # (31536 hz)

# Measurements of channel types (bytes)
const
  mmSizeofModCh* = 40
  mmSizeofActCh* = 28
  mmSizeofMixCh* = 24

proc `==`*(a, b: MmModuleId): bool {.borrow.}
proc `==`*(a, b: MmSampleId): bool {.borrow.}
proc `==`*(a, b: MmSfxHandle): bool {.borrow.}

proc init*(soundbank: pointer; channels: uint) {.importc:"mmInitDefault", header:"maxmod.h".}
  ## Initialize Maxmod with default settings.
  ## `soundbank` : Memory address of soundbank (in ROM).
  ##               A soundbank file can be created with the Maxmod Utility.
  ## `channels` : Number of module/mixing channels to allocate.
  ##              Must be greater or equal to the channel count in your modules.
  ## For GBA, this function uses these default settings (and allocates memory):
  ##  16KHz mixing rate, channel buffers in EWRAM, wave buffer in EWRAM, and
  ##  mixing buffer in IWRAM.

proc init*(setup: ptr MmGbaSystem) {.importc:"mmInit", header:"maxmod.h".}
  ## Initialize system. Call once at startup.

proc vblank*() {.importc:"mmVBlank", header:"maxmod.h".}
  ## Must be linked to the VBlank IRQ.
  ## This function must be linked directly to the VBlank IRQ.
  ## During this function, the sound DMA is reset. The timing is extremely critical, so
  ##  make sure that it is not interrupted, otherwise garbage may be heard in the output.
  ## If you need another function to execute after this process is finished, use
  ##  `setVBlankHandler` to install a your handler. 

proc setVBlankHandler*(function: MmFnPtr) {.importc:"mmSetVBlankHandler", header:"maxmod.h".}
  ## Install user vblank handler
  ## `function` : Pointer to your VBlank handler.

proc setEventHandler*(handler: MmCallback) {.importc:"mmSetEventHandler", header:"maxmod.h".}
  ## Install handler to receive song events.
  ## Use this function to receive song events. Song events occur in two situations.
  ## One is by special pattern data in a module (which is triggered by SFx/EFx commands).
  ## The other occurs when a module finishes playback (in MM_PLAY_ONCE mode).
  ## Note for GBA projects: During the song event, Maxmod is in the middle of module processing. Avoid using any Maxmod related functions during your song event handler since they may cause problems in this situation. 

proc frame*() {.importc:"mmFrame", header:"maxmod.h".}
  ## Work routine. _Must_ be called every frame.


# Module Playback
# ---------------

proc start*(id: MmModuleId; mode: MmPlaybackMode) {.importc:"mmStart", header:"maxmod.h".}
  ## Start module playback.
  ## `id` : ID of module to play.
  ## `mode` : Playback mode (loop/once)

proc pause*() {.importc:"mmPause", header:"maxmod.h".}
  ## Pause module playback, resume with `maxmod.resume()`

proc resume*() {.importc:"mmResume", header:"maxmod.h".}
  ## Resume module playback, pause with `maxmod.pause()`

proc stop*() {.importc:"mmStop", header:"maxmod.h".}
  ## Stop module playback. start again with mmStart().

proc setPosition*(position: uint) {.importc:"mmSetPosition", header:"maxmod.h".}
  ## Set playback position.
  ## `position` : New position in the module sequence.

proc getPosition*(): uint {.importc:"mmGetPosition", header:"maxmod.h".}
  ## Get playback position.

proc active*(): bool {.importc:"mmActive", header:"maxmod.h".}
  ## Returns true if module is playing.

proc jingle*(id: MmModuleId) {.importc:"mmJingle", header:"maxmod.h".}
  ##  Play module as jingle. Jingles are limited to 4 channels only.
  ##  `moduleID` : ID of module (defined in soundbank header)

proc activeSub*(): bool {.importc:"mmActiveSub", header:"maxmod.h".}
  ## Returns true if a jingle is actively playing.

proc setModuleVolume*(volume: uint) {.importc:"mmSetModuleVolume", header:"maxmod.h".}
  ## Set volume scaler for music.
  ## `volume` : 0->1024 = silent..normal

proc setJingleVolume*(volume: uint) {.importc:"mmSetJingleVolume", header:"maxmod.h".}
  ## Set volume scaler for jingles.
  ## `volume` : 0->1024 = silent..normal

proc setModuleTempo*(tempo: uint) {.importc:"mmSetModuleTempo", header:"maxmod.h".}
  ## Set tempo of playback.
  ## `tempo` : Fixed point (Q10) value representing tempo.
  ##           Range = 0x200 -> 0x800 = 0.5 -> 2.0

proc setModulePitch*(pitch: uint) {.importc:"mmSetModulePitch", header:"maxmod.h".}
  ## Set pitch of playback.
  ## `pitch` : Range = 0x200 -> 0x800 = 0.5 -> 2.0

# TODO: check types of mode and layer.

proc playModule*(address: pointer; mode: uint; layer: uint) {.importc:"mmPlayModule", header:"maxmod.h".}
  ## Play direct MAS file


# Sound Effects
# -------------

proc effect*(id: MmSampleId): MmSfxHandle {.importc:"mmEffect", header:"maxmod.h", discardable.}
  ## Play a sound effect at its default frequency with full volume and centered panning.
  ## `sampleID` : Sound effect ID. (defined in soundbank header)

proc effectEx*(sound: ptr MmSoundEffect): MmSfxHandle {.importc:"mmEffectEx", header:"maxmod.h", discardable.}
  ## Play a sound effect with all parameters.
  ## `sound` : Sound effect attributes.

proc setVolume*(handle: MmSfxHandle; volume: uint) {.importc:"mmEffectVolume", header:"maxmod.h".}
  ## Set the volume of a sound effect.
  ## `handle` : Sound effect handle.
  ## `volume` : 0->65535

proc setPanning*(handle: MmSfxHandle; panning: uint8) {.importc:"mmEffectPanning", header:"maxmod.h".}
  ## Set the panning of a sound effect.
  ## `handle` : Sound effect handle.
  ## `panning` : 0->255 = left..right

# TODO: use fixed point param for these two procs:

proc setRate*(handle: MmSfxHandle; rate: uint) {.importc:"mmEffectRate", header:"maxmod.h".}
  ## Set the playback rate of an effect.
  ## `handle` : Sound effect handle.
  ## `rate : 6.10 factor

proc scaleRate*(handle: MmSfxHandle; factor: uint) {.importc:"mmEffectScaleRate", header:"maxmod.h".}
  ## Scale the playback rate of an effect.
  ## `handle` : Sound effect handle.
  ## `factor` : 6.10 fixed point factor.

proc cancel*(handle: MmSfxHandle) {.importc:"mmEffectCancel", header:"maxmod.h".}
  ## Stop sound effect.
  ## `handle` : Sound effect handle.

proc release*(handle: MmSfxHandle) {.importc:"mmEffectRelease", header:"maxmod.h".}
  ## Release sound effect (invalidate handle and allow interruption)
  ## `handle` : Sound effect handle.

proc isActive*(handle: MmSfxHandle) {.importc:"mmEffectActive", header:"maxmod.h".}
  ## Indicates if a sound effect is active or not.
  ## `handle` : Sound effect handle.

proc setEffectsVolume*(volume: uint) {.importc:"mmSetEffectsVolume", header:"maxmod.h".}
  ## Set master volume scale for effect playback.
  ## `volume` : 0->1024 representing 0%->100% volume

proc cancelAllEffects*() {.importc:"mmEffectCancelAll", header:"maxmod.h".}
  ## Stop all sound effects


# Playback events
# ---------------

const mmcbSongMessage* = 0x0000002A
  ## This happens when Maxmod reads a SFx (or mod/xm EFx) effect from a module
  ## It will store 'x' in param_b

const mmcbSongFinished* = 0x0000002B
  ## A module has finished playing
  ## param == 0 if main module, 1 otherwise


# Nim Extras
# ----------
# Deprecated, please use `createMaxmodSoundbank` in your project's `config.nims` instead.
# Or use the `trick` library.

import macros, strutils

proc toCamelCase(name:string): string =
  var upper = false
  for c in name:
    if c == '_': upper = true
    elif upper:
      result.add(c.toUpperAscii())
      upper = false
    else:
      result.add(c.toLowerAscii())

proc getSoundName*(name: string, camelCase = false): string {.deprecated.} =
  ## Convert a sound filepath to a variable name
  ##
  ## By default, the mmutil naming convention is used.
  ## e.g. "songs/foo.xm" -> "MOD_FOO"
  ## 
  ## Pass `camelCase=true` for a more friendly name.
  ## e.g. "songs/foo.xm" -> "modFoo"
  ##
  ## Note: this procedure is meant for your macros and project tools,
  ##       not for use at runtime on the GBA.
  
  var prefix = ""
  if name.endsWith(".mod") or
  name.endsWith(".xm") or
  name.endsWith(".s3m") or
  name.endsWith(".it"):
    prefix = "MOD_"
  elif name.endsWith(".wav"):
    prefix = "SFX_"
  else:
    return ""
  
  var name = name.split("/")[^1]   # remove directory
  name = name.split(".")[0]        # remove full extension
  name = prefix & name.toUpperAscii()
  
  # replace non-alphanumeric chars with '_'
  for i in 0..<name.len:
    if name[i] notin 'A'..'Z' and name[i] notin '0'..'9':
      name[i] = '_'
  
  return (if camelCase: name.toCamelCase() else: name)


macro importSoundbank*(dir: static[string] = "audio", camelCase: static[bool] = true) {.deprecated.} =
  ## Generate declarations for the soundbank and music/effect IDs.
  ## Loops over the given directory and attempts to mimic the naming convention of mmutil
  
  result = newStmtList()
  
  # list all files in the project's audio directory
  var names = staticExec "ls -1 " & getProjectPath() & "/" & dir & "/*.*"
  
  for name in splitLines(names):
    if name == "" or name.startsWith("ls: cannot access"):
      continue
    
    {.push warning[Deprecated]: off.}
    var name = getSoundName(name)
    if name == "":
      continue
    {.pop.}
    
    let soundIdent = ident(if camelCase: (name.toCamelCase()) else: (name))
    let soundStrLit = newStrLitNode(name)
    result.add quote do:
      var `soundIdent`* {.importc:`soundStrLit`, header:"soundbank.h"}: uint
  
  # define reference to soundbank data
  let soundbankBinIdent = ident(if camelCase: "soundbankBin" else: "soundbank_bin")
  let soundbankBinStrLit = newStrLitNode("soundbank_bin")
  result.add quote do:
    var `soundbankBinIdent`* {.importc:`soundbankBinStrLit`, header:"soundbank_bin.h".}: pointer


# Old names, deprecated.

proc position*(position: uint) {.deprecated, importc:"mmPosition", header:"maxmod.h".}
proc effectRelease*(handle: MmSfxHandle) {.deprecated, importc:"mmEffectRelease", header:"maxmod.h".}
proc effectCancel*(handle: MmSfxHandle) {.deprecated, importc:"mmEffectCancel", header:"maxmod.h".}
proc effectRate*(handle: MmSfxHandle; rate: uint) {.importc:"mmEffectRate", header:"maxmod.h".}
proc effectScaleRate*(handle: MmSfxHandle; factor: uint) {.deprecated, importc:"mmEffectScaleRate", header:"maxmod.h".}
proc effectPanning*(handle: MmSfxHandle; panning: uint8) {.deprecated, importc:"mmEffectPanning", header:"maxmod.h".}
proc effectVolume*(handle: MmSfxHandle; volume: uint) {.deprecated, importc:"mmEffectVolume", header:"maxmod.h".}
proc effectCancelAll*() {.deprecated, importc:"mmEffectCancelAll", header:"maxmod.h".}
