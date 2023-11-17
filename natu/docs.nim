##
## Welcome to the Natu API docs, they're a bit rough right now...
## 
## **Modules:**
## 
## - `utils <utils.html>`_ ⸺ 
## - `bios <bios.html>`_ ⸺ GBA system calls.
## - `irq <irq.html>`_ ⸺ Hardware interrupt manager.
## - `input <input.html>`_ ⸺ Button input handler.
## - `waitstates <waitstates.html>`_ ⸺ Waitstate control.
## - `video <video.html>`_ ⸺ Display, BGs, sprites, colours and graphical effects.
## - `surface <surface.html>`_ ⸺ Software rendering surfaces.
## - `posprintf <posprintf.html>`_ ⸺ Fast number-to-string conversion.
## - `tte <tte.html>`_ ⸺ Tonc Text Engine
## - `mgba <mgba.html>`_ ⸺ mGBA debug logging
## - `maxmod <maxmod.html>`_ ⸺ Music and sound library
## - `legacy <legacy.html>`_ ⸺ Old C constants.

import std/compilesettings

when querySetting(command) in ["doc", "jsondoc"]:
  import utils
  import bios
  import irq
  import input
  import waitstates
  import video
  import surface
  import timers
  import posprintf
  import tte
  import mgba
  import maxmod
  import legacy

else:
  {.error:"This module is for doc gen only.".}