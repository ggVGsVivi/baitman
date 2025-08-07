import space
import walkstage/walk
import baitstage/bait

type
  InputKind* = enum
    ikMoveUp
    ikMoveDown
    ikMoveLeft
    ikMoveRight
    ikInteract
  CurrentStage* = enum
    csWalk
    csBait
  Game* = object
    currentStage*: CurrentStage
    walkStage*: WalkStage
    baitStage*: BaitStage
    paused*: bool

proc init*(game: var Game) =
  game.currentStage = csWalk
  game.walkStage.init()
  game.baitStage.init()
  game.paused = true

proc input*(game: var Game; kind: InputKind) =
  if game.paused:
    return
  case game.currentStage
  of csWalk:
    case kind
    of ikMoveUp:
      game.walkStage.girl.entity.direction.y -= 1
    of ikMoveDown:
      game.walkStage.girl.entity.direction.y += 1
    of ikMoveLeft:
      game.walkStage.girl.entity.direction.x -= 1
    of ikMoveRight:
      game.walkStage.girl.entity.direction.x += 1
    of ikInteract:
      discard
  of csBait:
    case kind
    of ikMoveUp:
      game.baitStage.baitman.inputDirection = [0, -1]
    of ikMoveDown:
      game.baitStage.baitman.inputDirection = [0, 1]
    of ikMoveLeft:
      game.baitStage.baitman.inputDirection = [-1, 0]
    of ikMoveRight:
      game.baitStage.baitman.inputDirection = [1, 0]
    of ikInteract:
      game.baitStage.useAbility()

proc tick*(game: var Game; delta: float64): bool =
  if game.paused:
    return true
  case game.currentStage
  of csWalk:
    game.walkStage.tick(delta)
  of csBait:
    game.baitStage.tick(delta)
  true
