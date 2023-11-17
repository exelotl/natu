# Generate docs (this may be replaced by Sphinx?)

import strutils

rmDir "docs"

selfExec [
  "doc",
  "--project",
  "--index:on",
  "--git.url:https://github.com/exelotl/natu",
  "--git.commit:devel",
  "--outdir:docs",
  "--cpu:arm",
  "natu/docs.nim"
].join(" ")
