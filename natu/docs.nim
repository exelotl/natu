##
## Welcome to the Natu API docs, they're a bit rough right now...
## 

import std/compilesettings

when querySetting(command) == "doc":
  import core
  import bios
  import irq
  import input
  import waitstates
  import video
  import oam
  import surface
  import posprintf
  import tte
  import mgba
  import maxmod
  import legacy

else:
  {.error:"This module is for doc gen only.".}