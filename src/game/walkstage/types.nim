import ../space

# level
type
  Wall* = array[2, Vec2f]
  Level* = object
    walls*: seq[Wall]

# walk
type
  Entity* = object
    pos*: Vec2f
    direction*: Vec2f
    speed*: float64
  Girl* = object
    entity*: Entity
  WalkStage* = object
    level*: ptr Level
    girl*: Girl

# i want cyclic imports reee