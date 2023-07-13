#
# Powers-of-ten table generator for GBA C library
#
# (C) Copyright 2021 Pedro Gimeno Fortea
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR
# IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

# This program was used to generate asminc/float2dec_table.inc and does not
# need to be run again in principle.

import sys
import math

def write(*s):
  for i in s:
    sys.stdout.write(i)


def tableEntry(tenPower):
  if tenPower >= 0:
    N = 2**2400 * 64 *  (10 ** +tenPower)
  else:
    N = 2**2400 * 64 // (10 ** -tenPower)
  binN = bin(N)
  digits = len(binN)-2-1 - 2400
  round = 0
  if binN[65] == '1':
    if (binN[64] == '1'  # parity bit
        or int(binN[66:],2) != 0):  # no tie, > 0.5
      round = 1  # round up
  N64 = (int(binN[:65], 0) + round) << 1  # remove least significant bit
  nextN = 2**2400*64
  nextN = nextN*10**(2+tenPower) if 2+tenPower>=0 else nextN//10**-(2+tenPower)
  nextDigits = len(bin(nextN))-2-1 - 2400
  assert nextDigits - digits in {6,7}
  #write("%d\n" % (nextDigits-digits-6))
  N64 += nextDigits - digits - 6
  return N64, digits


for passno in range(2):
  e = 0
  write("\n")
  # Preface
  for i in range(-344, -324, 2):
    if passno == 0:
      # Print table with ten even powers of 10 < 10**-324
      write("\t\t.8byte\t0x%X\n" % tableEntry(i)[0])
    else:
      # Print table with ten biased 2exps corresponding to the above entries
      write("\t\t.2byte\t%d\n" % (tableEntry(i)[1]+1074))
  write("TenPowers:\n" if passno == 0 else "Exp2ForEntry:\n")
  for i in range(2098+7):  # base -1074, max 1022
    old_e = e
    e = i + 3
    e = (  ((e * 39457 - 236739) >> 18) + 1  )*2 - 324
    if e != old_e:
      write("\t\t%s" % ("@" if e==310 else ""))
      N64, digits = tableEntry(e)
      if passno == 0:
        # 1st pass: table of numbers
        write(".8byte\t0x%X\n" % N64)
      else:
        # 2nd pass: table of exponents of 2 for this power of 10 (+64)
        write(".2byte\t%d\n" % (digits+1074))
