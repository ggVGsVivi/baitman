import random
import strformat

import csfml
import csfml/audio

import anim
import game
import bait
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
    animations: seq[ptr Animation]

proc processEvents(window: RenderWindow; keyCallbacks: KeyCallbacks; keysHeld: var KeysHeld) =
  var e: Event
  while window.pollEvent(e): # add --passC:-fno-stack-protector with -d:release otherwise this crashes
    case e.kind
    of EventType.Closed: window.close()
    of EventType.KeyPressed:
      let keycode = e.key.code
      if not keysHeld[keycode] and keyCallbacks[keycode] != nil:
        keyCallbacks[keycode]()
      keysHeld[keycode] = true
    of EventType.KeyReleased:
      let keycode = e.key.code
      keysHeld[keycode] = false
    else: discard

proc renderThread(params: ptr RenderParams) {.thread.} =
  # TODO move this mess
  let
    texGirl = newTexture("res/girl.png")
    texWall = newTexture("res/wall.png")
    texFish = newTexture("res/fish.png")
    texHook = newTexture("res/hook.png")
    texPelletBag = newTexture("res/pelletBag.png")

  var pelletCircle = newCircleShape(3)
  pelletCircle.origin = vec2(3, 3)
  pelletCircle.fillColor = color(0xff, 0xee, 0)

  var bigPelletCircle = newCircleShape(6)
  bigPelletCircle.origin = vec2(6, 6)
  bigPelletCircle.fillColor = color(0xff, 0xee, 0x66)

  var abilitySquare = newRectangleShape(vec2(24, 24))
  abilitySquare.position = vec2(88, 452)
  abilitySquare.outlineThickness = 2
  abilitySquare.outlineColor = White
  abilitySquare.fillColor = Black

  var animGirlDown = Animation(
      sprite: newSprite(texGirl),
      size: (32, 32),
      offsets: @[(0, 0), (32, 0), (0, 0), (64, 0)],
      speed: 4,
      repeat: true,
    )
  animGirlDown.sprite.origin = vec2(16, 16)
  params.animations.add(animGirlDown.addr)

  var animFish = Animation(
      sprite: newSprite(texFish),
      size: (32, 32),
      offsets: @[(0, 0)],
      speed: 0,
      repeat: true,
    )
  animFish.sprite.origin = vec2(16, 16)
  params.animations.add(animFish.addr)

  var sprWall = newSprite(texWall)

  var sprHook = newSprite(texHook)
  sprHook.origin = vec2(16, 16)

  var sprPelletBag = newSprite(texPelletBag)
  sprPelletBag.origin = vec2(16, 16)

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

  discard (params.window.active = true)
  while params.window.open:
    params.window.clear(Black)

    for y, row in params.game.baitStage.level.tiles:
      for x, tile in row:
        if tile == tkWall:
          sprWall.position = vec2(x * 16, y * 16)
          params.window.draw(sprWall)

    for y, row in params.game.baitStage.level.moveGrid:
      for x, node in row:
        case node.item:
        of ikPellet:
          pelletCircle.position = vec2(x * 16, y * 16)
          params.window.draw(pelletCircle)
        of ikBigPellet:
          bigPelletCircle.position = vec2(x * 16, y * 16)
          params.window.draw(bigPelletCircle)
        of ikNone: discard
    
    for i in 0..params.game.baitStage.abilities.high:
      # this is probably unsafe
      if i > params.game.baitStage.abilities.high: continue
      let ability = params.game.baitStage.abilities[i]
      case ability.kind
      of akBigPellet:
        sprPelletBag.position = vec2(
          ability.entity.pos[0] * 16,
          ability.entity.pos[1] * 16
        )
        params.window.draw(sprPelletBag)
      of akNone: discard
    
    for i in 0..params.game.baitStage.hooks.high:
      # this too
      if i > params.game.baitStage.hooks.high: continue
      let hook = params.game.baitStage.hooks[i]
      sprHook.position = vec2(
        hook.entity.pos[0] * 16,
        hook.entity.pos[1] * 16
      )
      params.window.draw(sprHook)
    
    for i in 0..params.game.baitStage.fish.high:
      # this too
      if i > params.game.baitStage.fish.high: continue
      let fish = params.game.baitStage.fish[i]
      animFish.sprite.position = vec2(
        fish.entity.pos[0] * 16,
        fish.entity.pos[1] * 16
      )
      params.window.draw(animFish.sprite)
       
    animGirlDown.sprite.position = vec2(
      params.game.baitStage.baitman.entity.pos[0] * 16,
      params.game.baitStage.baitman.entity.pos[1] * 16
    )
    params.window.draw(animGirlDown.sprite)

    timeText.str = fmt"{params.game.baitStage.time.int:03}"
    params.window.draw(timeText)
    scoreText.str = fmt"{params.game.baitStage.score:06}"
    params.window.draw(scoreText)

    params.window.draw(abilitySquare)
    case params.game.baitStage.currentAbility
    of akBigPellet:
      bigPelletCircle.position = vec2(100, 464)
      params.window.draw(bigPelletCircle)
    of akNone: discard 

    params.window.display()

when isMainModule:
  randomize()

  var
    gameState: Game
    window: RenderWindow
    thr: system.Thread[ptr RenderParams]
  
  gameState.init()

  window = newRenderWindow(videoMode(viewWidth * defaultScale, viewHeight * defaultScale), "Baitman", WindowStyle.Default, contextSettings())
  window.verticalSyncEnabled = true

  var music = newMusic("res/huhh.wav")
  music.loop = true
  music.play()

  var view = newView(rect(0, 0, viewWidth, viewHeight));
  window.view = view
  
  var renderParams = RenderParams(
    window: window,
    game: gameState.addr,
  )

  discard (window.active = false)
  createThread(thr, renderThread, renderParams.addr)

  var keyCallbacks: KeyCallbacks
  keyCallbacks[KeyCode.Escape] = proc() = 
    window.close()
  keyCallbacks[KeyCode.Space] = proc() =
    gameState.paused = not gameState.paused
  keyCallbacks[KeyCode.Z] = proc() =
    gameState.input(ikInteract)

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

      if gameState.baitStage.time <= 0:
        music.stop()
      elif gameState.baitStage.time < 30:
        music.pitch = 1.5

      # unsafe if the thread somehow gets here between animations getting added to the seq?
      for anim in renderParams.animations:
        discard anim[].next(1 / ticksPerSecond)

      delta = 0

  joinThread(thr)