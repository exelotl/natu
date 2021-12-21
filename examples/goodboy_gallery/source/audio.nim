import natu/[core, maxmod]

include ../output/soundbank

const
  channels = 16
  waveMemSize = channels * (mmSizeofModCh + mmSizeofActCh + mmSizeofMixCh) + mmMixLen31kHz 

var
  waveMem {.codegenDecl:EWRAM_DATA.}: array[waveMemSize, uint8]
  mixMem {.align:4.}: array[mmMixLen31kHz, uint8]

proc init* =
  var config = MmGbaSystem(
    mixingMode: mmMix31kHz,
    modChannelCount: channels,
    mixChannelCount: channels,
    moduleChannels: addr waveMem[0],
    activeChannels: addr waveMem[channels * mmSizeofModCh],
    mixingChannels: addr waveMem[channels * (mmSizeofModCh + mmSizeofActCh)],
    mixingMemory: addr mixMem[0],
    waveMemory: addr waveMem[channels * (mmSizeofModCh + mmSizeofActCh + mmSizeofMixCh)],
    soundbank: soundbankBin,
  )
  maxmod.init(addr config)

export maxmod.vblank
export maxmod.frame

proc playSound*(sampleId: MmSampleId) {.inline.} =
  maxmod.effect(sampleId)

proc playSong*(moduleId: MmModuleId) {.inline.} =
  maxmod.start(moduleId, mmPlayLoop)

proc stopSong* {.inline.} =
  maxmod.stop()
