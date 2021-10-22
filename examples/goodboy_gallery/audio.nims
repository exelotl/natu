# Sound effects and songs don't require any options, so
# we can build the lists automatically if desired:

for s in listFiles("samples").sorted:
  sample s

for m in listFiles("modules").sorted:
  module m
