import ../space
import ../collision
import level

import types
export types

proc move(entity: var Entity; delta: float64; walls: seq[Wall]) =
  entity.pos = (entity.pos + entity.direction.norm * entity.speed * delta).collide(walls, proc(v: Vec2f): float64 = 1)

proc tick(girl: var Girl; walkStage: WalkStage; delta: float64) =
  girl.entity.move(delta, walkStage.level.walls)
  girl.entity.direction = [0, 0]

proc init*(walkStage: var WalkStage) =
  walkStage.girl.entity.pos = [10, 10]
  walkStage.girl.entity.speed = 7
  walkStage.level = create(Level)
  walkStage.level.walls = @[
    [[18, 5], [26, 5]],
    [[26, 5], [26, 13]],
    [[26, 13], [18, 13]],
    [[18, 13], [18, 5]],
  ]

proc tick*(walkStage: var WalkStage; delta: float64) =
  walkStage.girl.tick(walkStage, delta)