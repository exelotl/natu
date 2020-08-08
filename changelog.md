# Changelog

## [0.1.2] - Unreleased

- `fp` is now available as a shorthand for constructing a 24:8 fixed point number. E.g. `fp(1.5)` instead of `fixed(1.5)`
- `{.codegenDecl:IWRAM_CODE.}` now includes the `target("arm")` gcc attribute. This ensures that ARM code instead of Thumb code is produced for functions in IWRAM.
