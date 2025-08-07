import ../space

import types
export types

proc move(entity: var Entity; delta: float64) =
  entity.pos = entity.pos + entity.direction.normalised * entity.speed * delta

proc tick(girl: var Girl; delta: float64) =
  girl.entity.move(delta)
  girl.entity.direction = [0, 0]

proc init*(walkStage: var WalkStage) =
  walkStage.girl.entity.pos = [10, 10]
  walkStage.girl.entity.speed = 7

proc tick*(walkStage: var WalkStage; delta: float64) =
  walkStage.girl.tick(delta)