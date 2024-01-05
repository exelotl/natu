import std/[random, os, math, locks, atomics]
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
    loop: bool
    playing: bool = true
    done: Atomic[bool]      # end of playback has been reached - may be checked at any time
    rateMul: float32 = 1.0f
    vol: float32 = 1.0f
    pan: float32 = 0.0f
    case kind: SourceKind
    of Wav:
      sample: ptr SampleInfo
      samplePos: float32
    of Ogg:
      vorbis: Vorbis
    of Mod:
      ctx: XmpContext

  # ah fun, to minimize waiting on locks we'll need a command queue I guess
  CommandKind = enum
    PlaySource
    PauseSource
    CancelSource
    DestroySource
    SetSourceRate
    SetSourceVolume
    SetSourcePanning
    SetSourcePosition
  
  Command = object
    kind: CommandKind
    val: float32
    source: Source

  MixerState = object
    spec: sdl.AudioSpec
    lock: Lock
    sources {.guard: lock.}: seq[Source]
    sourcesToDestroy: seq[Source]
    commandsLock: Lock
    commands {.guard: commandsLock.}: seq[Command]
    xmpBuf: array[BufLen * Channels, int16]
    sampleData: ptr UncheckedArray[float32]

var mixer: MixerState

proc len*(smp: ptr SampleInfo): int =
  (smp.dataEnd - smp.dataStart).int div smp.channels.int

proc handleCommand(m: ptr MixerState; cmd: Command) {.gcsafe.}

proc mixInto(s: Source; dst: ptr UncheckedArray[float32]; nsamples: int; m: ptr MixerState) =
  case s.kind
  of Wav:
    # echo (cast[uint](m.sampleData), s.sample.dataStart)
    var data = cast[ptr UncheckedArray[float32]](addr m.sampleData[s.sample.dataStart])
    var pos = s.samplePos
    
    let rate = s.rateMul * (s.sample.sampleRate.float32 / m.spec.freq.float32)
    if s.loop:
      let loopStart = s.sample.loopStart.float32
      let loopEnd = s.sample.loopEnd.float32
      let loopLen = loopEnd - loopStart
      case s.sample.channels
      of 1:
        # looping, mono
        for i in 0..<nsamples:
          let j = i*2
          let v = data[pos.int]
          dst[j] += v
          dst[j+1] += v
          pos += rate
          if pos >= loopEnd:
            pos -= loopLen
      of 2:
        # looping, stereo
        for i in 0..<nsamples:
          let j = i*2
          let k = (pos.int) * 2
          dst[j] += data[k]
          dst[j+1] += data[k+1]
          pos += rate
          if pos >= loopEnd:
            pos -= loopLen
      else:
        echo "Bad channel count ", s.sample.channels
    else:
      var count = nsamples
      let remaining = s.sample.len - pos.int
      if remaining < nsamples:
        count = remaining
        s.playing = false
        s.done.store(true)
      case s.sample.channels
      of 1:
        # non-looping, mono
        for i in 0..<count:
          let j = i*2
          let v = data[pos.int]
          dst[j] += v
          dst[j+1] += v
          pos += rate
      of 2:
        # non-looping, stereo
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
    withLock m.commandsLock:
      echo (m.commands, m.sources.len)
      for cmd in m.commands:
        handleCommand(m, cmd)
      m.commands.setLen(0)
    for s in m.sources:
      s.mixInto(buf, nsamples, m)
    for s in m.sourcesToDestroy:
      let i = m.sources.find(s)
      assert(i != -1, "Tried to destroy source that's not in the sources list??")
      if i != -1:
        m.sources.del(i)
        dealloc(s)
    m.sourcesToDestroy.setLen(0)

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
  
  # TODO: ditto
  withLock mixer.lock:
    mixer.sources.add(result)

proc destroy(m: ptr MixerState; s: Source) {.gcsafe.} =
  m.sourcesToDestroy.add(s)

proc play(m: ptr MixerState; s: Source) {.gcsafe.} =
  s.playing = true
  case s.kind
  of Wav: discard
  of Ogg: discard # TODO
  of Mod:
    let res = s.ctx.startPlayer(
      rate = m.spec.freq,
      flags = {}  # 16 bit, signed
    )
    doAssert res == 0, $res

proc pause(m: ptr MixerState; s: Source) {.gcsafe.} =
  s.playing = false
  case s.kind
  of Wav: discard
  of Ogg: discard # TODO
  of Mod: discard

proc cancel(m: ptr MixerState; s: Source) {.gcsafe.} =
  s.playing = false
  s.done.store(true)
  case s.kind
  of Wav: discard # TODO
  of Ogg: discard # TODO
  of Mod: discard # TODO

proc setRate(m: ptr MixerState; s: Source; rate: float32) {.gcsafe.} =
  s.rateMul = rate
  case s.kind
  of Wav: discard
  of Ogg: discard # TODO
  of Mod: discard # TODO

proc setVolume(m: ptr MixerState; s: Source; vol: float32) {.gcsafe.} =
  s.vol = vol
  case s.kind
  of Wav: discard
  of Ogg: discard # TODO
  of Mod: discard # TODO

proc setPanning(m: ptr MixerState; s: Source; pan: float32) {.gcsafe.} =
  s.pan = pan
  case s.kind
  of Wav: discard
  of Ogg: discard # TODO
  of Mod: discard # TODO

proc setPosition(m: ptr MixerState; s: Source; pos: float32) {.gcsafe.} =
  case s.kind
  of Wav: discard # TODO - set to position in seconds
  of Ogg: discard # TODO - seek to seconds
  of Mod: discard # TODO - jump to order

proc handleCommand(m: ptr MixerState; cmd: Command) {.gcsafe.} =
  case cmd.kind
  of PlaySource: m.play(cmd.source)
  of PauseSource: m.pause(cmd.source)
  of CancelSource: m.cancel(cmd.source)
  of DestroySource:
    if not cmd.source.done.load(): m.cancel(cmd.source)
    m.destroy(cmd.source)
  of SetSourceRate: m.setRate(cmd.source, cmd.val)
  of SetSourceVolume: m.setVolume(cmd.source, cmd.val)
  of SetSourcePanning: m.setPanning(cmd.source, cmd.val)
  of SetSourcePosition: m.setPosition(cmd.source, cmd.val)


import ../private/sdl/appcommon

proc xatuSetSampleData*(data: pointer) =
  mixer.sampleData = cast[ptr UncheckedArray[float32]](data)

proc xatuCreateSourceFromFile*(f: cstring; loop: bool): NatuSource =
  createSource($f, loop).NatuSource

proc xatuCreateSourceFromSample*(smp: ptr SampleInfo): NatuSource =
  let loop = (smp.loopKind == LoopForward)
  createSource(smp, loop).NatuSource

proc xatuDestroySource*(s: NatuSource) =
  let c = Command(
    kind: DestroySource,
    source: cast[Source](s),
  )
  withLock mixer.commandsLock:
    mixer.commands.add c

proc xatuPlaySource*(s: NatuSource) =
  let c = Command(
    kind: PlaySource,
    source: cast[Source](s),
  )
  withLock mixer.commandsLock:
    mixer.commands.add c

proc xatuSourceDone*(s: NatuSource): bool =
  load(cast[Source](s).done)

proc xatuPauseSource*(s: NatuSource) =
  let c = Command(
    kind: PauseSource,
    source: cast[Source](s),
  )
  withLock mixer.commandsLock:
    mixer.commands.add c

proc xatuCancelSource*(s: NatuSource) =
  let c = Command(
    kind: CancelSource,
    source: cast[Source](s),
  )
  withLock mixer.commandsLock:
    mixer.commands.add c

proc xatuSetSourceRate*(s: NatuSource, rate: float32) =
  let c = Command(
    kind: SetSourceRate,
    source: cast[Source](s),
    val: rate
  )
  withLock mixer.commandsLock:
    mixer.commands.add c

proc xatuSetSourceVolume*(s: NatuSource, vol: float32) =
  let c = Command(
    kind: SetSourceVolume,
    source: cast[Source](s),
    val: vol
  )
  withLock mixer.commandsLock:
    mixer.commands.add c

proc xatuSetSourcePanning*(s: NatuSource, pan: float32) =
  let c = Command(
    kind: SetSourcePanning,
    source: cast[Source](s),
    val: pan
  )
  withLock mixer.commandsLock:
    mixer.commands.add c

proc xatuSetSourcePosition*(s: NatuSource, pos: float32) =
  let c = Command(
    kind: SetSourcePosition,
    source: cast[Source](s),
    val: pos
  )
  withLock mixer.commandsLock:
    mixer.commands.add c
