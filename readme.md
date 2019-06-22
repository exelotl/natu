nim-tonc
========

This repo contains Nim bindings for the awesome libtonc by J. Vijn (cearn).

Libtonc provides everything you need to program the Game Boy Advance, and is the accompanying material to [Tonc](https://www.coranac.com/tonc/text/toc.htm) which is the de-facto tutorial for GBA development.

### Features

- Full GBA memory map + flag definitions
- BIOS routines
- Interrupt manager
- A very powerful text system
- Surfaces (draw to tiles like a canvas)
- Efficient copy routines
- Random number generator
- Sin/Cos/Div LUTs + other math functions
- Hardware sprites, affine matrix helpers
- Color/palette utilities
- Button states (hit, down, released)

### Goodies

Some things that differ from the original libtonc:

- Pleasant fixed-point and 2D vector types (taking advantage of Nim features)
- mGBA logging functions

### Usage

You will need [devkitARM](https://devkitpro.org/wiki/Getting_Started) with GBA tools and libraries. If you are using the graphical installer, simply check "tools for GBA development" during setup. Otherwise be sure to install the `gba-dev` group of packages. Either way, the libtonc package is included so you should be good to go!

Before diving into Nim, try building some of the Tonc 'advanced' demos to make sure your environment is good.

For developing with Nim you can use the standard devkitARM makefiles / project structure, but modified to use libtonc instead of libgba. In your project's `nim.cfg` you should target ARM CPU, 'standalone' OS, disable runtime checks, and set it to output C code into the 'source' directory. Check the examples in this repo for how this is done.

### Todo

- More examples and testing
- Generate documentation?
- Clean up `surface.nim`
- Maxmod bindings
