import random

import space
import entity
import level
import pathfinding

type
  Baitman* = object
    entity*: Entity
    lastNode: ptr MoveNode
    nodePos: Vec2f
    nodeDirection: Vec2f
  Fish* = object
    entity*: Entity
    lastNode*: ptr MoveNode
    nodePos: Vec2f
  Hook* = object
    entity*: Entity
  BaitStage* = object
    level*: ptr Level
    baitman*: Baitman
    fish*: seq[Fish]
    hooks*: seq[Hook]

proc turn(baitman: var Baitman) =
  let turnNode = baitman.lastNode.relativeNode(baitman.entity.direction[0].int, baitman.entity.direction[1].int)
  if turnNode != nil and turnNode.open:
    baitman.nodeDirection = baitman.entity.direction

proc nodeChange(baitman: var Baitman; node: ptr MoveNode) =
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

proc tick(baitman: var Baitman; delta: float64) =
  baitman.movement(delta)

proc nextDirection(fish: Fish): Vec2f =

  func pelletCheck(node: ptr MoveNode): bool =
    node.item == ikPellet

  func openNeighbours(node: ptr MoveNode): seq[(ptr MoveNode, float)] =
    for (x, y) in [(0, -1), (0, 1), (-1, 0), (1, 0)]:
      let nn = node.relativeNode(x, y)
      if nn.open:
        result.add((nn, 1.0))
  
  func hash(node: ptr MoveNode): (int, int) =
    node.pos

  func directionToNextNode(current, next: ptr MoveNode): Vec2f =
    result = [(next.pos[0] - current.pos[0]).float64, (next.pos[1] - current.pos[1]).float64]
    if result.len > 1:
      result = [0.0, 0.0] - result
    result = result.normalised()

  let path = calculatePath(fish.lastNode, pelletCheck, openNeighbours, hash)
  if path.len > 0:
    let nextNode = path[0]
    return directionToNextNode(fish.lastNode, nextNode)
  else:
    let open = fish.lastNode.openNeighbours()
    if open.len > 0:
      return directionToNextNode(fish.lastNode, sample(open)[0])

proc tick(fish: var Fish; delta: float64) =
  fish.nodePos = fish.nodePos + fish.entity.direction * fish.entity.speed * delta
  if fish.nodePos.len >= 1:
    fish.lastNode = fish.lastNode.relativeNode(fish.entity.direction[0].int, fish.entity.direction[1].int)
    if fish.lastNode.item == ikPellet:
      fish.lastNode.item = ikNone
    fish.entity.direction = fish.nextDirection()
    fish.nodePos = fish.entity.direction * (fish.nodePos - fish.nodePos.normalised).len
  fish.entity.pos = [fish.lastNode.pos[0].float64, fish.lastNode.pos[1].float64] + fish.nodePos

proc spawnFish(baitStage: var BaitStage) =
  var fish: Fish
  fish.lastNode = baitStage.level.randomOpenNode()
  fish.entity.direction = fish.nextDirection()
  fish.entity.speed = (1 + rand(5)).float
  baitStage.fish.add(fish)

proc init*(baitStage: var BaitStage) =
  baitStage.level = getLevel1()
  baitStage.baitman.nodeDirection = [-1, 0]
  baitStage.baitman.entity.direction = [-1, 0]
  baitStage.baitman.lastNode = baitStage.level.moveGrid[23][20]
  baitStage.baitman.entity.speed = 9
  for i in 0..29:
    baitStage.spawnFish()

proc tick*(baitStage: var BaitStage; delta: float64) =
  baitStage.baitman.tick(delta)
  for i in 0..baitStage.fish.high:
    baitStage.fish[i].tick(delta)