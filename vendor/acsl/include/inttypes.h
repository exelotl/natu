/*
 * inttypes.h implementation for GBA
 *
 * (C) Copyright 2021 Pedro Gimeno Fortea
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
 * IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 *
 */
#ifndef __INCLUDED_INTTYPES_H__
#define __INCLUDED_INTTYPES_H__

#include <stdint.h>

#define PRId8       "hhd"
#define PRId16       "hd"
#define PRId32        "d"
#define PRId64      "lld"
#define PRIi8       "hhi"
#define PRIi16       "hi"
#define PRIi32        "i"
#define PRIi64      "lli"
#define PRIo8       "hho"
#define PRIo16       "ho"
#define PRIo32        "o"
#define PRIo64      "llo"
#define PRIu8       "hhu"
#define PRIu16       "hu"
#define PRIu32        "u"
#define PRIu64      "llu"
#define PRIx8       "hhx"
#define PRIx16       "hx"
#define PRIx32        "x"
#define PRIx64      "llx"
#define PRIX8       "hhX"
#define PRIX16       "hX"
#define PRIX32        "X"
#define PRIX64      "llX"
#define PRIdLEAST8  "hhd"
#define PRIdLEAST16  "hd"
#define PRIdLEAST32   "d"
#define PRIdLEAST64 "lld"
#define PRIiLEAST8  "hhi"
#define PRIiLEAST16  "hi"
#define PRIiLEAST32   "i"
#define PRIiLEAST64 "lli"
#define PRIoLEAST8  "hho"
#define PRIoLEAST16  "ho"
#define PRIoLEAST32   "o"
#define PRIoLEAST64 "llo"
#define PRIuLEAST8  "hhu"
#define PRIuLEAST16  "hu"
#define PRIuLEAST32   "u"
#define PRIuLEAST64 "llu"
#define PRIxLEAST8  "hhx"
#define PRIxLEAST16  "hx"
#define PRIxLEAST32   "x"
#define PRIxLEAST64 "llx"
#define PRIXLEAST8  "hhX"
#define PRIXLEAST16  "hX"
#define PRIXLEAST32   "X"
#define PRIXLEAST64 "llX"
#define PRIdFAST8     "d"
#define PRIdFAST16    "d"
#define PRIdFAST32    "d"
#define PRIdFAST64  "lld"
#define PRIiFAST8     "i"
#define PRIiFAST16    "i"
#define PRIiFAST32    "i"
#define PRIiFAST64  "lli"
#define PRIoFAST8     "o"
#define PRIoFAST16    "o"
#define PRIoFAST32    "o"
#define PRIoFAST64  "llo"
#define PRIuFAST8     "u"
#define PRIuFAST16    "u"
#define PRIuFAST32    "u"
#define PRIuFAST64  "llu"
#define PRIxFAST8     "x"
#define PRIxFAST16    "x"
#define PRIxFAST32    "x"
#define PRIxFAST64  "llx"
#define PRIXFAST8     "X"
#define PRIXFAST16    "X"
#define PRIXFAST32    "X"
#define PRIXFAST64  "llX"
#define PRIdMAX     "lld"
#define PRIiMAX     "lli"
#define PRIoMAX     "llo"
#define PRIuMAX     "llu"
#define PRIxMAX     "llx"
#define PRIXMAX     "llX"
#define PRIdPTR       "d"
#define PRIiPTR       "i"
#define PRIoPTR       "o"
#define PRIuPTR       "u"
#define PRIxPTR       "x"
#define PRIXPTR       "X"

intmax_t strtoimax(const char *restrict nptr, char **restrict endptr,
  int base);
uintmax_t strtoumax(const char *restrict nptr, char **restrict endptr,
  int base);

#endif // __INCLUDED_INTTYPES_H__
