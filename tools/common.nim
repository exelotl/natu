import streams, parsecsv

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
