import space
import entity
import level

type
  Baitman* = object
    entity*: Entity
    lastNode: ref MoveNode
    nodePos: Vec2f
    nodeDirection: Vec2f
  Hook* = object
    entity*: Entity
  Fish* = object
    entity*: Entity
  BaitStage* = object
    level*: ref Level
    baitman*: Baitman
    hooks: seq[Hook]
    fish: seq[Fish]

proc turn(baitman: var Baitman) =
  let turnNode = baitman.lastNode.relativeNode(baitman.entity.direction[0].int, baitman.entity.direction[1].int)
  if turnNode != nil and turnNode.open:
    baitman.nodeDirection = baitman.entity.direction

proc nodeChange(baitman: var Baitman; node: ref MoveNode) =
  baitman.lastNode = node
  turn(baitman)
  let bumpCheckNode = baitman.lastNode.relativeNode(baitman.nodeDirection[0].int, baitman.nodeDirection[1].int)
  if bumpCheckNode != nil and bumpCheckNode.open:
    baitman.nodePos = baitman.nodeDirection * (baitman.nodePos - baitman.nodePos.normalised).len
  else:
    baitman.nodePos = [0, 0]
  
  # TODO different placable items
  baitman.lastNode.item = ikPellet

proc movement(baitman: var Baitman; delta: float64) =
  # TODO remake this at some point cause honestly it seems a bit overcomplicated
  let nextNode = baitman.lastNode.relativeNode(baitman.nodeDirection[0].int, baitman.nodeDirection[1].int)
  if nextNode != nil and nextNode.open:
    baitman.nodePos = baitman.nodePos + baitman.nodeDirection * baitman.entity.speed * delta
    if baitman.nodePos.len >= 1:
      baitman.nodeChange(nextNode)
  else:
    turn(baitman)
    baitman.nodePos = [0, 0]
  baitman.entity.direction = baitman.nodeDirection
  baitman.entity.pos = [baitman.lastNode.pos[0].float64, baitman.lastNode.pos[1].float64] + baitman.nodePos

proc tick*(baitman: var Baitman; delta: float64) =
  baitman.movement(delta)

proc init*(baitStage: var BaitStage) =
  baitStage.level = getLevel1()
  baitStage.baitman.nodeDirection = [-1, 0]
  baitStage.baitman.entity.direction = [-1, 0]
  baitStage.baitman.lastNode = baitStage.level.moveGrid[23][20]
  baitStage.baitman.entity.speed = 9

proc tick*(baitStage: var BaitStage; delta: float64) =
  baitStage.baitman.tick(delta)