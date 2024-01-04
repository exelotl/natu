import std/[random, os, math, locks]
import ../private/sdl/appcommon
import sdl2_nim/sdl
import ./stb_vorbis
import xmp
import ./xatu_input

const
  Channels = 2
  BufLen = 1024

type
  SourceKind* = enum
    Wav
    Ogg
    Mod
  
  Source* = ptr SourceObj
  
  SourceObj* = object
    # loop*: LoopKind  # TODO
    loop*: bool
    playing*: bool = true
    rateMul*: float32 = 1.0f
    case kind: SourceKind
    of Wav:
      sample*: ptr SampleInfo
      samplePos*: float32
    of Ogg:
      vorbis*: Vorbis
    of Mod:
      ctx*: XmpContext

  MixerState = object
    spec: sdl.AudioSpec
    lock: Lock
    sources {.guard: lock.}: seq[Source]
    xmpBuf: array[BufLen * Channels, int16]
    sampleData: ptr UncheckedArray[float32]

var mixer: MixerState

proc len*(smp: ptr SampleInfo): int =
  (smp.dataEnd - smp.dataStart).int div smp.channels.int

proc mixInto*(s: Source; dst: ptr UncheckedArray[float32]; nsamples: int; m: ptr MixerState) =
  case s.kind
  of Wav:
    # echo (cast[uint](m.sampleData), s.sample.dataStart)
    var data = cast[ptr UncheckedArray[float32]](addr m.sampleData[s.sample.dataStart])
    var pos = s.samplePos
    var count = nsamples
    let remaining = s.sample.len - pos.int
    if remaining < nsamples:
      count = remaining
      s.playing = false
    
    let rate = s.rateMul * (s.sample.sampleRate.float32 / m.spec.freq.float32)
    case s.sample.channels
    of 1:
      for i in 0..<count:
        let j = i*2
        let v = data[pos.int]
        dst[j] += v
        dst[j+1] += v
        pos += rate
    of 2:
      for i in 0..<count:
        let j = i*2
        let k = (pos.int) * 2
        dst[j] += data[k]
        dst[j+1] += data[k+1]
        pos += rate
    else:
      echo "Bad channel count ", s.sample.channels
    s.samplePos = pos
  of Ogg:
    discard # TODO
  of Mod:
    let buf = addr m.xmpBuf
    let res = s.ctx.playBuffer(
      buffer = buf,
      size = sizeof(buf[]),
      loop = 0  # forever
    )
    if res < 0:
      s.playing = false
    for i in 0..<nsamples:
      let j = i*2
      dst[j] += buf[j] / int16.high
      dst[j+1] += buf[j+1] / int16.high


proc fillAudio(udata: pointer; stream: ptr uint8; nbytes: cint) {.cdecl, gcsafe.} =
  let m = cast[ptr MixerState](udata)
  let buf = cast[ptr UncheckedArray[float32]](stream)
  let nsamples = (nbytes div sizeof(float32)) div m.spec.channels
  zeroMem(buf, nbytes)
  withLock m.lock:
    for s in m.sources:
      s.mixInto(buf, nsamples, m)

proc openMixer* =
  mixer.spec = sdl.AudioSpec(
    freq: 44100,
    # format: AudioS16,
    format: AudioF32,
    channels: 2,
    samples: BufLen,
    callback: fillAudio,
    userdata: addr mixer,
  )
  doAssert sdl.openAudio(addr mixer.spec, nil) == 0, "Failed to open audio: " & $sdl.getError()
  sdl.pauseAudio(0)

proc closeMixer* =
  discard

proc createSource*(smp: ptr SampleInfo; loop: bool): Source =
  result = createU(SourceObj)
  result[] = SourceObj(
    kind: Wav,
    sample: smp,
    loop: loop
  )
  # TODO: avoid blocking by storing sources in an add-list which gets copied to the main list 
  withLock mixer.lock:
    mixer.sources.add(result)

proc createSource*(path: string; loop: bool): Source =
  result = createU(SourceObj)
  case splitFile(path).ext
  of ".wav":
    assert(false, "TODO")  # make wav discard itself after the source is done?
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
  
  withLock mixer.lock:
    mixer.sources.add(result)

proc destroySource*(s: Source) =
  # TODO
  discard

proc play*(s: Source) =
  case s.kind
  of Wav:
    s.samplePos = 0
  of Ogg:
    discard # TODO
  of Mod:
    let res = s.ctx.startPlayer(
      rate = mixer.spec.freq,
      flags = {}  # 16 bit, signed
    )
    doAssert res == 0, $res

import ../private/sdl/appcommon

proc xatuSetSampleData*(data: pointer) =
  echo "Set sample data: ", cast[uint](data)
  mixer.sampleData = cast[ptr UncheckedArray[float32]](data)

proc xatuCreateSourceFromFile*(f: cstring; loop: bool): NatuSource =
  createSource($f, loop).NatuSource

proc xatuCreateSourceFromSample*(smp: ptr SampleInfo): NatuSource =
  let loop = false # TODO: determine from whether sample has loop points.
  createSource(smp, loop).NatuSource

proc xatuDestroySource*(s: NatuSource) =
  let s = cast[Source](s)
  # todo

proc xatuPlaySource*(s: NatuSource) =
  let s = cast[Source](s)
  s.play()

proc xatuPauseSource*(s: NatuSource) =
  let s = cast[Source](s)
  # todo

proc xatuStopSource*(s: NatuSource) =
  let s = cast[Source](s)
  # todo

proc xatuSetSourceRate*(s: NatuSource, rate: float32) =
  let s = cast[Source](s)
  s.rateMul = rate

proc xatuSetSourceVolume*(s: NatuSource, vol: float32) =
  let s = cast[Source](s)
  # todo

proc xatuSetSourcePanning*(s: NatuSource, pan: float32) =
  let s = cast[Source](s)
  # todo

proc xatuSetSourcePosition*(s: NatuSource, pos: float32) =
  let s = cast[Source](s)
  # todo
