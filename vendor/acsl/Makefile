#
# Makefile for GBA library
#
# (C) Copyright 2021 Pedro Gimeno Fortea
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

all: libacsl.a

# Possible compilation options (separated with commas or semicolons):
#  FLOAT_FORMAT  - includes the floating-point string formatting support
# example: make check OPTIONS=FLOAT_FORMAT
OPTIONS :=


override _comma := ,
override _OPTS := ;$(subst $(_comma),;,$(OPTIONS));
#override _space := $() $()
#override _OPTS := $(subst $(_space),;,$(_OPTS))

# ACSL objects
OBJECTS := acsl/crt0.o acsl/bluescreen.o acsl/render_text.o acsl/retzero.o\
 acsl/tenpowers.o

# stdlib.h objects
OBJECTS += stdlib/malloc_free.o stdlib/calloc.o stdlib/realloc.o\
 stdlib/exit.o stdlib/abort.o stdlib/setjmp.o stdlib/errno.o\
 stdlib/rand_srand.o stdlib/abs.o stdlib/llabs.o stdlib/div.o stdlib/ldiv.o\
 stdlib/lldiv.o stdlib/strtoany.o stdlib/strtol.o stdlib/strtoul.o\
 stdlib/strtoll.o stdlib/strtoull.o stdlib/strtod.o stdlib/strtof.o

# string.h objects
OBJECTS += string/memcpy.o string/memset.o string/strlen.o string/strchr.o\
 string/strerror.o string/strcmp.o string/memcmp.o string/memmove.o\
 string/memchr.o string/strcpy.o string/strncpy.o string/strcpy.o\
 string/strcat.o string/strncat.o string/strncmp.o string/strspn.o\
 string/strstr.o string/strtok.o

# stdio.h objects
OBJECTS += stdio/sprintf.o stdio/snprintf.o stdio/stdio_partialimp.o\
 stdio/stdio_unimplemented.o stdio/stdio_vars.o stdio/formatstr.o\
 stdio/perror.o

# math.h objects
OBJECTS += math/fabs.o math/fabsf.o math/isnant.o math/isnanft.o math/isnana.o\
 math/isnanfa.o math/copysign.o math/copysignf.o math/nan.o math/nanf.o\
 math/ldexp.o math/ldexpf.o

# ctype.h objects
OBJECTS += ctype/tolower_toupper.o ctype/isxxxx.o

# wchar.h objects
OBJECTS += wchar/wcslen.o

B_CFLAGS := -O3 -mcpu=arm7tdmi -mthumb -nostdinc -Iinclude -ffast-math\
 -fomit-frame-pointer -ffunction-sections $(CFLAGS)

B_LDFLAGS := --specs=gba.specs -L. -T gba.ld -Wl,--gc-sections $(LDFLAGS)

B_ASFLAGS := -Iasminc $(ASFLAGS)

ARM := arm-none-eabi-

OBJCOPY := $(ARM)objcopy
CC := $(ARM)gcc
LD := $(ARM)ld
AR := $(ARM)gcc-ar
AS := $(ARM)as
LUA := lua
PYTHON := python

-include local.mk


stdio/formatstr.o: stdio/formatstr.s asminc/float_fmt.inc
ifeq ($(findstring ;FLOAT_FORMAT;,$(_OPTS)),)
	$(AS) $(B_ASFLAGS) -o $@ $<
else
	$(AS) --defsym WITH_FLOAT_FORMATTING=1 $(B_ASFLAGS) -o $@ $<
endif

%.o: %.S
	$(AS) $(B_ASFLAGS) -o $@ $<

%.o: %.s
	$(AS) $(B_ASFLAGS) -o $@ $<

%.o: %.c
	$(CC) $(B_CFLAGS) -c -o $@ $^

%.s: %.c
	$(CC) $(B_CFLAGS) -c -S -o $@ $^

libacsl.a: $(OBJECTS)
	$(AR) rcvs $@ $?
# $? means to list only modified files from those in the input list

%.elf: %.o libacsl.a
	$(CC) $(B_LDFLAGS) -o $@ $<

%.gba: %.elf
	$(OBJCOPY) -O binary $< $@
	$(LUA) patch-cksum.lua $@ || { rm -f $@ && false; }

check: tests/testmem.gba tests/linktest.gba tests/test-strtol.gba\
 tests/test-strtod.gba tests/test-roundtrip.gba tests/test-ldexp.gba

tests/test-strtol.o: tests/test-strtol.c
	$(CC) $(B_CFLAGS) -O0 -c -o $@ $^

clean:
	for i in o elf gba; do for j in testmem example test-strtol test-strtod; do rm -f "tests/$$j.$$i"; done; done
	rm -f $(OBJECTS) libacsl.a

.PRECIOUS: %.o %.elf

.PHONY: all clean
