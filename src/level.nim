import random

const
  levelWidth = 40
  levelHeight = 28
  gridWidth = levelWidth + 1
  gridHeight = levelHeight + 1

type
  TileKind* = enum
    tkWall
    tkGround
  ItemKind* = enum
    ikNone
    ikPellet
    ikBigPellet
  MoveNode* = object
    level: ref Level
    pos*: (int, int)
    open*: bool
    item*: ItemKind
  Level* = object
    tiles*: array[levelHeight, array[levelWidth, TileKind]]
    moveGrid*: array[gridHeight, array[gridWidth, ref MoveNode]]
    openMoveNodes: seq[ref MoveNode]

func relativeNode*(node: ref MoveNode; x, y: int): ref MoveNode =
  var
    xx = node.pos[0] + x
    yy = node.pos[1] + y
  if xx < 0:
    xx = gridWidth - 1
  if yy < 0:
    yy = gridHeight - 1
  node.level.moveGrid[yy mod gridHeight][xx mod gridWidth]

func openNeighbours*(node: ref MoveNode): seq[ref MoveNode] =
  for (x, y) in [(0, -1), (0, 1), (-1, 0), (1, 0)]:
    let nn = node.relativeNode(x, y)
    if nn.open:
      result.add(nn)

proc randomOpenNode*(level: Level; rand: var Rand): ref MoveNode =
  rand.sample(level.openMoveNodes)

proc generateMoveGrid(level: ref Level) =

  func openCheck(level: ref Level; x, y: int): bool =
    for (yOffset, xOffset) in [(0, 0), (1, 0), (0, 1), (1, 1)]:
      let
        xx = x - 1 + xOffset
        yy = y - 1 + yOffset
      if not (yy in 0..levelHeight - 1 and xx in 0..levelWidth - 1):
        continue
      if level.tiles[yy][xx] == tkWall:
        return false
    return true

  for y in 0..gridHeight - 1:
    for x in 0..gridWidth - 1:
      var node = new MoveNode
      node.level = level
      node.pos = (x, y)
      node.open = openCheck(level, x, y)
      level.moveGrid[y][x] = node
      if node.open:
        level.openMoveNodes.add(level.moveGrid[y][x])

func constructLevel(levelStr: string): ref Level =
  result = new Level
  var
    x = 0
    y = 0
  for c in levelStr:
    case c
    of '#':
      result.tiles[y][x] = tkWall
      x += 1
    of ' ':
      result.tiles[y][x] = tkGround
      x += 1
    of '\n':
      x = 0
      y += 1
    else: discard

  result.generateMoveGrid()

const level1Str = """
###########  ##############  ###########
######             ##             ######
######             ##             ######
######  ###  ####  ##  ####  ###  ######
######  ###  ####  ##  ####  ###  ######
######                            ######
######                            ######
######  ###  #  ########  #  ###  ######
######       #     ##     #       ######
######       #     ##     #       ######
###########  ####  ##  ####  ###########
###########  #            #  ###########
###########  #            #  ###########
                ########                
                ########                
###########  #            #  ###########
###########  #            #  ###########
###########  #  ########  #  ###########
######             ##             ######
######             ##             ######
######  ###  ####  ##  ####  ###  ######
######  ###  ####  ##  ####  ###  ######
######  ###                  ###  ######
######  ###                  ###  ######
######  ###  #  ########  #  ###  ######
######       #            #       ######
######       #            #       ######
###########  ##############  ###########
"""

func getLevel1*(): ref Level =
  constructLevel(level1Str)