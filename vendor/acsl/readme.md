ACSL - Advance C Small Library
==============================

This directory contains the implementations of `malloc` / `free` / `realloc` / `calloc`
from ACSL by pgimeno. See [here for the full library](https://codeberg.org/pgimeno/ACSL).

I started using this in Natu because the default malloc implementation from newlib is pretty wasteful,
eating [1KB of IWRAM](https://github.com/devkitPro/newlib/blob/a60a4501b77dca8f30e01327b96171ee89c278f7/newlib/libc/stdlib/mallocr.c#L1597).

Now I've ditched newlib this library is actually essential, at least for projects using [`--mm:arc`](https://nim-lang.org/docs/nimc.html#nim-for-embedded-systems).

To make it work with AntonioND's linker script we just need to begin the heap at `__HEAP_START__` instead of `__bss_end__`.
Alternatively if you were trying to make it work with devkitPro's linker script you'd use `__sbss_end__` instead.
