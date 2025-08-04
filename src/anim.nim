type
  Point = (int, int)
  Animation* = object
    size*: Point
    offsets*: seq[Point]
    speed*: float
    progress*: float64
    repeat*: bool

func getFrame*(animation: Animation): array[4, int] =
  let currentOffset = animation.offsets[animation.progress.int]
  [currentOffset[0], currentOffset[1], animation.size[0], animation.size[1]]

proc next*(animation: var Animation; delta: float64): bool =
  animation.progress += animation.speed * delta
  if animation.progress >= animation.offsets.len.float:
    if animation.repeat:
      animation.progress -= animation.offsets.len.float
    else:
      animation.progress -= 1
  not animation.repeat and animation.progress >= animation.offsets.len.float - 1