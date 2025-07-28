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
    node*: ptr MoveNode
  BaitStage* = object
    level*: ptr Level
    baitman*: Baitman
    fish*: seq[Fish]
    hooks*: seq[Hook]
    time*: float64
    score*: int

proc turn(baitman: var Baitman) =
  let turnNode = baitman.lastNode.relativeNode(baitman.entity.direction)
  if turnNode != nil and turnNode.open:
    baitman.nodeDirection = baitman.entity.direction

proc nodeChange(baitman: var Baitman; node: ptr MoveNode) =
  baitman.lastNode = node
  turn(baitman)
  let bumpCheckNode = baitman.lastNode.relativeNode(baitman.nodeDirection)
  if bumpCheckNode != nil and bumpCheckNode.open:
    baitman.nodePos = baitman.nodeDirection * (baitman.nodePos - baitman.nodePos.normalised).mag
  else:
    baitman.nodePos = [0, 0]
  
  # TODO different placeable items
  baitman.lastNode.item = ikPellet

proc movement(baitman: var Baitman; delta: float64) =
  # TODO remake this at some point cause honestly it seems a bit overcomplicated
  var nextNode = baitman.lastNode.relativeNode(baitman.nodeDirection)
  if nextNode != nil and nextNode.open:
    baitman.nodePos = baitman.nodePos + baitman.nodeDirection * baitman.entity.speed * delta
    while baitman.nodePos.sum.abs >= 1:
      baitman.nodeChange(nextNode)
      # for super high speeds
      if baitman.nodePos.sum.abs < 1:
        break
      nextNode = baitman.lastNode.relativeNode(baitman.nodeDirection)
  else:
    turn(baitman)
    baitman.nodePos = [0, 0]
  baitman.entity.direction = baitman.nodeDirection
  baitman.entity.pos = baitman.lastNode.pos.Vec2f + baitman.nodePos

proc tick(baitman: var Baitman; delta: float64) =
  baitman.movement(delta)

proc nextDirection(fish: Fish): Vec2f =

  func pelletCheck(node: ptr MoveNode): bool =
    node.item == ikPellet

  func openNeighbours(node: ptr MoveNode): seq[(ptr MoveNode, float)] =
    for dir in [[0, -1], [0, 1], [-1, 0], [1, 0]]:
      let nn = node.relativeNode(dir)
      if nn.open:
        result.add((nn, 1.0))
  
  func hash(node: ptr MoveNode): Vec2i =
    node.pos

  func directionToNextNode(current, next: ptr MoveNode): Vec2f =
    result = next.pos - current.pos
    if result.sum.abs > 1:
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
  while fish.nodePos.sum.abs >= 1:
    fish.lastNode = fish.lastNode.relativeNode(fish.entity.direction)
    if fish.lastNode.item == ikPellet:
      fish.lastNode.item = ikNone
    fish.entity.direction = fish.nextDirection()
    fish.nodePos = fish.entity.direction * (fish.nodePos - fish.nodePos.normalised).mag
  fish.entity.pos = fish.lastNode.pos.Vec2f + fish.nodePos

proc tick(hook: var Hook; delta: float64) =
  hook.entity.pos = hook.node.pos

proc spawnFish(baitStage: var BaitStage) =
  var fish: Fish
  fish.lastNode = baitStage.level.randomOpenNode()
  fish.entity.pos = fish.lastNode.pos
  fish.entity.direction = fish.nextDirection()
  fish.entity.speed = 1.0 + rand(5.0)
  baitStage.fish.add(fish)

proc spawnHook(baitStage: var BaitStage) =
  var hook: Hook
  hook.node = baitStage.level.randomOpenNode()
  hook.entity.pos = hook.node.pos
  baitStage.hooks.add(hook)

proc catchFish(baitStage: var BaitStage) =
  for i in countDown(baitStage.fish.high, 0):
    for j in countDown(baitStage.hooks.high, 0):
      let
        fish = baitStage.fish[i]
        hook = baitStage.hooks[j]
      if (fish.entity.pos - hook.entity.pos).mag < 1:
        baitStage.score += 1
        baitStage.fish.delete(i)
        baitStage.hooks.delete(j)
        break

proc init*(baitStage: var BaitStage) =
  baitStage.level = getLevel1()
  baitStage.baitman.nodeDirection = [-1, 0]
  baitStage.baitman.entity.direction = [-1, 0]
  baitStage.baitman.lastNode = baitStage.level.moveGrid[23][20]
  baitStage.baitman.entity.speed = 9
  baitStage.time = 180

proc tick*(baitStage: var BaitStage; delta: float64) =
  if baitStage.time <= 0:
    baitStage.time = 0
    return
  baitStage.time -= delta
  baitStage.baitman.tick(delta)
  for i in 0..baitStage.fish.high:
    baitStage.fish[i].tick(delta)
  for i in 0..baitStage.hooks.high:
    baitStage.hooks[i].tick(delta)
  baitStage.catchFish()
  while baitStage.fish.len < 30:
    baitStage.spawnFish()
  while baitStage.hooks.len < 3:
    baitStage.spawnHook()