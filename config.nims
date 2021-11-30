import strutils

--cpu:arm

task docs, "build docs":
  rmDir "docs"
  selfExec [
    "doc",
    "--project",
    "--index:on",
    "--git.url:https://github.com/exelotl/natu",
    "--git.commit:devel",
    "--outdir:docs",
    "natu/docs.nim"
  ].join(" ")
  
