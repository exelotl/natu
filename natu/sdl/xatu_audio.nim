import sdl2_nim/sdl
import sdl2_nim/sdl_mixer as mix
import ../private/sdl/appcommon

proc openMixer* =
  
  doAssert mix.openAudio(
    frequency = 48000,
    format = AudioS16LSB,
    channels = 2,
    chunksize = 1024  # in bytes
  ) == 0,
    "Failed to open mixer: " & $mix.getError()
  
  const flags = InitOgg or InitMod
  
  doAssert mix.init(flags) == flags,
    "Failed to init mixer flags: " & $mix.getError()
  
  sdl.logInfo(LogCategoryApplication, "Mixer is a-go!")
  
  discard mix.allocateChannels(16)
  

proc closeMixer* =
  
  var i = 50
  while mix.init(0) != 0:
    mix.quit()
    dec i
    if i <= 0: break  # bail
  
  let mixNumOpened = mix.querySpec(nil, nil, nil)
  for i in 0..<mixNumOpened:
    mix.closeAudio()


converter toMusic(m: NatuMusic): Music =
  cast[Music](m)

converter toChunk(s: NatuSample): Chunk =
  cast[Chunk](s)

proc xatuLoadMusic*(f: cstring): NatuMusic =
  echo "Loading ", f
  let music = mix.loadMus(f)
  if music.isNil:
    echo "Nope."
    sdl.logInfo(LogCategoryApplication, "Failed to load music: %s", mix.getError())
  music.NatuMusic

proc xatuFreeMusic*(music: NatuMusic) =
  if not music.isNil:
    mix.freeMusic(music)

proc xatuStartMusic*(music: NatuMusic; loops: cint) =
  echo "Starting"
  if not music.isNil:
    echo "Play!"
    doAssert mix.playMusic(music, loops) == 0

proc xatuPauseMusic*() =
  mix.pauseMusic()

proc xatuResumeMusic*() =
  mix.resumeMusic()

proc xatuStopMusic*() =
  mix.pauseMusic()
  mix.rewindMusic()

proc xatuSetMusicPosition*(pos: cdouble) =
  discard mix.setMusicPosition(pos)

proc xatuSetMusicVolume*(vol: cfloat) =
  discard mix.volumeMusic((vol * 128).cint)

proc xatuLoadSample*(f: cstring): NatuSample =
  let chunk = mix.loadWav(f)
  if chunk.isNil:
    sdl.logInfo(LogCategoryApplication, "Failed to load sample: %s", mix.getError())
  chunk.NatuSample

proc xatuFreeSample*(sample: NatuSample) =
  if not sample.isNil:
    mix.freeChunk(sample)

proc xatuPlaySample*(sample: NatuSample) =
  discard mix.playChannel(-1, sample, loops=0)

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

