import ../space

# walk
type
  Entity* = object
    pos*: Vec2f
    direction*: Vec2f
    speed*: float64
  Girl* = object
    entity*: Entity
  WalkStage* = object
    girl*: Girl

# i want cyclic imports reee