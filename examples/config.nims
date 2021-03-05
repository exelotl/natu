task build_examples, "build all examples":
  for dir in listDirs(thisDir()):
    withDir dir:
      echo dir
      selfExec "build"

task clean_examples, "remove build files for all examples":
  for dir in listDirs(thisDir()):
    withDir dir:
      selfExec "clean"

task examples, "build all examples":
  # shorthand
  buildExamplesTask()
