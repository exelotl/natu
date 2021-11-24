import macros

func isPowerOfTwo*(n: SomeInteger): bool {.inline.} =
  n > 0 and (n and (n-1)) == 0

func logPowerOfTwo*(n: uint): uint {.inline.} =
  ## Given that `n` is a power of two, return the power.
  ((n and 0xAAAAAAAA'u) != 0).uint or
    ((n and 0xCCCCCCCC'u) != 0).uint shl 1 or
    ((n and 0xF0F0F0F0'u) != 0).uint shl 2 or
    ((n and 0xFF00FF00'u) != 0).uint shl 3 or
    ((n and 0xFFFF0000'u) != 0).uint shl 4

macro writeFields*(obj: typed; args: varargs[untyped]) =
  ## Common implementation of `init`, `edit` and `dup` templates
  result = newStmtList()
  if args.len == 1 and args[0].kind == nnkStmtList:
    for i, node in args[0]:
      case node.kind
      of nnkCall, nnkCommand:
        node.insert(1, obj)
        result.add(node)
      of nnkAsgn:
        let (key, val) = (node[0], node[1])
        result.add quote do:
          `obj`.`key` = `val`
      else:
        error("Expected assignment, got " & repr(node))
  else:
    for i, node in args:
      case node.kind
      of nnkCall, nnkCommand:
        node.insert(1, obj)
        result.add(node)
      of nnkExprEqExpr:
        let (key, val) = (node[0], node[1])
        result.add quote do:
          `obj`.`key` = `val`
      else:
        error("Expected assignment, got " & repr(node))
