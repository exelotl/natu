
# Simple looping animation
type
  AnimData* = object
    first*, len*, speed*: int
  Anim* = object
    data*: AnimData
    frame*, timer*: int

proc initAnim*(data: AnimData): Anim =
  result.data = data
  result.frame = 0
  result.timer = data.speed + 1

proc update*(a: var Anim) =
  dec a.timer
  if a.timer < 0:
    a.timer = a.data.speed
    inc a.frame
    if a.frame >= a.data.first + a.data.len:
      a.frame = 0

proc dirty*(a: Anim): bool =
  a.timer == a.data.speed
