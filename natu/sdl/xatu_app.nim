import sdl2_nim/sdl
import ./xatu_mgba
import ./xatu_input
import ./xatu_audio
import ../private/sdl/appcommon

# mGBA Renderer + app mem
# -----------------------

var swr: GBAVideoSoftwareRenderer  # internal mGBA renderer state
var mem*: NatuAppMem               # memory passed to the game shared lib

proc gbaInit() =
  
  mem.regs[GBA_REG_KEYINPUT shr 1] = 0xffff  # no keys held
  
  # BG affine matrices
  mem.regs[0x020 shr 1] = 0x100
  mem.regs[0x026 shr 1] = 0x100
  mem.regs[0x030 shr 1] = 0x100
  mem.regs[0x036 shr 1] = 0x100

proc vidSetBuffer*(pitch: cint, buf: pointer) =
  const bytesPerPixel = 4
  swr.outputBuffer = cast[ptr color_t](buf)
  swr.outputBufferStride = pitch div bytesPerPixel

proc vidStart*(pitch: cint, buf: pointer) =
  
  GBAVideoSoftwareRendererCreate(addr swr)
  swr.d.palette = addr mem.palram
  swr.d.vram = addr mem.vram
  swr.d.oam = cast[ptr GBAOAM](addr mem.oam)
  
  vidSetBuffer(pitch, buf)
  
  for v in mitems(swr.scanlineDirty):
    v = 0xffffffff'u32
  
  swr.init()
  # swr.reset()  # already called by init
  
  block:
    # swr.dispcnt.forcedBlank = false
    mem.palram[0] = 0x0

proc vidWritePalMem* =
  # happens once per scanline so could do with optimising probably...
  for i, color in mem.palram:
    let address = (i*2).uint32
    swr.writePalette(address, color)
  
  # for i, hw in mem.vram:
  #   swr.writeVRAM((i*2).uint32)
  
  # we basically need to tear out all these caches I think...
  # swr.bg[0].yCache = -1
  # swr.bg[1].yCache = -1
  # swr.bg[2].yCache = -1
  # swr.bg[3].yCache = -1

# import std/strutils

proc vidDraw* =
  vidWritePalMem()
  
  let dispstat = cast[ptr GBARegisterDISPSTAT](addr mem.regs[GBA_REG_DISPSTAT shr 1])
  
  dispstat[].inVblank = true
  
  for i in 0 ..< natuVideoVerticalPixels.int:
    swr.oamDirty = true
    # echo "---------- ", cast[uint32](addr swr.oamDirty).toHex(16)
    # swr.writeOAM(0)
    
    mem.regs[GBA_REG_VCOUNT shr 1] = i.uint16
    discard swr.writeVideoRegister(GBA_REG_DISPCNT, mem.regs[GBA_REG_DISPCNT shr 1])
    discard swr.writeVideoRegister(GBA_REG_GREENSWP, mem.regs[GBA_REG_GREENSWP shr 1])
    # discard swr.writeVideoRegister(GBA_REG_DISPSTAT, mem.regs[GBA_REG_DISPSTAT shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG0CNT, mem.regs[GBA_REG_BG0CNT shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG1CNT, mem.regs[GBA_REG_BG1CNT shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG2CNT, mem.regs[GBA_REG_BG2CNT shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG3CNT, mem.regs[GBA_REG_BG3CNT shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG0HOFS, mem.regs[GBA_REG_BG0HOFS shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG0VOFS, mem.regs[GBA_REG_BG0VOFS shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG1HOFS, mem.regs[GBA_REG_BG1HOFS shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG1VOFS, mem.regs[GBA_REG_BG1VOFS shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG2HOFS, mem.regs[GBA_REG_BG2HOFS shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG2VOFS, mem.regs[GBA_REG_BG2VOFS shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG3HOFS, mem.regs[GBA_REG_BG3HOFS shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG3VOFS, mem.regs[GBA_REG_BG3VOFS shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG2PA, mem.regs[GBA_REG_BG2PA shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG2PB, mem.regs[GBA_REG_BG2PB shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG2PC, mem.regs[GBA_REG_BG2PC shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG2PD, mem.regs[GBA_REG_BG2PD shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG2X_LO, mem.regs[GBA_REG_BG2X_LO shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG2X_HI, mem.regs[GBA_REG_BG2X_HI shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG2Y_LO, mem.regs[GBA_REG_BG2Y_LO shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG2Y_HI, mem.regs[GBA_REG_BG2Y_HI shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG3PA, mem.regs[GBA_REG_BG3PA shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG3PB, mem.regs[GBA_REG_BG3PB shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG3PC, mem.regs[GBA_REG_BG3PC shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG3PD, mem.regs[GBA_REG_BG3PD shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG3X_LO, mem.regs[GBA_REG_BG3X_LO shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG3X_HI, mem.regs[GBA_REG_BG3X_HI shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG3Y_LO, mem.regs[GBA_REG_BG3Y_LO shr 1])
    discard swr.writeVideoRegister(GBA_REG_BG3Y_HI, mem.regs[GBA_REG_BG3Y_HI shr 1])
    discard swr.writeVideoRegister(XATU_REG_WIN0X1, mem.regs[XATU_REG_WIN0X1 shr 1])
    discard swr.writeVideoRegister(XATU_REG_WIN0X2, mem.regs[XATU_REG_WIN0X2 shr 1])
    discard swr.writeVideoRegister(XATU_REG_WIN0Y1, mem.regs[XATU_REG_WIN0Y1 shr 1])
    discard swr.writeVideoRegister(XATU_REG_WIN0Y2, mem.regs[XATU_REG_WIN0Y2 shr 1])
    discard swr.writeVideoRegister(XATU_REG_WIN1X1, mem.regs[XATU_REG_WIN1X1 shr 1])
    discard swr.writeVideoRegister(XATU_REG_WIN1X2, mem.regs[XATU_REG_WIN1X2 shr 1])
    discard swr.writeVideoRegister(XATU_REG_WIN1Y1, mem.regs[XATU_REG_WIN1Y1 shr 1])
    discard swr.writeVideoRegister(XATU_REG_WIN1Y2, mem.regs[XATU_REG_WIN1Y2 shr 1])
    discard swr.writeVideoRegister(GBA_REG_WININ, mem.regs[GBA_REG_WININ shr 1])
    discard swr.writeVideoRegister(GBA_REG_WINOUT, mem.regs[GBA_REG_WINOUT shr 1])
    discard swr.writeVideoRegister(GBA_REG_MOSAIC, mem.regs[GBA_REG_MOSAIC shr 1])
    discard swr.writeVideoRegister(GBA_REG_BLDCNT, mem.regs[GBA_REG_BLDCNT shr 1])
    discard swr.writeVideoRegister(GBA_REG_BLDALPHA, mem.regs[GBA_REG_BLDALPHA shr 1])
    discard swr.writeVideoRegister(GBA_REG_BLDY, mem.regs[GBA_REG_BLDY shr 1])
    # mem.palram[0] = (i*2).uint16
    swr.drawScanline(i.cint)
  swr.finishFrame()
  dispstat[].inVblank = false


# SDL App definition
# ------------------

const
  Title = "SDL2 App"
  WindowScale = 3

type
  App* = ref AppObj
  AppObj = object
    window*: sdl.Window # Window pointer
    renderer*: sdl.Renderer # Rendering state pointer
    texture*: sdl.Texture
    running*: bool
  
  # AppError* = object of CatchableError
  #   kind*: ErrorKind

template check(res: cint) =
  doAssert res == 0, "Err = " & $sdl.getError()

template check(res: pointer) =
  doAssert res != nil, "Err = " & $sdl.getError()


proc start*(app: App; lcdW, lcdH: int) =
  
  assert(not app.running)
  
  check sdl.init(sdl.InitVideo or sdl.InitAudio)
  
  app.window = sdl.createWindow(
    title = Title,
    x = sdl.WindowPosUndefined,
    y = sdl.WindowPosUndefined,
    w = lcdW * WindowScale,
    h = lcdH * WindowScale,
    flags = 0
  )
  check app.window
  
  app.renderer = sdl.createRenderer(
    window = app.window,
    index = -1, 
    # flags = sdl.RendererAccelerated or sdl.RendererPresentVsync
    flags = sdl.RendererSoftware or sdl.RendererPresentVsync
  )
  
  check app.renderer
  check app.renderer.setRenderDrawColor(0x22, 0x11, 0x22, 0xFF)
  
  openMixer()
  
  sdl.logInfo(sdl.LogCategoryApplication, "SDL initialized successfully")
  app.running = true
  
  app.texture = sdl.createTexture(
    app.renderer,
    sdl.PIXELFORMAT_ABGR8888,   # ABGR1555 doesn't work cause mGBA already converts to true color for us.
    sdl.TEXTUREACCESS_STREAMING,
    lcdW, lcdH
  )
  doAssert(app.texture != nil)
  
  natuMgbaSetLcdSize(lcdW, lcdH)
  gbaInit()
  
  var pitch: cint
  var buffer: pointer
  check sdl.lockTexture(app.texture, nil, addr buffer, addr pitch)
  vidStart(pitch, buffer)


proc draw*(app: App) =
  vidDraw()
  sdl.unlockTexture(app.texture)
  # for i in 0..<10:
  check sdl.renderCopy(app.renderer, app.texture, nil, nil)
  sdl.renderPresent(app.renderer)
  var pitch: cint
  var buffer: pointer
  check sdl.lockTexture(app.texture, nil, addr buffer, addr pitch)
  vidSetBuffer(pitch, buffer)

proc exit*(app: App) =
  app.renderer.destroyRenderer()
  app.window.destroyWindow()
  closeMixer()
  sdl.logInfo(sdl.LogCategoryApplication, "SDL shutdown completed")
  sdl.quit()

proc handleEvents*(app: App) =
  var e: sdl.Event
  
  while sdl.pollEvent(addr(e)) != 0:
    
    # Quit requested
    if e.kind == sdl.Quit:
      app.running = false
    
    # Key pressed
    elif e.kind == sdl.KeyDown:
      # Show what key was pressed
      sdl.logInfo(sdl.LogCategoryApplication, "Pressed %s", $e.key.keysym.sym)
      
      pressKey(e.key)
      
      # Exit on Escape key press
      if e.key.keysym.sym == sdl.K_Escape:
        app.running = false
    
    elif e.kind == sdl.KeyUp:
      releaseKey(e.key)
  
  mem.regs[GBA_REG_KEYINPUT shr 1] = not cast[uint16](gbaKeys)
  updateKeys()
