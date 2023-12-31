import std/[random, os, math]
import sdl2_nim/sdl
import ./stb_vorbis
import xmp

const
  Channels = 2
  BufLen = 1024

proc fillAudio(udata: pointer; stream: ptr uint8; nbytes: cint) {.cdecl.}

type
  Sample* = ptr SampleObj
  SampleObj* = object
    len: int
    # data comes after here
  
  SourceKind* = enum
    Wav
    Ogg
    Mod
  
  Source* = ptr SourceObj
  
  SourceObj* = object
    loop*: bool
    active*: bool
    case kind: SourceKind
    of Wav:
      sample*: Sample
    of Ogg:
      vorbis*: Vorbis
    of Mod:
      ctx*: XmpContext

static:
  # ensure the sample data starts on a word boundary
  doAssert sizeof(SampleObj) == (sizeof(SampleObj) div 4) * 4

proc allocSample(nsamples: int): Sample =
  result = cast[Sample](createU(byte, sizeof(SampleObj) + nsamples * Channels * sizeof(float32)))
  result.len = nsamples

proc data*(s: Sample): ptr UncheckedArray[float32] {.inline.} =
  let bytes = cast[ptr UncheckedArray[byte]](s)
  cast[ptr UncheckedArray[float32]](addr bytes[sizeof(SampleObj)])


var sources: seq[Source]
var xmpBuf: array[BufLen * Channels, int16]

proc mixInto*(s: Source; dst: ptr UncheckedArray[float32]; nsamples: int) =
  case s.kind
  of Wav:
    discard # TODO
  of Ogg:
    discard # TODO
  of Mod:
    let res = s.ctx.playBuffer(
      buffer = addr xmpBuf,
      size = sizeof(xmpBuf),
      loop = 0  # forever
    )
    if res < 0:
      s.active = false
    for i in 0..<nsamples:
      let j = i*2
      dst[j] += xmpBuf[j] / int16.high
      dst[j+1] += xmpBuf[j+1] / int16.high

var mixerSpec = sdl.AudioSpec(
  freq: 44100,
  # format: AudioS16,
  format: AudioF32,
  channels: 2,
  samples: BufLen,
  callback: fillAudio,
  userdata: nil,
)

proc fillAudio(udata: pointer; stream: ptr uint8; nbytes: cint) {.cdecl.} =
  let buf = cast[ptr UncheckedArray[float32]](stream)
  let nsamples = (nbytes div sizeof(float32)) div mixerSpec.channels
  zeroMem(buf, nbytes)
  for s in sources:
    s.mixInto(buf, nsamples)

proc openMixer* =
  doAssert sdl.openAudio(addr mixerSpec, nil) == 0, "Failed to open audio: " & $sdl.getError()
  sdl.pauseAudio(0)

proc closeMixer* =
  discard
  # var i = 50
  # while mix.init(0) != 0:
  #   mix.quit()
  #   dec i
  #   if i <= 0: break  # bail
  
  # let mixNumOpened = mix.querySpec(nil, nil, nil)
  # for i in 0..<mixNumOpened:
  #   mix.closeAudio()
  
proc createSample*(f: string): Sample =

  var wavSpec: sdl.AudioSpec
  var len: uint32
  var buf: ptr uint8
  doAssert sdl.loadWAV(f, addr wavSpec, addr buf, addr len) != nil, "Failed to load " & $f & ": " & $sdl.getError()
  
  # convert sample to the mixer's own internal format:
  var cvt: AudioCvt
  let res = sdl.buildAudioCvt(
    cvt = addr cvt,
    src_format = wavSpec.format,
    src_channels = wavSpec.channels,
    src_rate = wavSpec.freq,
    dst_format = AudioF32,
    dst_channels = mixerSpec.channels,
    dst_rate = mixerSpec.freq,
  )
  doAssert res != -1, "Failed to set up wav converter."
  cvt.len = len.int32
  cvt.buf = createU(byte, len * cvt.len_mult.uint32)
  copyMem(cvt.buf, buf, len)
  doAssert sdl.convertAudio(addr cvt) == 0, "Failed to convert wav " & $f & ": " & $sdl.getError()
  sdl.freeWav(buf)

proc createSource(smp: Sample; loop: bool): Source =
  result = createU(SourceObj)
  result[] = SourceObj(
    kind: Wav,
    sample: smp,
    loop: loop
  )
  sources.add(result)

proc createSource*(path: string; loop: bool): Source =
  result = createU(SourceObj)
  case splitFile(path).ext
  of ".wav":
    assert(false, "TODO")
    result[] = SourceObj(kind: Wav)
  
  of ".ogg": 
    assert(false, "TODO")
    result[] = SourceObj(kind: Ogg)
  
  of ".mod", ".s3m", ".xm", ".it":
    let ctx = xmp.createContext()
    doAssert ctx.loadModule(path) == 0, "Failed to load module " & path
    result[] = SourceObj(
      kind: Mod,
      ctx: ctx,
      loop: loop
    )
  
  else:
    doAssert(false, "Unsupported file extension for " & path)
  
  sources.add(result)

proc destroySource*(s: Source) =
  # TODO
  discard

proc play*(s: Source) =
  case s.kind
  of Wav:
    discard # TODO
  of Ogg:
    discard # TODO
  of Mod:
    let res = s.ctx.startPlayer(
      rate = mixerSpec.freq,
      flags = {}  # 16 bit, signed
    )
    doAssert res == 0, $res

import ../private/sdl/appcommon

proc xatuCreateSample*(f: cstring): NatuSample =
  createSample($f).NatuSample  

proc xatuCreateSourceFromFile*(f: cstring; loop: bool): NatuSource =
  createSource($f, loop).NatuSource

proc xatuCreateSourceFromSample*(smp: NatuSample): NatuSource =
  let loop = false # TODO: determine from whether sample has loop points.
  createSource(cast[Sample](smp), loop).NatuSource

proc xatuDestroySource*(s: NatuSource) =
  discard
  # let s = s.Source
  # dealloc(s)

proc xatuPlaySource*(s: NatuSource) =
  cast[Source](s).play()

proc xatuPauseSource*(s: NatuSource) =
  discard

proc xatuStopSource*(s: NatuSource) =
  discard

# proc xatuPauseSource*() =
#   discard

# proc xatuResumeSource*() =
#   # mix.resumeMusic()
#   discard

# proc xatuStopSource*() =
#   # mix.pauseMusic()
#   # mix.rewindMusic()
#   discard

# proc xatuSetSourcePosition*(pos: cdouble) =
#   # discard mix.setSourcePosition(pos)
#   discard

# proc xatuSetSourceVolume*(vol: cfloat) =
#   # discard mix.volumeMusic((vol * 128).cint)
#   discard

# proc xatuSetEffectVolume*() =
#   discard

# proc xatuSetEffectPanning*() =
#   discard

# proc xatuSetEffectRate*() =
#   discard

# proc xatuCancelEffect*() =
#   discard

# proc xatuReleaseEffect*() =
#   discard

# proc xatuSetEffectsVolume*() =
#   discard

# proc xatuCancelAllEffects*() =
#   discard

