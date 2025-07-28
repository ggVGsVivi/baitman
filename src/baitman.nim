import random
import strformat

import csfml

import game
import anim
import level

const
  viewWidth = 640
  viewHeight = 480
  defaultScale = 2
  ticksPerSecond = 60

type
  KeyCallbacks = array[KeyCode, proc()]
  KeysHeld = array[KeyCode, bool]
  RenderParams = object
    window: RenderWindow
    game: ptr Game
    girlAnim: Animation
    wallSprite: Sprite
    fishAnim: Animation
    hookSprite: Sprite
    timetext: Text
    scoreText: Text

proc processEvents(window: RenderWindow; keyCallbacks: KeyCallbacks; keysHeld: var KeysHeld) =
  var e: Event
  while window.pollEvent(e): # add with -d:release otherwise this crashes: --passC:-fno-stack-protector
    case e.kind
    of EventType.Closed: window.close()
    of EventType.KeyPressed:
      let keycode = e.key.code
      if keyCallbacks[keycode] != nil:
        keyCallbacks[keycode]()
      keysHeld[keycode] = true
    of EventType.KeyReleased:
      let keycode = e.key.code
      keysHeld[keycode] = false
    else: discard

proc renderThread(params: ptr RenderParams) {.thread, nimcall.} =
  var pelletCircle = newCircleShape(3)
  pelletCircle.origin = vec2(3, 3)
  pelletCircle.fillColor = color(0xff, 0xee, 0)

  # TODO fix this mess

  discard (params.window.active = true)
  while params.window.open:
    params.window.clear(Black)

    for y, row in params.game.baitStage.level.tiles:
      for x, tile in row:
        if tile == tkWall:
          params.wallSprite.position = vec2(x * 16, y * 16)
          params.window.draw(params.wallSprite)

    for y, row in params.game.baitStage.level.moveGrid:
      for x, node in row:
        case node.item:
        of ikPellet:
          pelletCircle.position = vec2(x * 16, y * 16)
          params.window.draw(pelletCircle)
        else: discard
        #if node.open:
        #  pelletCircle.position = vec2(x * 16, y * 16)
        #  params.window.draw(pelletCircle)
    
    for i in 0..params.game.baitStage.fish.high:
      # this is probably unsafe
      if i > params.game.baitStage.fish.high: continue
      let fish = params.game.baitStage.fish[i]
      params.fishAnim.sprite.position = vec2(
        fish.entity.pos[0] * 16,
        fish.entity.pos[1] * 16
      )
      params.window.draw(params.fishAnim.sprite)
    
    for i in 0..params.game.baitStage.hooks.high:
      # this too
      if i > params.game.baitStage.hooks.high: continue
      let hook = params.game.baitStage.hooks[i]
      params.hookSprite.position = vec2(
        hook.entity.pos[0] * 16,
        hook.entity.pos[1] * 16
      )
      params.window.draw(params.hookSprite)
       
    params.girlAnim.sprite.position = vec2(
      params.game.baitStage.baitman.entity.pos[0] * 16,
      params.game.baitStage.baitman.entity.pos[1] * 16
    )
    params.window.draw(params.girlAnim.sprite)
    params.timeText.str = fmt"{params.game.baitStage.time.int:03}"
    params.window.draw(params.timeText)
    params.scoreText.str = fmt"{params.game.baitStage.score:06}"
    params.window.draw(params.scoreText)

    params.window.display()

when isMainModule:
  let
    girlTexture = newTexture("res/girl.png")
    wallTexture = newTexture("res/wall.png")
    fishTexture = newTexture("res/fish.png")
    hookTexture = newTexture("res/hook.png")
  var
    animGirlDown = Animation(
      sprite: newSprite(girlTexture),
      size: (32, 32),
      offsets: @[(0, 0), (32, 0), (0, 0), (64, 0)],
      speed: 4 / ticksPerSecond,
      repeat: true,
    )
    #animGirlUp = Animation(
    #  sprite: newSprite(girlTexture),
    #  size: (32, 32),
    #  offsets: @[(0, 64), (32, 64), (0, 64), (64, 64)],
    #  speed: 4 / ticksPerSecond,
    #  repeat: true,
    #)
    animFish = Animation(
      sprite: newSprite(fishTexture),
      size: (32, 32),
      offsets: @[(0, 0)],
      speed: 0,
      repeat: true,
    )
    wallSprite = newSprite(wallTexture)
    hookSprite = newSprite(hookTexture)
  animGirlDown.sprite.origin = vec2(16, 16)
  hookSprite.origin = vec2(16, 16)
  animFish.sprite.origin = vec2(16, 16)

  randomize()

  var gameState: Game
  gameState.init()

  var
    window: RenderWindow
    thr: system.Thread[ptr RenderParams]

  window = newRenderWindow(videoMode(viewWidth * defaultScale, viewHeight * defaultScale), "Baitman", WindowStyle.Default, contextSettings())
  window.verticalSyncEnabled = true

  # double size and scaled down cause of antialiasing
  var
    font = newFont("res/font.ttf")
    scoreText = newText("000000", font, 48)
    timeText = newText("000", font, 48)
  scoreText.fillColor = White
  scoreText.position = vec2(496, 450)
  scoreText.scale = vec2(0.5, 0.5)
  timeText.fillColor = White
  timeText.position = vec2(2, 450)
  timeText.scale = vec2(0.5, 0.5)

  var view = newView(rect(0, 0, viewWidth, viewHeight));
  window.view = view
  
  var renderParams = RenderParams(
    window: window,
    game: gameState.addr,
    girlAnim: animGirlDown,
    wallSprite: wallSprite,
    fishAnim: animFish,
    hookSprite: hookSprite,
    scoreText: scoreText,
    timeText: timeText
  )

  discard (window.active = false)
  createThread(thr, renderThread, renderParams.addr)

  var keyCallbacks: KeyCallbacks
  keyCallbacks[KeyCode.Escape] = proc() = 
    window.close()
  keyCallbacks[KeyCode.Space] = proc() =
    gameState.paused = not gameState.paused

  var heldCallbacks: KeyCallbacks
  heldCallbacks[KeyCode.Up] = proc() =
    gameState.input(ikMoveUp)
  heldCallbacks[KeyCode.Down] = proc() =
    gameState.input(ikMoveDown)
  heldCallbacks[KeyCode.Left] = proc() =
    gameState.input(ikMoveLeft)
  heldCallbacks[KeyCode.Right] = proc() =
    gameState.input(ikMoveRight)

  var keysHeld: KeysHeld

  var
    clock = newClock()
    lastTime: Time
    delta: float64
  while window.open:
    let time = clock.elapsedTime
    delta += time.asSeconds - lastTime.asSeconds
    lastTime = time

    if delta >= 1 / ticksPerSecond:
      processEvents(window, keyCallbacks, keysHeld)
      for keycode, held in keysHeld:
        if heldCallbacks[keycode] != nil and held:
          heldCallbacks[keycode]()
      if not gameState.tick(1 / ticksPerSecond): window.close()

      discard animGirlDown.next()

      delta = 0

  joinThread(thr)