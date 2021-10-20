macro `'fp`*(s: static string): Fixed =
  ## Suffix for fixed point numeric literal, e.g: `22.5'fp` is equivalent to `fixed(22.5)`
  ## 
  ## Requires Nim >= 1.6.0.
  var f: float
  if parseFloat(s, f) == 0:
    error(s & "'fp is not a fixed point literal.")
  newCall(bindSym("fixed"), newFloatLitNode(f))
