from ./private/privutils import writeFields

type
  TimerFreq* = enum
    tf17MHz     ## 1 cycle per tick (16.78 Mhz)
    tf262kHz    ## 64 cycles per tick (262.21 kHz)
    tf66kHz     ## 256 cycles per tick (65.536 kHz)
    tf16kHz     ## 1024 cycles per tick (16.384 kHz)
    tfCascade   ## Timer ticks when the preceding timer overflows.
  
  Timer* {.bycopy, exportc.} = object
    ## Provides access to a timer data register and the corresponding timer control register.
    
    data: uint16    ## Timer data. Since reading and writing this value do different things,
                    ## it is accessed via the `count` and `start=` procs.
    
    freq* {.bitsize:3.}: TimerFreq   ## Frequency of the timer.
    
    _ {.bitsize:3.}: uint16
    
    irq* {.bitsize:1.}: bool    ## Enables the overflow interrupt for this timer.
                                ## When using the `irq` module you don't have to set this directly.
    
    active* {.bitsize:1.}: bool   ## Enables the timer and resets it to its `start` value.


var tmcnt* {.importc:"((volatile Timer*)(0x04000100))", nodecl.}: array[4, Timer]
  ## Array of timer data + control registers.


proc count*(timer: Timer): uint16 {.inline.} =
  ## Get the current value of the timer.
  timer.data

proc `start=`*(timer: var Timer, val: uint16) {.inline.} =
  ## Set the initial value of the timer.
  ## 
  ## The timer will reset to this value when it overflows
  ## or when the `active` bit is changed from `false` to `true`.
  timer.data = val


template init*(r: Timer, args: varargs[untyped]) =
  ## Initialise a timer with desired fields.
  ## 
  ## .. code-block:: nim
  ## 
  ##    # Set up timer 3 to overflow once per second.
  ##    
  ##    tmcnt[3].init(
  ##      freq = tf16kHz,
  ##      start = cast[uint16](-0x4000),  # 2^14 ticks at 16 kHz = 1 second
  ##      active = true,                  # Enable the timer.
  ##      irq = true,                     # Fire an interrupt when the timer overflows.
  ##    )
  ## 
  var tmp: Timer
  writeFields(tmp, args)
  r = tmp

template edit*(r: Timer, args: varargs[untyped]) =
  var tmp = r
  writeFields(tmp, args)
  r = tmp


# Timer
# -----

{.pragma: toncinl, header: "tonc_core.h".}  # indicates that the definition is in the header.

proc profileStart*() {.importc: "profile_start", toncinl.}
  ## Start a profiling run.
  ## 
  ## .. note::
  ##    Routine uses timers 2 and 3; if you're already using these somewhere, chaos is going to ensue.

proc profileStop*(): uint {.importc: "profile_stop", toncinl.}
  ## Stop a profiling run and return the time since its start.
  ## 
  ## Returns number of CPU cycles elapsed since `profileStart` was called.


from natu/private/common import natuPlatform

when natuPlatform == "gba":
  proc getPerfTimer*(): float64 {.error: "getPerfTimer not implemented for GBA platform.".}
  
elif natuPlatform == "sdl":
  import natu/private/sdl/applib
  proc getPerfTimer*(): float64 = natuMem.getPerfTimer()

else:
  {.error: "Unknown platform " & natuPlatform.}
