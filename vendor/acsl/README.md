## ACSL - Advance C Small Library

This is an implementation of a C99 library designed for the Game Boy Advance (hence "Advance" in the name, not "advanced").

A good part of it is implemented in assembler.

The "S" in "ACSL" may change meaning in future. At the moment it stands for "small" in that it doesn't cover the whole C standard library.

This library is work in progress, but it's in a usable state if you don't need any of the functions that are pending to be implemented (most notably, `sscanf` and most of `math.h` functions).

### Documentation

Quirks of this library are:

- Allocation is 32-bit granular, i.e. alignment of pointers is 4 bytes. `malloc` (and `calloc`) uses one extra word per allocation for internal memory management.
- There is no run-time console; displaying a message to standard output or error causes the program to change mode, display the message and terminate.
- File functions are in general not implemented and will terminate the program if invoked. A few functions (e.g. `fwrite`, `fprintf`) work as described in the previous point if the stream is `stdout` or `stderr`. `setbuf` and `setvbuf` do nothing at all, not even checking the arguments; `setvbuf` will always return 0.
- Wide strings work mostly like char strings, in that only the lowest significant byte is used. Similarly for wide chars vs chars.
- The current PRNG is SFC32, by Chris Doty-Humphrey, but it's likely to change in future.
- `memcpy` copies words whenever possible. This may cause trouble with certain devices - apparently some kind of SRAM does not support reading unless it's byte by byte.
- Include files need a bit more work; for example, currently `string.h` pulls the whole `stdlib.h` in order to include support for `NULL` and `size_t`. Some guards against previously defined symbols are also missing, as is `__STDC_xx__` stuff.

#### The formatting functions

Compilation of support for `%e`, `%E`, `%f`, `%F`, `%g`, `%G` is optional, through the `make` variable `OPTIONS=FLOAT_FORMAT`. By default it is off, and they display e.g. `%e` literally. The formatting routines currently take:

- With float support:
  - 3694 bytes of ROM
  - 3270 more bytes of ROM in a table shared with `strtod`
  - 580 bytes of IWRAM
- Without float support:
  - 2196 bytes of ROM
  - 368 bytes of IWRAM

They are always compiled in, even if not used, because the error reporting system depends on them.

Floats don't follow the recommendation that the result is exact when more decimals than the precision are requested; that's because, for memory and performance reasons, the algorithm used produces between 18 and 20 decimal digits, so the rest are always zero-padded. Fortunately, 18 digits are (just) enough for round-tripping of double-precision floats; it's well known that converting a double to decimal and then back to double is lossless if there is proper rounding and 17 or more significant digits are used.

The `'` POSIX modifier is supported but it always outputs commas, as there's no locale support or plans to add it. A future plan is to have two char variables, one with the decimal point and the other with the thousands separator, for use in formatting functions.

The `n$` POSIX argument selector works somewhat, but if the arguments contain double word values, it will probably not work as expected due to the alignment requirements of AAPCS. You need to manually skip padding words that are inserted by the compiler due to alignment, and the second word of double word values. That applies to long long and float/double arguments, for example. In general, it's best to avoid this feature if you don't have a pressing need for it.

#### The `strto*` functions

`strtol` and `strtoul` have fast-track code for decimal and octal, but not for hexadecimal. `strtoll` and `strtoull` don't have any fast-track code.

`strtof` just invokes `strtod` and converts the result, which implies that there's a double rounding.

The decimal part of `strtod` uses 64 bits internally for the conversion, which is insufficient for proper rounding. Still, `strtod` and `sprintf` round-trip as they should.

`strtod` uses the same 3270-byte ten powers table as the decimal float formatting function.

### Building

The requisites are: the `arm-none-eabi-*` toolchain (gcc and binutils) and GNU make. It should work out of the box, for example, in Debian after installing `gcc-arm-none-eabi`, `binutils-arm-none-eabi` and `make`. In order to build `.gba` executables, including the test programs, Lua is also necessary (any version of Lua >= 5.0 should work). The ten powers table in `asminc/float2dec_table.inc` does not need to be regenerated, but if it has to be for some reason, Python will also be necessary in order to run `pow10_generator.py`, which works with both Python 2.7 and 3.5 (probably with any Python 3 version).

To build, run:

    make OPTIONS=FLOAT_FORMAT

The result is a `libacsl.a` static library file. Compiling single-file programs inside the library folder works; just run `make <your_C_program>.gba`.

To build the test programs (`linktest.gba`, `testmem.gba` and the several `test-*.gba`), run `make check`. Note that `linktest.gba` is not meant to be run; its purpose is to verify that no symbol dependencies are missing. Usage of `testmem.gba` is as follows: press `start` to step through one test at a time, and `select` to run all tests without stopping. At the end, the screen will show either a green band (if all tests passed) or a red band (if any test failed). The others will show messages according to the result, e.g. `* PASS` when they pass.

### Usage

Once you have built `libacsl.a`, you need to tell `gcc` to use it at link time, and you also need to tell it to pass the included `gba.ld` linker script to the `ld` linker.

To do that, pass the following options to `gcc` (or however your cross-compiler is called, for example `arm-none-eabi-gcc`) at link time (`LDFLAGS`), replacing `/dir/of/acsl/` with the path where ACSL was compiled:

    --specs=/dir/of/acsl/gba.specs -L/dir/of/acsl/ -T/dir/of/acsl/gba.ld -Wl,--gc-sections

and the following options at compilation time (`CFLAGS`):

    -nostdinc -isystem /dir/of/acsl/include

The `-Wl,--gc-sections` is used to remove unused sections from the output. This is done to reduce the final executable size, because some files declare multiple functions but in different sections, and without this option, all of them would be included in the executable even if unused. It's also recommendable to use gcc's `-ffunction-sections` for your code, because that will also remove unused functions. Remember that the executable is the `.gba` file, not the `.elf`; using `-ffunction-sections` may make the `.elf` grow in size, but not the `.gba` file.

### License

The license is ISC. `setjmp.s` is a modified version of a third-party file by Nick Clifton licensed under a BSD 3-clause license; see `stdlib/setjmp.s` for details. `font5x8.bin` is a modified version of a font by Rami Sabbagh licensed under the Expat license; check the file LICENSE.md for details.
