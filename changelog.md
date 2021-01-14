# Changelog

## [0.1.2] - 2021-01-14

- `fp` is now available as a shorthand for constructing a 24:8 fixed point number.
  - E.g. `fp(1.5)` instead of `fixed(1.5)`
- `{.codegenDecl:IWRAM_CODE.}` now includes the `target("arm")` gcc attribute.
  - This ensures that ARM code instead of Thumb code is produced for functions in IWRAM.
- Some text functions are less picky about parameters.
  - `ttePutc` now takes `char|int`, not just `int`.
  - Color attribute getters/setters (`ink`, `shadow` etc.) now accept a non-ptr TTE context.
- `init` and `edit` macros now work with more registers (`bgofs`, `bgaff`, `winXXXcnt`, `winXh/v`, `bldcnt`)
- Write-only protections have been removed from `bgofs` registers until I find a solution with better semantics.
- `maxmod.effect` and `maxmod.effectEx` are now discardable again.

## [0.1.1] - 2020-06-30

The dark days, before this file existed...
