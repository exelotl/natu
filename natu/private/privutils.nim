import macros

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
