# Sound effects and songs don't require any options, so
# we can build the lists automatically if desired:

withDir "samples":
  for s in listFiles("."):
    sample s

withDir "modules":
  for m in listFiles("."):
    module m
