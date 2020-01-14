## mGBA Debug Logging
## ==================
## Output text to the debug console in mGBA

# Adapted from https://github.com/mgba-emu/mgba/tree/master/opt/libgba
# Which is subject to the license below:
#[
 Copyright (c) 2016 Jeffrey Pfau
 Redistribution and use in source and binary forms, with or without modification,
 are permitted provided that the following conditions are met:
  1. Redistributions of source code must retain the above copyright notice,
     this list of conditions and the following disclaimer.
  2. Redistributions in binary form must reproduce the above copyright notice,
     this list of conditions and the following disclaimer in the documentation and/or
     other materials provided with the distribution.
 THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR IMPLIED
 WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY
 AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE
 LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,
 EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
]#

{.emit: """/*INCLUDESECTION*/
#include <stdarg.h>
#include <stdio.h>
#include <tonc_types.h>

#define REG_DEBUG_ENABLE *(vu16*)0x4FFF780
#define REG_DEBUG_FLAGS *(vu16*)0x4FFF700
#define REG_DEBUG_STRING *(char*)0x4FFF600

void mgba_printf(int level, const char* str, ...);
void mgba_printf_default(const char* str, ...);
""".}

{.emit: """/*TYPESECTION*/
void mgba_printf(int level, const char* str, ...) {
  level &= 0x7;
  va_list args;
  va_start(args, str);
  vsnprintf(&REG_DEBUG_STRING, 0x100, str, args);
  va_end(args);
  REG_DEBUG_FLAGS = level | 0x100;
}
// Log at 'WARN' level since those are visible by default in mGBA log window
void mgba_printf_default(const char* str, ...) {
  va_list args;
  va_start(args, str);
  vsnprintf(&REG_DEBUG_STRING, 0x100, str, args);
  va_end(args);
  REG_DEBUG_FLAGS = 2 | 0x100;
}
""".}


var REG_DEBUG_ENABLE {.importc:"REG_DEBUG_ENABLE", nodecl.}: uint16
# var REG_DEBUG_FLAGS {.importc:"REG_DEBUG_FLAGS", nodecl.}: uint16
# var REG_DEBUG_STRING {.importc:"REG_DEBUG_STRING", nodecl.}: cstring

type LogLevel* {.size: sizeof(cint).} = enum
  LOG_FATAL = 0
  LOG_ERROR = 1
  LOG_WARN = 2
  LOG_INFO = 3
  LOG_DEBUG = 4

proc open*(): bool {.discardable.} =
  REG_DEBUG_ENABLE = 0xC0DE
  return (REG_DEBUG_ENABLE == 0x1DEA)

proc close*() =
  REG_DEBUG_ENABLE = 0

proc printf*(level:LogLevel, str:cstring) {.importc: "mgba_printf", varargs.}
proc printf*(str:cstring) {.importc: "mgba_printf_default", varargs.}


# Attempting to implement in pure Nim:


# Works but not very useful because `&` and `fmt` don't work

# proc log*(str:cstring) =
#   copyMem(addr REG_DEBUG_STRING, str, 0x100)
#   REG_DEBUG_FLAGS = ord(LOG_WARN) or 0x100


# Doesn't work due to missing `copyString`

# proc log*(args: varargs[string]) =
#   var i = 0
#   for str in args:
#     var j = 0
#     while str[j] != '\0' and i < 256:
#       REG_DEBUG_STRING[i] = str[j]
#       inc i
#       inc j
#   REG_DEBUG_FLAGS = ord(LOG_WARN) or 0x100
    