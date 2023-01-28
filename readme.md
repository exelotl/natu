<p align="center"><img width="200" src="https://user-images.githubusercontent.com/569607/85204175-8293f180-b30a-11ea-9fb0-66a502f740ba.png" alt="Natu GBA Logo"></p>

Natu is a package for making Game Boy Advance games in [Nim](https://nim-lang.org/).

Originally a wrapper for [libtonc](https://www.coranac.com/tonc/text/), we are now growing in our own direction: ditching some old conventions to be more Nim-friendly, and adding more libraries.

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

For docs and setup instructions go to [natu.exelo.tl](https://natu.exelo.tl)

The examples can be found at [git.sr.ht/~exelotl/natu-examples](https://git.sr.ht/~exelotl/natu-examples)

Happy coding! And if you need any help you can reach me (exelotl) on the [gbadev](https://discord.gg/2WS7bpJ) discord, `#natu` irc channel on EFnet, or ask a question on [the natu mailing list](https://lists.sr.ht/~exelotl/natu).

### Thanks

[tonc](https://www.coranac.com/tonc/text/) + libtonc by cearn  
[maxmod](https://maxmod.devkitpro.org/) sound system by mukunda johnson  
[libugba](https://github.com/AntonioND/libugba)'s interrupt handler by AntonioND
[ACSL](https://codeberg.org/pgimeno/ACSL)'s malloc/free by pgimeno
[mGBA](https://mgba.io/) by endrift  
[posprintf](http://www.danposluns.com/gbadev/posprintf/index.html) by dan posluns  
natu logo by [hot_pengu](https://twitter.com/hot_pengu), based on pixel art by [iamrifki](https://iamrifki.github.io/)  

<br>
<p align="right"><img width="40" src="https://user-images.githubusercontent.com/569607/85335282-a440d480-b4d4-11ea-9f7f-a48ae4726525.png" alt="Natu" title="noot noot!">&nbsp;</p>
