import ./panics

{.push stackTrace:off, profiler:off.}

when defined(nimHasExceptionsQuery):
  const gotoBasedExceptions = compileOption("exceptions", "goto")
else:
  const gotoBasedExceptions = false

template sysFatal(exceptn: typedesc, message: string|cstring) =
  when nimvm:
    raise (ref exceptn)(msg: message)
  else:
    panic(message)

template sysFatal(exceptn: typedesc, message, arg: string|cstring) =
  when nimvm:
    raise (ref exceptn)(msg: message & arg)
  else:
    panic(message, arg)

{.pop.}
