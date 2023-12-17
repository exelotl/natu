import sdl2_nim/sdl
import ./xatu_mgba
import ../private/sdl/appcommon

# mGBA Renderer + app mem
# -----------------------

var swr: GBAVideoSoftwareRenderer  # internal mGBA renderer state
var mem*: NatuAppMem               # memory passed to the game shared lib

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
    mem.palram[0] = 0x0f

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
  # echo "Frame"
  for i in 0..<160:
    swr.oamDirty = true
    # echo "---------- ", cast[uint32](addr swr.oamDirty).toHex(16)
    # swr.writeOAM(0)
    
    mem.regs[GBA_REG_VCOUNT] = i.uint16
    discard swr.writeVideoRegister(GBA_REG_DISPCNT, mem.regs[GBA_REG_DISPCNT])
    discard swr.writeVideoRegister(GBA_REG_GREENSWP, mem.regs[GBA_REG_GREENSWP])
    # discard swr.writeVideoRegister(GBA_REG_DISPSTAT, mem.regs[GBA_REG_DISPSTAT])
    discard swr.writeVideoRegister(GBA_REG_BG0CNT, mem.regs[GBA_REG_BG0CNT])
    discard swr.writeVideoRegister(GBA_REG_BG1CNT, mem.regs[GBA_REG_BG1CNT])
    discard swr.writeVideoRegister(GBA_REG_BG2CNT, mem.regs[GBA_REG_BG2CNT])
    discard swr.writeVideoRegister(GBA_REG_BG3CNT, mem.regs[GBA_REG_BG3CNT])
    discard swr.writeVideoRegister(GBA_REG_BG0HOFS, mem.regs[GBA_REG_BG0HOFS])
    discard swr.writeVideoRegister(GBA_REG_BG0VOFS, mem.regs[GBA_REG_BG0VOFS])
    discard swr.writeVideoRegister(GBA_REG_BG1HOFS, mem.regs[GBA_REG_BG1HOFS])
    discard swr.writeVideoRegister(GBA_REG_BG1VOFS, mem.regs[GBA_REG_BG1VOFS])
    discard swr.writeVideoRegister(GBA_REG_BG2HOFS, mem.regs[GBA_REG_BG2HOFS])
    discard swr.writeVideoRegister(GBA_REG_BG2VOFS, mem.regs[GBA_REG_BG2VOFS])
    discard swr.writeVideoRegister(GBA_REG_BG3HOFS, mem.regs[GBA_REG_BG3HOFS])
    discard swr.writeVideoRegister(GBA_REG_BG3VOFS, mem.regs[GBA_REG_BG3VOFS])
    discard swr.writeVideoRegister(GBA_REG_BG2PA, mem.regs[GBA_REG_BG2PA])
    discard swr.writeVideoRegister(GBA_REG_BG2PB, mem.regs[GBA_REG_BG2PB])
    discard swr.writeVideoRegister(GBA_REG_BG2PC, mem.regs[GBA_REG_BG2PC])
    discard swr.writeVideoRegister(GBA_REG_BG2PD, mem.regs[GBA_REG_BG2PD])
    discard swr.writeVideoRegister(GBA_REG_BG2X_LO, mem.regs[GBA_REG_BG2X_LO])
    discard swr.writeVideoRegister(GBA_REG_BG2X_HI, mem.regs[GBA_REG_BG2X_HI])
    discard swr.writeVideoRegister(GBA_REG_BG2Y_LO, mem.regs[GBA_REG_BG2Y_LO])
    discard swr.writeVideoRegister(GBA_REG_BG2Y_HI, mem.regs[GBA_REG_BG2Y_HI])
    discard swr.writeVideoRegister(GBA_REG_BG3PA, mem.regs[GBA_REG_BG3PA])
    discard swr.writeVideoRegister(GBA_REG_BG3PB, mem.regs[GBA_REG_BG3PB])
    discard swr.writeVideoRegister(GBA_REG_BG3PC, mem.regs[GBA_REG_BG3PC])
    discard swr.writeVideoRegister(GBA_REG_BG3PD, mem.regs[GBA_REG_BG3PD])
    discard swr.writeVideoRegister(GBA_REG_BG3X_LO, mem.regs[GBA_REG_BG3X_LO])
    discard swr.writeVideoRegister(GBA_REG_BG3X_HI, mem.regs[GBA_REG_BG3X_HI])
    discard swr.writeVideoRegister(GBA_REG_BG3Y_LO, mem.regs[GBA_REG_BG3Y_LO])
    discard swr.writeVideoRegister(GBA_REG_BG3Y_HI, mem.regs[GBA_REG_BG3Y_HI])
    discard swr.writeVideoRegister(GBA_REG_WIN0H, mem.regs[GBA_REG_WIN0H])
    discard swr.writeVideoRegister(GBA_REG_WIN1H, mem.regs[GBA_REG_WIN1H])
    discard swr.writeVideoRegister(GBA_REG_WIN0V, mem.regs[GBA_REG_WIN0V])
    discard swr.writeVideoRegister(GBA_REG_WIN1V, mem.regs[GBA_REG_WIN1V])
    discard swr.writeVideoRegister(GBA_REG_WININ, mem.regs[GBA_REG_WININ])
    discard swr.writeVideoRegister(GBA_REG_WINOUT, mem.regs[GBA_REG_WINOUT])
    discard swr.writeVideoRegister(GBA_REG_MOSAIC, mem.regs[GBA_REG_MOSAIC])
    discard swr.writeVideoRegister(GBA_REG_BLDCNT, mem.regs[GBA_REG_BLDCNT])
    discard swr.writeVideoRegister(GBA_REG_BLDALPHA, mem.regs[GBA_REG_BLDALPHA])
    discard swr.writeVideoRegister(GBA_REG_BLDY, mem.regs[GBA_REG_BLDY])
    # mem.palram[0] = (i*2).uint16
    swr.drawScanline(i.cint)
  swr.finishFrame()


# SDL App definition
# ------------------

const
  Title = "SDL2 App"
  ScreenW = 240*3 # Window width
  ScreenH = 160*3 # Window height

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


proc start*(app: App) =
  
  assert(not app.running)
  
  check sdl.init(sdl.InitVideo)
  
  app.window = sdl.createWindow(
    title = Title,
    x = sdl.WindowPosUndefined,
    y = sdl.WindowPosUndefined,
    w = ScreenW,
    h = ScreenH,
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
  
  sdl.logInfo(sdl.LogCategoryApplication, "SDL initialized successfully")
  app.running = true
  
  app.texture = sdl.createTexture(
    app.renderer,
    sdl.PIXELFORMAT_ABGR8888,   # ABGR1555 doesn't work cause mGBA already converts to true color for us.
    sdl.TEXTUREACCESS_STREAMING,
    240, 160                        # muffin
  )
  doAssert(app.texture != nil)
  
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
      
      # Exit on Escape key press
      if e.key.keysym.sym == sdl.K_Escape:
        app.running = false
