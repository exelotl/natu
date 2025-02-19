type
  NatuSource* {.borrow.} = distinct pointer
    ## A thing that emits audio

proc `==`*(a, b: NatuSource): bool {.borrow.}
proc isNil*(a: NatuSource): bool {.borrow.}


#[
  On GBA:
                 ---------------BG-VRAM-------------- ---OBJ-VRAM----
  Charblocks:   | 0 (16K) |   1    |   2    |   3    |   4   |   5   |
  Screenblocks: |  0..7   |  8..15 | 16..23 | 24..31 |       |       |
  
  On PC:
                 -----------------BG-TILE-VRAM------------------ -------OBJ-VRAM-------- ----------BG-MAP-VRAM-----------
  Charblocks:   |  0 (32K)  |     1     |     2     |     3     |     4     |     5     | unused ...   ..    ..    ..    |
  Screenblocks: | unused...   ..    ..    ..     ..      ..     |  ..    ..    ..       | 0..7 | 8..15 | 16..23 | 24..31 | 
  
]#

const NatuCbLen* = 8192*2  # twice as big as normal
const NatuSbLen* = 1024
const NatuSbStart* = NatuCbLen*6
const NatuVramLen* = NatuCbLen*6 + NatuSbLen*32

const NatuBgPalRamLen* = 256
const NatuObjPalRamLen* = 512
const NatuPalRamLen* = NatuBgPalRamLen + NatuObjPalRamLen

const NatuNumObjs* = 256
const NatuNumMatrices* = NatuNumObjs div 4
const NatuOamLen* = NatuNumObjs * 4

{.passC: "-DNATU_CB_LEN=" & $NatuCbLen.}
{.passC: "-DNATU_SB_LEN=" & $NatuSbLen.}
{.passC: "-DNATU_SB_START=" & $NatuSbStart.}
{.passC: "-DNATU_VRAM_LEN=" & $NatuVramLen.}
{.passC: "-DNATU_BG_PAL_RAM_LEN=" & $NatuBgPalRamLen.}
{.passC: "-DNATU_OBJ_PAL_RAM_LEN=" & $NatuObjPalRamLen.}
{.passC: "-DNATU_PAL_RAM_LEN=" & $NatuPalRamLen.}
{.passC: "-DNATU_NUM_OBJS=" & $NatuNumObjs.}
{.passC: "-DNATU_NUM_MATRICES=" & $NatuNumMatrices.}
{.passC: "-DNATU_OAM_LEN=" & $NatuOamLen.}

type
  LoopKind* = enum
    LoopNone
    LoopForward
    LoopPingPong
  
  SampleInfo* = object
    dataStart*: uint32   # measured in floats
    dataEnd*: uint32     # .. (exclusive)
    channels*: uint16
    sampleRate*: uint32
    loopKind*: LoopKind
    loopStart*: uint32  # measured in samples (mono or stereo)
    loopEnd*: uint32    # ..
  
  GamepadAxis* = enum
    axisNone
    axisLeftStickX
    axisLeftStickY
    axisRightStickX
    axisRightStickY
    axisLeftTrigger
    axisRightTrigger
  
  GamepadButton* = enum
    btnNone
    
    # Buttons matching the SDL constants
    btnA  # B on Nintendo Switch
    btnB  # A on Nintendo Switch
    btnX  # Y on Nintendo Switch
    btnY  # X on Nintendo Switch
    btnBack
    btnGuide
    btnStart
    btnLeftStick
    btnRightStick
    btnLeftShoulder
    btnRightShoulder
    btnUp
    btnDown
    btnLeft
    btnRight
    btnMisc1
    
    # Fake buttons that are actually joystick / trigger axes
    btnLeftStickUp
    btnLeftStickDown
    btnLeftStickLeft
    btnLeftStickRight
    btnRightStickUp
    btnRightStickDown
    btnRightStickLeft
    btnRightStickRight
    btnLeftTrigger
    btnRightTrigger
    
    # Buttons matching the labels on the controllers, as opposed to positions.
    btnUiA
    btnUiB
    btnUiX
    btnUiY
  
  GamepadKind* = enum
    GamepadUnknown        # note: Unknown gamepads may have `swapUiButtons` set or not, depending on what platform xatu is compiled for.
    GamepadStandard
    GamepadXbox360
    GamepadXboxOne
    GamepadPs3
    GamepadPs4
    GamepadPs5
    GamepadSwitchPro
    GamepadJoyconLeft
    GamepadJoyconRight
    GamepadJoyconPair
  
  Gamepad* = object
    uid*: string
    kind*: GamepadKind
    swapUiButtons*: bool
    currAxisStates*: array[GamepadAxis, float32]
    prevAxisStates*: array[GamepadAxis, float32]
    currBtnStates*: set[GamepadButton]
    prevBtnStates*: set[GamepadButton]
    rumbleSupported*: bool
    pinned*: bool    # This gamepad is locked in place and can't be reassigned to another slot.
    lastActivity*: uint64
  
  VideoSettings* = object
    title*: cstring = "Natu Game"
    pixelScale*: int = 3
    fullscreen*: bool = false
    screenFilter*: uint8 = 0
    unused: uint16
  
  NatuAppMem* = object
    regs*: array[0x200, uint16]
    palram*: array[NatuPalRamLen, uint16]
    vram*: array[NatuVramLen, uint16]
    oam*: array[NatuOamLen, uint32]
    softResetFlag*: bool
    availableScreenFilters*: uint8
    apiVersion*: uint16
    videoSettings*: VideoSettings
    activityTimer*: uint64   # Ticks up each frame, can be compared to `gamepad.lastActivity`
    
    # api:
    quit*: proc () {.nimcall.}
    panic*: proc (msg1: cstring; msg2: cstring = nil) {.nimcall.}
    printf*: proc (format: cstring) {.cdecl, varargs.}
    setSampleData*: proc (data: pointer) {.nimcall.}
    createSourceFromSample*: proc (smp: ptr SampleInfo): NatuSource {.nimcall.}
    createSourceFromFile*: proc (f: cstring; loop: bool): NatuSource {.nimcall.}
    destroySource*: proc (s: NatuSource) {.nimcall.}
    sourceDone*: proc (s: NatuSource): bool {.nimcall.}
    playSource*: proc (s: NatuSource) {.nimcall.}
    pauseSource*: proc (s: NatuSource) {.nimcall.}
    cancelSource*: proc (s: NatuSource) {.nimcall.}
    setSourceRate*: proc (s: NatuSource, rate: float32) {.nimcall.}
    setSourceVolume*: proc (s: NatuSource, vol: float32) {.nimcall.}
    setSourcePanning*: proc (s: NatuSource, pan: float32) {.nimcall.}
    setSourcePosition*: proc (s: NatuSource, pos: int32) {.nimcall.}
    getSourcePosition*: proc (s: NatuSource): int32 {.nimcall.}
    setSourceTime*: proc (s: NatuSource, seconds: float32) {.nimcall.}
    getSourceTime*: proc (s: NatuSource): float32 {.nimcall.}
    setSourceGroup*: proc (s: NatuSource, group: int32) {.nimcall.}
    setAudioGroupVolume*: proc (group: int32; vol: float32) {.nimcall.}
    startDma*: proc(reg: pointer) {.nimcall.}
    stopDma*: proc(reg: pointer) {.nimcall.}
    getGamepad*: proc (i: int32): ptr Gamepad {.nimcall.}
    numGamepads*: proc (): int32 {.nimcall.}
    swapGamepads*: proc (i, j: int32) {.nimcall.}
    setKeyboardOnly*: proc (i: int32; val: bool) {.nimcall.}
    isKeyboardOnly*: proc (i: int32): bool {.nimcall.}
    applyRumble*: proc (i: int32; power: float32) {.nimcall.}
    keyIsDown*: proc (keycode: int32): bool {.nimcall.}
    keyWasDown*: proc (keycode: int32): bool {.nimcall.}
    getPerfTimer*: proc (): float64 {.nimcall.}
    readFile*: proc (path: cstring): tuple[ok: bool, res: string] {.nimcall.}
    writeFile*: proc (path: cstring; contents: string): tuple[ok: bool, msg: string] {.nimcall.}
    fileExists*: proc (path: cstring): bool {.nimcall.}
    getEnv*: proc (key: cstring): string {.nimcall.}
    applyVideoSettings*: proc () {.nimcall.}
    setAchievement*: proc (name: cstring) {.nimcall.}
    setIntStat*: proc (name: cstring; val: int) {.nimcall.}
    setFloatStat*: proc (name: cstring; val: float32) {.nimcall.}
    setAvgStat*: proc (name: cstring; num, den: float32) {.nimcall.}
    storeStats*: proc () {.nimcall.}
    getSaveDir*: proc (): string {.nimcall.}
    getSteamLanguage*: proc (): string {.nimcall.}
    usePlayerIndexes*: proc (a, b: int32) {.nimcall.}
