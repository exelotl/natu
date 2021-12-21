from ./private/utils import writeFields

type
  TimerFreq* = enum
    tf17MHz     ## 1 cycle per tick (16.78 Mhz)
    tf262kHz    ## 64 cycles per tick (262.21 kHz)
    tf66kHz     ## 256 cycles per tick (65.536 kHz)
    tf16kHz     ## 1024 cycles per tick (16.384 kHz)
    tfCascade   ## Timer ticks when the preceding timer overflows.
  
  Timer* {.bycopy, exportc.} = object
    ## Provides access to a timer data register and the corresponding timer control register.
    
    data: uint16    ## Timer data. Since reading and writing to this do different
                    ## things, it is accessed via the `count` and `start=` procs.
    
    freq* {.bitsize:3.}: TimerFreq   ## Frequency of the timer.
    _ {.bitsize:3.}: uint16
    irq* {.bitsize:1.}: bool         ## Enables the overflow interrupt for this timer.
    active* {.bitsize:1.}: bool      ## Enables the timer. 


var tmcnt* {.importc:"((volatile Timer*)(0x04000100))", nodecl.}: array[4, Timer]
  ## Array of timer data + control registers.


proc count*(timer: Timer): uint16 {.inline.} =
  ## Get the value of the timer.
  timer.data

proc `reset=`*(timer: var Timer, val: uint16) {.inline.} =
  ## Set the initial value for the next timer run.
  ## 
  ## The timer will reset to this value when it overflows
  ## or when the `active` bit changes from `false` to `true`.
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
  ##      reset = cast[uint16](-0x4000),  # 2^14 ticks at 16 kHz = 1 second
  ##      active = true,                  # Enable the timer.
  ##    )
  ## 
  var tmp: Timer
  writeFields(tmp, args)
  r = tmp

template edit*(r: Timer, args: varargs[untyped]) =
  var tmp = r
  writeFields(tmp, args)
  r = tmp
