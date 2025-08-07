import random

import ../space

const
  levelWidth* = 40
  levelHeight* = 28
  gridWidth* = levelWidth + 1
  gridHeight* = levelHeight + 1

# level
type
  TileKind* = enum
    tkWall
    tkGround
  ItemKind* = enum
    ikNone
    ikPellet
    ikBigPellet
  MoveNode* = object
    level*: ptr Level
    pos*: Vec2i
    open*: bool
    item*: ItemKind
  Level* = object
    rand*: Rand
    tiles*: array[levelHeight, array[levelWidth, TileKind]]
    moveGrid*: array[gridHeight, array[gridWidth, ptr MoveNode]]
    openMoveNodes*: seq[ptr MoveNode]

# bait
type
  AbilityKind* = enum
    akNone
    akBigPellet
  Entity* = object
    node*: ptr MoveNode
    nextNode*: ptr MoveNode
    speed*: float64
    progress*: float64
  Baitman* = object
    entity*: Entity
    inputDirection*: Vec2i
    nextItem*: ItemKind
  Fish* = object
    entity*: Entity
  Hook* = object
    entity*: Entity
  Ability* = object
    entity*: Entity
    kind*: AbilityKind
  BaitStage* = object
    level*: ptr Level
    baitman*: Baitman
    fish*: seq[Fish]
    hooks*: seq[Hook]
    abilities*: seq[Ability]
    currentAbility*: AbilityKind
    time*: float64
    score*: int

# i want cyclic imports reee