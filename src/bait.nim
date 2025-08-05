import random

import space
import level
import pathfinding

type
  AbilityKind* = enum
    akNone
    akBigPellet
  Entity = object
    node: ptr MoveNode
    nextNode: ptr MoveNode
    speed: float64
    progress: float64
  Baitman* = object
    entity*: Entity
    inputDirection*: Vec2i
    nextItem: ItemKind
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

func direction(entity: Entity): Vec2i =
  if entity.nextNode == nil:
    return [0, 0]
  result = entity.nextNode.pos - entity.node.pos
  # maybe there's a better way to do this
  if result.sum.abs > 1:
    result = ([0, 0] - result).normalised

func pos*(entity: Entity): Vec2f =
  if entity.node == nil:
    return [0, 0]
  entity.node.pos.Vec2f + entity.direction.Vec2f * entity.progress

proc turn(baitman: var Baitman): bool =
  let turnNode = baitman.entity.node.relativeNode(baitman.inputDirection)
  if turnNode.open:
    baitman.entity.nextNode = turnNode
    return true
  false

proc placeItem(baitman: var Baitman) =
  const priority = [ikBigPellet, ikPellet, ikNone]
  if priority.find(baitman.entity.node.item) > priority.find(baitman.nextItem):
    baitman.entity.node.item = baitman.nextItem
  baitman.nextItem = ikPellet

proc movement(baitman: var Baitman; delta: float64) =
  if baitman.entity.nextNode != nil:
    baitman.entity.progress += baitman.entity.speed * delta
    while baitman.entity.progress >= 1:
      baitman.entity.progress -= 1
      let direction = baitman.entity.direction
      baitman.entity.node = baitman.entity.nextNode
      if not baitman.turn():
        baitman.entity.nextNode = baitman.entity.node.relativeNode(direction)
        if not baitman.entity.nextNode.open:
          baitman.entity.nextNode = nil
          baitman.entity.progress = 0
      baitman.placeItem()
  else:
    discard baitman.turn()
  baitman.inputDirection = baitman.entity.direction

proc init(baitman: var Baitman) =
  baitman.inputDirection = [-1, 0]
  baitman.entity.speed = 9
  baitman.nextItem = ikPellet

proc tick(baitman: var Baitman; delta: float64) =
  baitman.movement(delta)

proc path(fish: Fish): ptr MoveNode =

  func bigPelletCheck(node: ptr MoveNode): bool =
    node.item == ikBigPellet

  func pelletCheck(node: ptr MoveNode): bool =
    node.item == ikPellet

  func openNeighbours(node: ptr MoveNode): seq[(ptr MoveNode, float)] =
    for dir in [[0, -1], [0, 1], [-1, 0], [1, 0]]:
      let nn = node.relativeNode(dir)
      if nn.open:
        result.add((nn, 1.0))
      node.level.rand.shuffle(result)
  
  func hash(node: ptr MoveNode): Vec2i =
    node.pos

  let bigPelletPath = calculatePath(fish.entity.node, bigPelletCheck, openNeighbours, hash, some(6.0))
  if bigPelletPath.len > 0:
    return bigPelletPath[0]
  let pelletPath = calculatePath(fish.entity.node, pelletCheck, openNeighbours, hash, some(3.0))
  if pelletPath.len > 0:
    return pelletPath[0]
  let open = fish.entity.node.openNeighbours()
  if open.len > 0:
    return sample(open)[0]

proc tick(fish: var Fish; delta: float64) =
  fish.entity.progress += fish.entity.speed * delta
  while fish.entity.progress >= 1:
    fish.entity.progress -= 1
    fish.entity.node = fish.entity.nextNode
    case fish.entity.node.item
    of ikPellet:
      fish.entity.node.item = ikNone
    of ikBigPellet:
      fish.entity.node.item = ikNone
    else: discard
    fish.entity.nextNode = fish.path()

proc tick(hook: var Hook; delta: float64) =
  discard

proc tick(ability: var Ability; delta: float64) =
  discard

proc spawnFish(baitStage: var BaitStage) =
  var fish: Fish
  fish.entity.node = baitStage.level.randomOpenNode()
  fish.entity.nextNode = fish.path()
  fish.entity.speed = 2.0 + rand(4.0)
  baitStage.fish.add(fish)

proc spawnHook(baitStage: var BaitStage) =
  var hook: Hook
  hook.entity.node = baitStage.level.randomOpenNode()
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
  ability.entity.node = baitStage.level.randomOpenNode()
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
  baitStage.baitman.entity.node = baitStage.level.moveGrid[23][20]
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