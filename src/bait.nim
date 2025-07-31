import random

import space
import entity
import level
import pathfinding

type
  AbilityKind* = enum
    akNone
    akBigPellet
  Baitman* = object
    entity*: Entity
    lastNode: ptr MoveNode
    nodePos: Vec2f
    nodeDirection: Vec2f
    nextItem: ItemKind
  Fish* = object
    entity*: Entity
    lastNode*: ptr MoveNode
    nodePos: Vec2f
  Hook* = object
    entity*: Entity
    node*: ptr MoveNode
  Ability* = object
    entity*: Entity
    node*: ptr MoveNode
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

proc turn(baitman: var Baitman) =
  let turnNode = baitman.lastNode.relativeNode(baitman.entity.direction)
  if turnNode != nil and turnNode.open:
    baitman.nodeDirection = baitman.entity.direction

proc placeItem(baitman: var Baitman) =
  const priority = [ikBigPellet, ikPellet, ikNone]
  if priority.find(baitman.lastNode.item) > priority.find(baitman.nextItem):
    baitman.lastNode.item = baitman.nextItem
  baitman.nextItem = ikPellet

proc nodeChange(baitman: var Baitman; node: ptr MoveNode) =
  baitman.lastNode = node
  turn(baitman)
  let bumpCheckNode = baitman.lastNode.relativeNode(baitman.nodeDirection)
  if bumpCheckNode != nil and bumpCheckNode.open:
    baitman.nodePos = baitman.nodeDirection * (baitman.nodePos - baitman.nodePos.normalised).mag
  else:
    baitman.nodePos = [0, 0]
  baitman.placeItem()

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
    baitman.placeItem()
  baitman.entity.direction = baitman.nodeDirection
  baitman.entity.pos = baitman.lastNode.pos.Vec2f + baitman.nodePos

proc init(baitman: var Baitman) =
  baitman.nodeDirection = [-1, 0]
  baitman.entity.direction = [-1, 0]
  baitman.entity.speed = 9
  baitman.nextItem = ikPellet

proc tick(baitman: var Baitman; delta: float64) =
  baitman.movement(delta)

proc nextDirection(fish: Fish): Vec2f =

  func bigPelletCheck(node: ptr MoveNode): bool =
    node.item == ikBigPellet

  func pelletCheck(node: ptr MoveNode): bool =
    node.item == ikPellet

  proc openNeighbours(node: ptr MoveNode): seq[(ptr MoveNode, float)] =
    for dir in [[0, -1], [0, 1], [-1, 0], [1, 0]]:
      let nn = node.relativeNode(dir)
      if nn.open:
        result.add((nn, 1.0))
      result.shuffle()
  
  func hash(node: ptr MoveNode): Vec2i =
    node.pos

  func directionToNextNode(current, next: ptr MoveNode): Vec2f =
    result = next.pos - current.pos
    if result.sum.abs > 1:
      result = [0.0, 0.0] - result
    result = result.normalised()

  let bigPelletPath = calculatePath(fish.lastNode, bigPelletCheck, openNeighbours, hash, some(6.0))
  if bigPelletPath.len > 0:
    return directionToNextNode(fish.lastNode, bigPelletPath[0])
  let pelletPath = calculatePath(fish.lastNode, pelletCheck, openNeighbours, hash, some(3.0))
  if pelletPath.len > 0:
    return directionToNextNode(fish.lastNode, pelletPath[0])
  let open = fish.lastNode.openNeighbours()
  if open.len > 0:
    return directionToNextNode(fish.lastNode, sample(open)[0])

proc tick(fish: var Fish; delta: float64) =
  fish.nodePos = fish.nodePos + fish.entity.direction * fish.entity.speed * delta
  while fish.nodePos.sum.abs >= 1:
    fish.lastNode = fish.lastNode.relativeNode(fish.entity.direction)
    case fish.lastNode.item
    of ikPellet:
      fish.lastNode.item = ikNone
    of ikBigPellet:
      fish.lastNode.item = ikNone
    else: discard
    fish.entity.direction = fish.nextDirection()
    fish.nodePos = fish.entity.direction * (fish.nodePos - fish.nodePos.normalised).mag
  fish.entity.pos = fish.lastNode.pos.Vec2f + fish.nodePos

proc tick(hook: var Hook; delta: float64) =
  hook.entity.pos = hook.node.pos

proc tick(ability: var Ability; delta: float64) =
  ability.entity.pos = ability.node.pos

proc spawnFish(baitStage: var BaitStage) =
  var fish: Fish
  fish.lastNode = baitStage.level.randomOpenNode()
  fish.entity.pos = fish.lastNode.pos
  fish.entity.direction = fish.nextDirection()
  fish.entity.speed = 2.0 + rand(4.0)
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

proc spawnAbility(baitStage: var BaitStage) =
  var ability: Ability
  ability.node = baitStage.level.randomOpenNode()
  ability.entity.pos = ability.node.pos
  ability.kind = akBigPellet
  baitStage.abilities.add(ability)

proc collectAbilities(baitStage: var BaitStage) =
  for i in countDown(baitStage.abilities.high, 0):
    let ability = baitStage.abilities[i]
    if (baitStage.baitman.entity.pos - ability.entity.pos).mag < 1:
      baitStage.currentAbility = ability.kind
      baitStage.abilities.delete(i)

proc useAbility*(baitStage: var BaitStage) =
  case baitStage.currentAbility
  of akBigPellet:
    baitStage.baitman.nextItem = ikBigPellet
  of akNone: discard
  baitStage.currentAbility = akNone

proc init*(baitStage: var BaitStage) =
  baitStage.level = createLevel(level1Str)
  baitStage.baitman.init()
  baitStage.baitman.lastNode = baitStage.level.moveGrid[23][20]
  baitStage.currentAbility = akBigPellet
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

  for i in 0..baitStage.abilities.high:
    baitStage.abilities[i].tick(delta)
  baitStage.collectAbilities()

  while baitStage.fish.len < 10:
    baitStage.spawnFish()
  while baitStage.hooks.len < 3:
    baitStage.spawnHook()
  while baitStage.abilities.len < 2:
    baitStage.spawnAbility()