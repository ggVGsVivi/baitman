import random
import strformat

import raylib

import anim
import game
import bait
import level

const
  viewWidth = 640
  viewHeight = 480
  defaultScale = 2
  ticksPerSecond = 60

when isMainModule:
  randomize()

  setConfigFlags(flags(WindowResizable, VsyncHint))
  initWIndow(viewWidth * defaultScale, viewHeight * defaultScale, "Baitman")
  let target = loadRenderTexture(viewWidth, viewHeight)

  initAudioDevice()

  let
    #texGirl = loadTexture("res/girl.png")
    texBaitman = loadTexture("res/mika.png")
    texWall = loadTexture("res/wall.png")
    texFish = loadTexture("res/fish.png")
    texHook = loadTexture("res/hook.png")
    texPelletBag = loadTexture("res/pelletBag.png")

  var animations: seq[ptr Animation]

  var animGirlDown = Animation(
    size: (32, 32),
    offsets: @[(0, 0), (32, 0), (0, 0), (64, 0)],
    speed: 4,
    repeat: true,
  )
  animations.add(animGirlDown.addr)

  var animBaitman = Animation(
    size: (32, 32),
    offsets: @[(0, 0), (32, 0)],
    speed: 6,
    repeat: true,
  )
  animations.add(animBaitman.addr)

  var animFish = Animation(
    size: (32, 32),
    offsets: @[(0, 0)],
    speed: 0,
    repeat: true,
  )
  animations.add(animFish.addr)

  var font = loadFont("res/font.ttf")

  var music = loadMusicStream("res/huhh.wav")
  playMusicStream(music)

  var gameState: Game
  gameState.init()

  #var view = newView(rect(0, 0, viewWidth, viewHeight));
  #window.view = view

  proc draw() =
    beginTextureMode(target)
    beginDrawing()

    clearBackground(Black)

    for y, row in gameState.baitStage.level.tiles:
      for x, tile in row:
        if tile == tkWall:
          drawTexture(texWall, Vector2(x: x.float * 16, y: y.float * 16), White)

    for y, row in gameState.baitStage.level.moveGrid:
      for x, node in row:
        case node.item:
        of ikPellet:
          drawCircle(Vector2(x: x.float * 16, y: y.float * 16), 3, Color(r: 0xff, g: 0xee, b: 0x00, a: 0xff))
        of ikBigPellet:
          drawCircle(Vector2(x: x.float * 16, y: y.float * 16), 6, Color(r: 0xff, g: 0xee, b: 0x66, a: 0xff))
        of ikNone: discard
    
    for ability in gameState.baitStage.abilities:
      case ability.kind
      of akBigPellet:
        drawTexture(texPelletBag, Vector2(x: ability.entity.pos[0] * 16 - 16, y: ability.entity.pos[1] * 16 - 16), White)
      of akNone: discard
    
    for hook in gameState.baitStage.hooks:
      drawTexture(texHook, Vector2(x: hook.entity.pos[0] * 16 - 16, y: hook.entity.pos[1] * 16 - 16), White)
    
    for fish in gameState.baitStage.fish:
      drawTexture(texFish, Vector2(x: fish.entity.pos[0] * 16 - 16, y: fish.entity.pos[1] * 16 - 16), White)
        
    let baitman = gameState.baitStage.baitman
    drawTexture(texBaitman, Vector2(x: baitman.entity.pos[0] * 16 - 16, y: baitman.entity.pos[1] * 16 - 16), White)

    drawText(font, fmt"{gameState.baitStage.score:06}", Vector2(x: 496, y: 454), 24, 0, White)
    drawText(font, fmt"{gameState.baitStage.time.int:03}", Vector2(x: 2, y: 454), 24, 0, White)

    drawRectangleLines(88, 452, 24, 24, White)
    case gameState.baitStage.currentAbility
    of akBigPellet:
      drawCircle(100, 464, 6, Color(r: 0xff, g: 0xee, b: 0x66, a: 0xff))
    of akNone: discard 

    endDrawing()
    endTextureMode()

    beginDrawing()

    drawTexture(
      target.texture,
      Rectangle(x: 0, y: 0, width: viewWidth, height: -viewHeight),
      Rectangle(x: 0, y: 0, width: getScreenWidth().float, height: getScreenHeight().float),
      Vector2(x: 0, y: 0),
      0,
      White
    )

    beginDrawing()

  proc input() =
    if isKeyPressed(Escape):
      closeWindow()
    if isKeyPressed(Space):
      gameState.paused = not gameState.paused
    if isKeyPressed(Z):
      gameState.input(ikInteract)

    if isKeyDown(Up):
      gameState.input(ikMoveUp)
    if isKeyDown(Down):
      gameState.input(ikMoveDown)
    if isKeyDown(Left):
      gameState.input(ikMoveLeft)
    if isKeyDown(Right):
      gameState.input(ikMoveRight)

  var
    lastTime: float64
    delta: float64
  while not windowShouldClose():
    let time = getTime()
    delta += time - lastTime
    lastTime = time

    if delta >= 1 / ticksPerSecond:
      input()
      if not gameState.tick(1 / ticksPerSecond): closeWindow()

      #if gameState.baitStage.time <= 0:
      #  music.stop()
      #elif gameState.baitStage.time < 30:
      #  music.pitch = 1.5

      # unsafe if the thread somehow gets here between animations getting added to the seq?
      for anim in animations:
        discard anim[].next(1 / ticksPerSecond)
      draw()

      delta = 0