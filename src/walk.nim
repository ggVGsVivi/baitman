import space

type
  Entity = object
    pos: Vec2f
  Girl = object
    entity: Entity
  WalkStage* = object
    girl: Girl

proc tick*(walkStage: var WalkStage; delta: float64) =
  discard