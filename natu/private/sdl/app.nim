import sdl2_nim/sdl
# import ./mgbavid
import ./video

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
