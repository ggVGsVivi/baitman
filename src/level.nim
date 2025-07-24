const
  levelWidth = 40
  levelHeight = 28

type
  TileKind* = enum
    tkWall
    tkGround
  ItemKind* = enum
    ikPellet
    ikBigPellet
  MoveNode* = object
    level: ptr Level
    pos*: (int, int)
    open*: bool
    item: ItemKind
  Level* = object
    tiles*: array[levelHeight, array[levelWidth, TileKind]]
    moveGrid*: array[levelHeight, array[levelWidth, MoveNode]]

func relativeNode*(node: ptr MoveNode; x, y: int): ptr MoveNode =
  if node.pos[1] + y in 0..levelHeight - 1 and node.pos[0] + x in 0..levelWidth - 1:
    node.level.moveGrid[node.pos[1] + y][node.pos[0] + x].addr
  else:
    nil

func openNeighbours*(node: ptr MoveNode): seq[ptr MoveNode] =
  for (x, y) in [(0, -1), (0, 1), (-1, 0), (1, 0)]:
    let nn = node.level.moveGrid[node.pos[1] + y][node.pos[0] + x].addr
    if nn.open:
      result.add(nn)

proc generateMoveGrid(level: var Level) =

  func openCheck(level: Level; y, x: int): bool =
    for (yOffset, xOffset) in [(0, 0), (1, 0), (0, 1), (1, 1)]:
      if y + yOffset >= levelHeight or x + xOffset >= levelWidth:
        continue
      if level.tiles[y + yOffset][x + xOffset] == tkWall:
        return false
    return true

  for y in 0..levelHeight - 1:
    for x in 0..levelWidth - 1:
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
########################################
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
###########     ########     ###########
###########     ########     ###########
###########  #            #  ###########
###########  #            #  ###########
###########  #  ########  #  ###########
######             ##             ######
######             ##             ######
######  ###  ####  ##  ####  ###  ######
######  ###                  ###  ######
######  ###                  ###  ######
######  ###  #  ########  #  ###  ######
######       #            #       ######
######       #            #       ######
########################################
########################################
"""

func getLevel1*(): Level =
  constructLevel(level1Str)