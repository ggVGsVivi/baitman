import math

import entity
import bait

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
    # TODO walkStage: WalkStage
    baitStage*: BaitStage

proc init*(game: var Game) =
  game.currentStage = csBait
  game.baitStage.init()

proc input*(game: var Game; kind: InputKind) =
  case game.currentStage
  of csWalk:
    discard # TODO after walkStage
  of csBait:
    case kind
    of ikMoveUp:
      game.baitStage.baitman.entity.direction = [0, -1]
    of ikMoveDown:
      game.baitStage.baitman.entity.direction = [0, 1]
    of ikMoveLeft:
      game.baitStage.baitman.entity.direction = [-1, 0]
    of ikMoveRight:
      game.baitStage.baitman.entity.direction = [1, 0]
    of ikInteract:
      discard

proc tick*(game: var Game; delta: float64): bool =
  case game.currentStage
  of csWalk:
    discard # TODO after walkStage
  of csBait:
    game.baitStage.tick(delta)
  true
