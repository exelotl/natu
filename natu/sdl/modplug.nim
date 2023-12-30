when defined windows:
  const ModPlugLib* = "modplug.dll"
elif defined macosx:
  const ModPlugLib* = "libmodplug.dylib"
else:
  const ModPlugLib* = "libmodplug.so(|.1.0.0|.1)"

type
  ModPlugFile* = ptr object
  
  ModPlugNote* {.bycopy.} = object
    note*: cuchar
    instrument*: cuchar
    volumeEffect*: cuchar
    effect*: cuchar
    volume*: cuchar
    parameter*: cuchar
  
  ModPlugMixerProc* = proc (buffer: ptr cint; channels: culong; nsamples: culong) {.cdecl.}
    ## 
    ## To be passed to `initMixerCallback`.
    ## Use this if you want to 'modify' the mixed data of LibModPlug.
    ## 
    ## 'buffer': A buffer of mixed samples (samples are signed 32-bit integers)
    ## 'channels': N. of channels in the buffer
    ## 'nsamples': N. of samples in the buffer (without taking care of n.channels)
    ##
  
  MpFlag* = enum
    Oversampling   ## Enable oversampling (*highly* recommended)
    NoiseReduction ## Enable noise reduction
    Reverb         ## Enable reverb
    Megabass       ## Enable megabass
    Surround       ## Enable surround sound
  
  ModPlugFlags* {.size: sizeof(cint).} = set[MpFlag]
  
  ModPlugResamplingMode* {.size: sizeof(cint).} = enum
    ResampleNearest ## No interpolation (very fast, extremely bad sound quality)
    ResampleLinear  ## Linear interpolation (fast, good quality)
    ResampleSpline  ## Cubic spline interpolation (high quality)
    ResampleFir     ## 8-tap fir filter (extremely high quality)
  
  ModPlugSettings* {.bycopy.} = object
    ## Note that ModPlug always decodes sound at 44100kHz, 32 bit, stereo and
    ## then down-mixes to the settings you choose.
    flags*: ModPlugFlags     ## Bitset of MpFlag
    channels*: cint          ## Number of channels - 1 for mono or 2 for stereo
    bits*: cint              ## Bits per sample - 8, 16, or 32
    frequency*: cint         ## Sampling rate - 11025, 22050, or 44100
    resamplingMode*: ModPlugResamplingMode  ## One of ResampleXxx, above
    stereoSeparation*: cint  ## Stereo separation, 1 - 256
    maxMixChannels*: cint    ## Maximum number of mixing channels (polyphony), 32 - 256
    reverbDepth*: cint       ## Reverb level 0(quiet)-100(loud)
    reverbDelay*: cint       ## Reverb delay in ms, usually 40-200ms
    bassAmount*: cint        ## XBass level 0(quiet)-100(loud)
    bassRange*: cint         ## XBass cutoff in Hz 10-100
    surroundDepth*: cint     ## Surround level 0(quiet)-100(heavy)
    surroundDelay*: cint     ## Surround delay in ms, usually 5-40ms
    loopCount*: cint         ## Number of times to loop.  Zero prevents looping. -1 loops forever.


proc load*(data: pointer; size: cint): ModPlugFile {.importc: "ModPlug_Load", dynlib: ModPlugLib.}
  ## Load a mod file.  [data] should point to a block of memory containing the complete file, and [size] should be the size of that block.
  ## Return the loaded mod file on success, or NULL on failure.

proc unload*(file: ModPlugFile) {.importc: "ModPlug_Unload", dynlib: ModPlugLib.}
  ## Unload a mod file.

proc read*(file: ModPlugFile; buffer: pointer; size: cint): cint {.importc: "ModPlug_Read", dynlib: ModPlugLib.}
  ## Read sample data into the buffer.  Returns the number of bytes read.  If the end
  ## of the mod has been reached, zero is returned.

proc getName*(file: ModPlugFile): cstring {.importc: "ModPlug_GetName", dynlib: ModPlugLib.}
  ## Get the name of the mod.  The returned buffer is stored within the ModPlugFile
  ## structure and will remain valid until you unload the file.

proc getLength*(file: ModPlugFile): cint {.importc: "ModPlug_GetLength", dynlib: ModPlugLib.}
  ## Get the length of the mod, in milliseconds.  Note that this result is not always
  ## accurate, especially in the case of mods with loops.

proc seek*(file: ModPlugFile; millisecond: cint) {.importc: "ModPlug_Seek", dynlib: ModPlugLib.}
  ## Seek to a particular position in the song.  Note that seeking and MODs don't mix very
  ## well.  Some mods will be missing instruments for a short time after a seek, as ModPlug
  ## does not scan the sequence backwards to find out which instruments were supposed to be
  ## playing at that time.  (Doing so would be difficult and not very reliable.)  Also,
  ## note that seeking is not very exact in some mods -- especially those for which
  ## ModPlug_GetLength() does not report the full length.

proc getSettings*(settings: ptr ModPlugSettings) {.importc: "ModPlug_GetSettings", dynlib: ModPlugLib.}
  ## Get and set the mod decoder settings.  All options, except for channels, bits-per-sample,
  ## sampling rate, and loop count, will take effect immediately.  Those options which don't
  ## take effect immediately will take effect the next time you load a mod.

proc setSettings*(settings: ptr ModPlugSettings) {.importc: "ModPlug_SetSettings", dynlib: ModPlugLib.}

proc getMasterVolume*(file: ModPlugFile): cuint {.importc: "ModPlug_GetMasterVolume", dynlib: ModPlugLib.}
  ## NOTE: Master Volume (1-512)
proc setMasterVolume*(file: ModPlugFile; cvol: cuint) {.importc: "ModPlug_SetMasterVolume", dynlib: ModPlugLib.}
proc getCurrentSpeed*(file: ModPlugFile): cint {.importc: "ModPlug_GetCurrentSpeed", dynlib: ModPlugLib.}
proc getCurrentTempo*(file: ModPlugFile): cint {.importc: "ModPlug_GetCurrentTempo", dynlib: ModPlugLib.}
proc getCurrentOrder*(file: ModPlugFile): cint {.importc: "ModPlug_GetCurrentOrder", dynlib: ModPlugLib.}
proc getCurrentPattern*(file: ModPlugFile): cint {.importc: "ModPlug_GetCurrentPattern", dynlib: ModPlugLib.}
proc getCurrentRow*(file: ModPlugFile): cint {.importc: "ModPlug_GetCurrentRow", dynlib: ModPlugLib.}
proc getPlayingChannels*(file: ModPlugFile): cint {.importc: "ModPlug_GetPlayingChannels", dynlib: ModPlugLib.}
proc seekOrder*(file: ModPlugFile; order: cint) {.importc: "ModPlug_SeekOrder", dynlib: ModPlugLib.}
proc getModuleType*(file: ModPlugFile): cint {.importc: "ModPlug_GetModuleType", dynlib: ModPlugLib.}
proc getMessage*(file: ModPlugFile): cstring {.importc: "ModPlug_GetMessage", dynlib: ModPlugLib.}
proc numInstruments*(file: ModPlugFile): cuint {.importc: "ModPlug_NumInstruments", dynlib: ModPlugLib.}
proc numSamples*(file: ModPlugFile): cuint {.importc: "ModPlug_NumSamples", dynlib: ModPlugLib.}
proc numPatterns*(file: ModPlugFile): cuint {.importc: "ModPlug_NumPatterns", dynlib: ModPlugLib.}
proc numChannels*(file: ModPlugFile): cuint {.importc: "ModPlug_NumChannels", dynlib: ModPlugLib.}
proc sampleName*(file: ModPlugFile; qual: cuint; buff: cstring): cuint {.importc: "ModPlug_SampleName", dynlib: ModPlugLib.}
proc instrumentName*(file: ModPlugFile; qual: cuint; buff: cstring): cuint {.importc: "ModPlug_InstrumentName", dynlib: ModPlugLib.}
proc getPattern*(file: ModPlugFile; pattern: cint; numrows: ptr cuint): ptr ModPlugNote {.importc: "ModPlug_GetPattern", dynlib: ModPlugLib.}
  ##
  ## Retrieve pattern note-data
  ##

proc initMixerCallback*(file: ModPlugFile; cb: ModPlugMixerProc) {.importc: "ModPlug_InitMixerCallback", dynlib: ModPlugLib.}
proc unloadMixerCallback*(file: ModPlugFile) {.importc: "ModPlug_UnloadMixerCallback", dynlib: ModPlugLib.}
