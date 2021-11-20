ACSL - Advance C Small Library
==============================

This directory contains the implementations of `malloc` / `free` / `realloc` / `calloc` from ACSL by pgimeno. See [here for the full library](https://codeberg.org/pgimeno/ACSL).

This is used by Natu because the default malloc implementation from newlib is pretty wasteful, eating [1KB of IWRAM](https://github.com/devkitPro/newlib/blob/a60a4501b77dca8f30e01327b96171ee89c278f7/newlib/libc/stdlib/mallocr.c#L1597).

To make it work under devkitARM, the only change needed to make was to begin the heap from `__sbss_end__` instead of `__bss_end__`.
