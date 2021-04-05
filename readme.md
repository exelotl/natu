NOTE! Nim and dkP's libtonc don't work together due to conflicing definitions of `bool`.

This is fixed in the **devel** branch of Natu, so it's recommended to use that for now.

Quickstart: After installing [devkitARM](https://devkitpro.org/wiki/Getting_Started) and [Nim](https://nim-lang.org/):

```sh
git clone https://github.com/exelotl/natu
cd natu
git checkout devel               # switch to devel branch
git submodule update --init      # clone libtonc and maxmod submodules
nimble develop                   # symlink the repo to your ~/.nimble directory
cd examples/hello_world          # go to an example
nim build                        # run the build nimscript task
```

---

<p align="center"><img width="200" src="https://user-images.githubusercontent.com/569607/85204175-8293f180-b30a-11ea-9fb0-66a502f740ba.png" alt="Natu GBA Logo"></p>

Natu is a package for making Game Boy Advance games in [Nim](https://nim-lang.org/).

Primarily a wrapper for [libtonc](https://www.coranac.com/tonc/text/), we are now growing in our own direction: ditching some old conventions to be more Nim-friendly, and adding more libraries.

### Features

- Full GBA memory map + flag definitions
- BIOS routines
- Interrupt manager
- A powerful text system (TTE)
- Surfaces (draw to tiles like a canvas)
- Efficient copy routines
- Sin/Cos/Div LUTs + other math functions
- Fixed-point numbers, 2D vector types
- Random number generator
- Hardware sprites, affine matrix helpers
- Color/palette utilities
- Button states (hit, down, released)
- mGBA logging functions
- Maxmod bindings for music/sfx
- Posprintf wrapper for string formatting

### Usage

You will need [devkitARM](https://devkitpro.org/wiki/Getting_Started) with GBA tools and libraries. If you are using the graphical installer, simply check "tools for GBA development" during setup. Otherwise be sure to install the `gba-dev` group of packages. Either way, the libtonc package is included so you should be good to go!

Before diving into Nim, try building some of the Tonc 'advanced' demos to make sure your environment is good.

The examples in this repo each use a _nimscript_ configuration which should make a good starting point for any project. From within an example you can run `nim build` in the terminal to produce a GBA rom.

Happy coding! And if you need any help you can reach me (exelotl) on the [gbadev](https://discord.gg/2WS7bpJ) discord.

### Thanks

[tonc](https://www.coranac.com/tonc/text/) + libtonc by cearn  
[devkitARM](https://devkitpro.org/) toolchain maintained by wintermute  
[maxmod](https://maxmod.devkitpro.org/) sound system by mukunda johnson  
[mGBA](https://mgba.io/) by endrift  
[posprintf](http://www.danposluns.com/gbadev/posprintf/index.html) by dan posluns  
natu logo by [hot_pengu](https://twitter.com/hot_pengu), based on pixel art by [iamrifki](https://iamrifki.github.io/)  

<br>
<p align="right"><img width="40" src="https://user-images.githubusercontent.com/569607/85335282-a440d480-b4d4-11ea-9f7f-a48ae4726525.png" alt="Natu" title="noot noot!">&nbsp;</p>
