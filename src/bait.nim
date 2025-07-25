import space
import entity
import level

type
  Baitman* = object
    entity*: Entity
    lastNode: ptr MoveNode
    nodePos: Vec2f
    nodeDirection: Vec2f
  Hook* = object
    entity*: Entity
  Fish* = object
    entity*: Entity
  BaitStage* = object
    level*: Level
    baitman*: Baitman
    hooks: seq[Hook]
    fish: seq[Fish]

proc turn(baitman: var Baitman) =
  let turnNode = baitman.lastNode.relativeNode(baitman.entity.direction.normalised[0].int, baitman.entity.direction.normalised[1].int)
  if turnNode != nil and turnNode.open:
    baitman.nodeDirection = baitman.entity.direction

proc nodeChange(baitman: var Baitman; node: ptr MoveNode) =
  baitman.lastNode = node
  turn(baitman)
  let bumpCheckNode = baitman.lastNode.relativeNode(baitman.nodeDirection.normalised[0].int, baitman.nodeDirection.normalised[1].int)
  if bumpCheckNode != nil and bumpCheckNode.open:
    baitman.nodePos = baitman.nodeDirection.normalised * (baitman.nodePos - baitman.nodePos.normalised).len
  else:
    baitman.nodePos = [0, 0]
  
  # TODO different placable items
  baitman.lastNode.item = ikPellet

proc movement(baitman: var Baitman; delta: float64) =
  let nextNode = baitman.lastNode.relativeNode(baitman.nodeDirection.normalised[0].int, baitman.nodeDirection.normalised[1].int)
  if nextNode != nil and nextNode.open:
    baitman.nodePos = baitman.nodePos + baitman.nodeDirection.normalised * baitman.entity.speed * delta
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
  baitStage.baitman.lastNode = baitStage.level.moveGrid[23][20].addr
  baitStage.baitman.entity.speed = 9

proc tick*(baitStage: var BaitStage; delta: float64) =
  baitStage.baitman.tick(delta)