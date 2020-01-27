<p align="center"><img width="98" height="76" src="https://user-images.githubusercontent.com/569607/72299597-32c54600-3659-11ea-807f-0b1b0b3ad7c6.png" alt="Natu GBA Logo"></p>

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

### Usage

You will need [devkitARM](https://devkitpro.org/wiki/Getting_Started) with GBA tools and libraries. If you are using the graphical installer, simply check "tools for GBA development" during setup. Otherwise be sure to install the `gba-dev` group of packages. Either way, the libtonc package is included so you should be good to go!

Before diving into Nim, try building some of the Tonc 'advanced' demos to make sure your environment is good.

The examples in this repo each use a _nimscript_ configuration which should make a good starting point for any project. From within an example you can run `nim build` in the terminal to produce a GBA rom.

Happy coding! And if you need any help you can reach me (@exelotl) on the [gbdev discord](https://discord.gg/gpBxq85).

### Thanks

[tonc](https://www.coranac.com/tonc/text/) + libtonc by cearn  
[devkitARM](https://devkitpro.org/) toolchain maintained by wintermute  
[maxmod](https://maxmod.devkitpro.org/) sound system by mukunda johnson  
[mGBA](https://mgba.io/) by endrift  
gba logo by [iamrifki](https://iamrifki.github.io/)  
font: [gelatin mono](https://lorenschmidt.itch.io/gelatin-mono) by loren schmidt  

<img src="https://img.pokemondb.net/sprites/ruby-sapphire/normal/natu.png" alt="Natu" title="noot noot!">