import os, times, streams, parsecsv

template withFile*(filename: string, mode: FileMode, body: untyped) =
  block:
    var file {.inject.}: File
    try:
      file = open(filename, mode)
      body
    finally:
      close(file)

iterator tsvRows*(filename: string): seq[string] =
  var stream = newFileStream(filename, fmRead)
  var tsv: CsvParser
  try:
    open(tsv, stream, filename, separator='\t')
    while readRow(tsv):
      yield tsv.row
  finally:
    close(tsv)

proc toTime*(t: Time): Time = t

proc toTime*(f: string): Time =
  if fileExists(f) or dirExists(f): getLastModificationTime(f)
  else: fromUnix(0)

proc newest*(times: varargs[Time, toTime]): Time =
  result = times[0]
  for t in times[1..^1]:
    if t > result: result = t

proc oldest*(times: varargs[Time, toTime]): Time =
  result = times[0]
  for t in times[1..^1]:
    if t < result: result = t
