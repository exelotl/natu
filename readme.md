nim-tonc
========

This repo contains bindings for the awesome 'tonclib' GBA programming library by J. Vijn (cearn).



Goodies
-------
Some things that differ from the original tonclib:

- Pleasant fixed-point and 2D vector types (taking advantage of Nim features)
- mGBA logging functions


Usage
-----

You will need [devkitARM](https://devkitpro.org/wiki/Getting_Started) with GBA tools and libraries. Now download the [Tonc example code](https://www.coranac.com/projects/tonc/) and copy the tonclib folder to your devkitPro installation (e.g. C:\\devkitPro\tonclib).

For development you can use the standard devkitARM makefiles / project structure, so that Nim outputs C code into the 'source' directory. See `examples/helloworld`. Make sure to set `arm.standalone.gcc.path` in nim.cfg to be correct for your system.


Todo
----

- More examples and testing
- Generate documentation?
- Clean up `surface.nim`

