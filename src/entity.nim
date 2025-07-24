import space
import level

type
  Entity* = object
    pos*: Vec2f
    direction*: Vec2f
    speed*: float
    collision: bool
    level: ptr Level
  Girl* = object
    entity*: Entity

proc applyMovement*(entity: var Entity; delta: float64) =
  if not entity.collision:
    entity.pos = entity.pos + entity.direction.normalised * entity.speed * delta
  else:
    discard # collision stuff