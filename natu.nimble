version       = "0.2.0"
author        = "exelotl"
description   = "Game Boy Advance development library"
license       = "zlib"
installExt    = @["nim"]
installDirs   = @["vendor"]
skipDirs      = @["examples"]
bin           = @["natu", "mmutil"]

requires "nim >= 1.4.2"
requires "trick >= 0.1.6"
requires "sdl2_nim"
requires "nxmp"
requires "riff"

