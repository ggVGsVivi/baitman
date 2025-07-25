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
    level: ptr Level
    pos*: (int, int)
    open*: bool
    item*: ItemKind
  Level* = object
    tiles*: array[levelHeight, array[levelWidth, TileKind]]
    moveGrid*: array[gridHeight, array[gridWidth, MoveNode]]

func relativeNode*(node: ptr MoveNode; x, y: int): ptr MoveNode =
  var
    xx = node.pos[0] + x
    yy = node.pos[1] + y
  if xx < 0:
    xx = gridWidth - 1
  if yy < 0:
    yy = gridHeight - 1
  node.level.moveGrid[yy mod gridHeight][xx mod gridWidth].addr

func openNeighbours*(node: ptr MoveNode): seq[ptr MoveNode] =
  for (x, y) in [(0, -1), (0, 1), (-1, 0), (1, 0)]:
    let nn = node.relativeNode(x, y)
    if nn.open:
      result.add(nn)

proc generateMoveGrid(level: var Level) =

  func openCheck(level: Level; y, x: int): bool =
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
      var node: MoveNode
      node.level = level.addr
      node.pos = (x, y)
      node.open = openCheck(level, y, x)
      level.moveGrid[y][x] = node

func constructLevel(levelStr: string): Level =
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

func getLevel1*(): Level =
  constructLevel(level1Str)