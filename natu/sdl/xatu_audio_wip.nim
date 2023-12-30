import std/[random, os, math]
import sdl2_nim/sdl
import ./stb_vorbis
import ./modplug   # apparently xmp-lite is MIT so we could use that in future?

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
      module*: ModPlugFile

static:
  # ensure the sample data starts on a word boundary
  doAssert sizeof(SampleObj) == (sizeof(SampleObj) div 4) * 4

const
  Channels = 2
  BufSize = 1024
  BufMul = (44100/48000)
  MpBufSize = ceil(1024 * BufMul).int

proc allocSample(nsamples: int): Sample =
  result = allocU(sizeof(SampleObj) + nsamples * Channels * sizeof(float32))
  result.len = nsamples

proc data*(s: Sample): ptr UncheckedArray[float32] {.inline.} =
  let bytes = cast[ptr UncheckedArray[byte]](s)
  cast[ptr UncheckedArray[float32]](addr bytes[sizeof(SampleObj)])

proc mixInto*(s: Source; dst: ptr UncheckedArray[float32]; nsamples: int) =
  case s.kind
  of Wav:
    discard # TODO
  of Ogg:
    discard # TODO
  of Mod:
    var arr: array[MpBufSize * Channels, int32]
    let bytesRead = s.module.read(addr arr, sizeof(arr))
    var n = 0.0
    for i in 0..<nsamples:
      dst[i*2] += arr[(n.int)*2] / int32.high
      dst[i*2 + 1] += arr[(n.int)*2 + 1] / int32.high
      n += BufMul
    if bytesRead < sizeof(arr):
      s.active = false

var sources: seq[SourceObj]

var mixerSpec = sdl.AudioSpec(
  freq: 48000,
  # format: AudioS16,
  format: AudioF32,
  channels: 2,
  samples: 1024,
  callback: fillAudio,
  userdata: nil,
)

proc fillAudio(udata: pointer; stream: ptr uint8; nbytes: cint) {.cdecl.} =
  let buf = cast[ptr UncheckedArray[float32]](stream)
  let nsamples = (nbytes div sizeof(float32)) div mixerSpec.channels
  clearMem(buf, nbytes)
  for s in sources:
    (addr s).mixInto(buf, nsamples)

proc openMixer* =
  doAssert sdl.openAudio(addr mixerSpec, nil) == 0, "Failed to open audio: " & $sdl.getError()
  
  var mpSettings: ModPlugSettings
  modplug.getSettings(addr mpSettings)
  echo mpSettings
  
  # var mpSettings = ModPlugSettings(
  #   flags: {Oversampling},
  #   channels: 2,
  #   bits: 32,
  #   frequency: 44100,
  #   resamplingMode: ResampleNearest,
  #   stereoSeparation: 128,
  #   maxMixChannels: 32,
  #   reverbDepth: 50,
  #   reverbDelay: 50,
  #   bassAmount: 50,
  #   bassRange: 50,
  #   surroundDepth: 60,
  #   surroundDelay: 10,
  #   loopCount: -1,
  # )
  # modplug.setSettings(mpSettings)
  
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
  
proc createSample*(f: cstring): Sample =

  var wavSpec: sdl.AudioSpec
  var len: uint32
  var buf: ptr uint8
  doAssert sdl.loadWAV(f, addr wavSpec, addr buf, addr len) != nil, "Failed to load " & $f & ": " & $sdl.getError()
  
  # convert sample to the mixer's own internal format:
  var cvt: AudioCvt
  sdl.buildAudioCvt(
    cvt: addr cvt,
    src_format: wavSpec.format,
    src_channels: wavSpec.channels,
    src_rate: wavSpec.freq,
    dst_format: AudioF32,
    dst_channels: mixerSpec.channels,
    dst_rate: mixerSpec.rate,
  )
  cvt.len = len
  cvt.buf = allocU(len * cvt.len_mult)
  copyMem(cvt.buf, buf, len)
  sdl.convertAudio(cvt)
  sdl.freeWav(buf)

proc createSource(smp: Sample): Source =
  result = createU(SourceObj)
  result[] = SourceObj(
    kind: Wav,
    sample: smp,
  )

proc createSource*(f: cstring): Source =
  result = createU(SourceObj)
  let path = $f
  case splitFile(path).ext
  of ".wav":
    result[] = SourceObj(kind: Wav)
  of ".ogg": 
    result[] = SourceObj(kind: Ogg)
  of ".mod", ".s3m", ".xm", ".it":
    var data = readFile(path)
    result[] = SourceObj(kind: Mod, module: modplug.load(addr data[0], data.len))
    doAssert(res.module != nil, "Failed to load module " & path)
  else:
    doAssert(false, "Unsupported file extension for " & path)

proc destroySource*(s: Source) =
  # TODO
  discard


import ../private/sdl/appcommon

proc xatuCreateSample*(f: cstring): NatuSample =
  createSample(f).NatuSample  

proc xatuCreateSourceFromFile*(f: cstring): NatuSource =
  createSource(f).NatuSample  

proc xatuCreateSourceFromSample*(f: cstring): NatuSource =
  createSource(f).NatuSample 

proc xatuDestroySource*(s: NatuSource) =
  let s = s.Source
  dealloc(s)

proc xatuPlaySource*(s: NatuSource) =
  let s = s.Source

proc xatuPauseSource*(s: NatuSource) =
  let s = s.Source

proc xatuStopSource*(s: NatuSource) =
  let s = s.Source

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

