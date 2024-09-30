import macros

#[

The following call:
  
  printify(printf(), "x is {x} and y is {y}")

expands into:

  printifyImpl(printf("", "x is ", doFormat(x), " and y is ", doFormat(y)))

after the semantic pass becomes:

  printifyImpl(printf("", "x is ", ("%ld", x), " and y is ", ("%s", $y)))

which then expands into:

  printf("%s%ld%s%s", "x is ", x, " and y is ", $y)

]#

type
  PrintifyData = object
    start: int  # index at which format string begins.

template doFormat(a: typed): untyped =
  when a is SomeInteger:
    ("%ld", a)
  elif a is string or a is cstring:
    ("%s", a)
  else:
    ("%s", $a)

macro printifyImpl(call: typed; data: static[PrintifyData]) =
  echo repr(call)
  echo treeRepr(call)
  # let call = call.copy()
  var formatString = ""
  
  var src = call  # the node in which we're replacing tuples with bare args - usually this is the call itself ...
  var firstArg = data.start + 1
  var lastArg = call.len - 1
  
  if src[firstArg].kind == nnkHiddenStdConv:
    # ... but sometimes this junk is here so we have to go over an inner node instead.
    src = src[firstArg][1]
    firstArg = 0
    lastArg = src.len - 1
    echo "HUH"
    echo treeRepr(src)
  
  result = nnkCall.newTree()
  for i in 0..data.start:
    result.add(call[i])
  
  for i in firstArg..lastArg:
    case src[i].kind
    of nnkStrLit:
      formatString &= "%s"
      result.add(src[i])
    of nnkTupleConstr:
      if src[i][0].kind == nnkStrLit:
        formatString &= src[i][0].strVal
        result.add(src[i][1])
      else:
        error("Bad format node[0]", src[i][0])
    else:
      error("Bad format node", src[i])
  
  result[data.start].strVal = formatString
  echo repr(result)


macro printify*(call: untyped; str: static[string]) =
  
  if call.kind != nnkCall:
    error("printify expects a function call as it's first param, got: " & repr(call), call)
  
  proc cstr(s: string): NimNode =
    nnkStaticExpr.newTree(newCall(ident("cstring"), newStrLitNode(s)))
  
  var data = PrintifyData(start: call.len)
  
  let call = call.copy()
  call.add(cstr(""))    # add empty format specifier to be replaced.
  
  var curPart = ""
  var i = 0
  while i < str.len:
    let c = str[i]
    if c == '{':
      call.add cstr(curPart)
      curPart = ""
      inc i
      var d = str[i]
      while d != '}':
        curPart &= d
        inc i
        d = str[i]
      call.add newCall(bindSym"doFormat", parseExpr(curPart))
      curPart = ""
    else:
      curPart &= c
    inc i
  
  if curPart.len > 0:
    call.add cstr(curPart)
  
  let dataLit = newLit(data)
  result = newCall(bindSym"printifyImpl", call, newLit(data))


when isMainModule:
  
  proc printf*(frmt: cstring): cint {.importc: "printf", header: "<stdio.h>", varargs, discardable.}
  proc snprintf*(buf: cstring, n: csize_t, frmt: cstring): cint {.importc: "snprintf", header: "<stdio.h>", varargs, noSideEffect, discardable.}
  
  var x = 10
  var y = "Hi"
  var z = true
  
  # printify(printf(), "x is {x}, y is {y}, z is {z} bye!\n")
  
  template logf(s: static string) =
    printify(printf(), s & "\n")
  
  template snlog(buf: var openArray[char]; s: static string) =
    printify(snprintf(addr buf[0], buf.len.csize_t), s)
  
  logf "x is {x}, y is {y}, z is {z} bye!"
  
  var myArray: array[25, char]
  snlog myArray, "The {x} brown fox {y} over the lazy {z} bye!"
  
  echo cast[cstring](addr myArray)
  
