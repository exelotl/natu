{.push stackTrace:off, profiler:off.}

proc natuPanic(msg1: cstring; msg2: cstring = nil) {.importc, noreturn.}

const
  gotoBasedExceptions = compileOption("exceptions", "goto")
  quirkyExceptions = compileOption("exceptions", "quirky")

template sysFatal(exceptn: typedesc, message: string|cstring) =
  when nimvm:
    raise (ref exceptn)(msg: message)
  else:
    natuPanic(message)

template sysFatal(exceptn: typedesc, message, arg: string|cstring) =
  when nimvm:
    raise (ref exceptn)(msg: message & arg)
  else:
    natuPanic(message, arg)

{.pop.}
