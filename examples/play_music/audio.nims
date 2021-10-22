# Add all music and sounds from the audio directory.

for f in listFiles("audio").sorted:
  if f.endsWith(".wav"):
    sample f
  else:
    module f
