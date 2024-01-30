#[
Based on code from Nim's runtime library

Copyright (C) 2006-2023 Andreas Rumpf. All rights reserved.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.
]#

import std/strutils

type
  LibHandle* = pointer ## A handle to a dynamically loaded library.

proc loadLib*(path: string, globalSymbols = false): LibHandle {.gcsafe.}
  ## Loads a library from `path`. Returns nil if the library could not
  ## be loaded.

proc loadLib*(): LibHandle {.gcsafe.}
  ## Gets the handle from the current executable. Returns nil if the
  ## library could not be loaded.

proc unloadLib*(lib: LibHandle) {.gcsafe.}
  ## Unloads the library `lib`.

proc raiseInvalidLibrary*(name: cstring) {.noinline, noreturn.} =
  ## Raises a `LibraryError` exception.
  raise newException(LibraryError, "could not find symbol: " & $name)

proc symAddr*(lib: LibHandle, name: cstring): pointer {.gcsafe.}
  ## Retrieves the address of a procedure/variable from `lib`. Returns nil
  ## if the symbol could not be found.

proc checkedSymAddr*(lib: LibHandle, name: cstring): pointer =
  ## Retrieves the address of a procedure/variable from `lib`. Raises
  ## `LibraryError` if the symbol could not be found.
  result = symAddr(lib, name)
  if result == nil: raiseInvalidLibrary(name)

proc libCandidates*(s: string, dest: var seq[string]) =
  ## Given a library name pattern `s`, write possible library names to `dest`.
  var le = strutils.find(s, '(')
  var ri = strutils.find(s, ')', le+1)
  if le >= 0 and ri > le:
    var prefix = substr(s, 0, le - 1)
    var suffix = substr(s, ri + 1)
    for middle in split(substr(s, le + 1, ri - 1), '|'):
      libCandidates(prefix & middle & suffix, dest)
  else:
    add(dest, s)

proc loadLibPattern*(pattern: string, globalSymbols = false): LibHandle =
  ## Loads a library with name matching `pattern`, similar to what the `dynlib`
  ## pragma does. Returns nil if the library could not be loaded.
  ##
  ## .. warning:: this proc uses the GC and so cannot be used to load the GC.
  var candidates = newSeq[string]()
  libCandidates(pattern, candidates)
  for c in candidates:
    result = loadLib(c, globalSymbols)
    if not result.isNil: break

#
# =======================================================================
# Native Windows Implementation
# =======================================================================
#
type
  HMODULE = pointer
  FARPROC = pointer

proc GetProcAddress(lib: HMODULE, name: cstring): FARPROC {.importc, stdcall.}
proc FreeLibrary(lib: HMODULE) {.importc, stdcall.}
proc LoadLibraryA(path: cstring): HMODULE {.importc, stdcall.}

proc loadLib(path: string, globalSymbols = false): LibHandle =
  result = cast[LibHandle](LoadLibraryA(path))
proc loadLib(): LibHandle =
  result = cast[LibHandle](LoadLibraryA(nil))
proc unloadLib(lib: LibHandle) = FreeLibrary(cast[HMODULE](lib))

proc symAddr(lib: LibHandle, name: cstring): pointer =
  result = cast[pointer](GetProcAddress(cast[HMODULE](lib), name))
