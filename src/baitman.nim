import tables
import random
import strformat

import sdl2
import sdl2/image
import sdl2/gfx
import sdl2/ttf
import sdl2/mixer

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
  Keys = Table[cint, bool]
  Params = object
    window: WindowPtr
    renderer: RendererPtr
    game: ptr Game
    animations: seq[ptr Animation]

when isMainModule:
  var running = true

  proc logicThread(params: ptr Params) {.thread.} =

    var
      keysPressed: Keys
      keysReleased: Keys
      keysHeld: Keys

    func check(keys: Keys; key: cint): bool =
      key in keys and keys[key]

    proc processEvents() =
      keysPressed = Keys()
      keysReleased = Keys()
      var e: Event
      while pollEvent(e): # add --passC:-fno-stack-protector with -d:release otherwise this crashes
        case e.kind
        of EventType.QuitEvent:
          running = false
        of EventType.KeyDown:
          let keycode = e.key.keysym.sym
          if not keysHeld.check(keycode):
            keysPressed[keycode] = true
          keysHeld[keycode] = true
        of EventType.KeyUp:
          let keycode = e.key.keysym.sym
          if keysHeld.check(keycode):
            keysReleased[keycode] = true
          keysHeld[keycode] = false
        else: discard

    proc input() =
      if keysPressed.check(K_ESCAPE):
        running = false
      if keysPressed.check(K_SPACE):
        params.game.paused = not params.game.paused
      if keysPressed.check(K_Z):
        params.game[].input(ikInteract)

      if keysHeld.check(K_UP):
        params.game[].input(ikMoveUp)
      if keysHeld.check(K_DOWN):
        params.game[].input(ikMoveDown)
      if keysHeld.check(K_LEFT):
        params.game[].input(ikMoveLeft)
      if keysHeld.check(K_RIGHT):
        params.game[].input(ikMoveRight)

    var
      lastTime: float64
      delta: float64
    while running:
      let time = getTicks().float64 / 1000
      delta += time - lastTime
      lastTime = time

      if delta >= 1 / ticksPerSecond:
        processEvents()
        input()
        if not params.game[].tick(1 / ticksPerSecond): running = false

        #if gameState.baitStage.time <= 0:
        #  music.stop()
        #elif gameState.baitStage.time < 30:
        #  music.pitch = 1.5

        # unsafe if the thread somehow gets here between animations getting added to the seq?
        for anim in params.animations:
          discard anim[].next(1 / ticksPerSecond)

        delta = 0


  proc renderThread(params: ptr Params) {.thread.} =

    template rect(x, y, w, h: untyped): untyped =
      sdl2.rect(x.cint, y.cint, w.cint, h.cint)

    let
      black = color(0x00, 0x00, 0x00, 0xff)
      white = color(0xff, 0xff, 0xff, 0xff)

    let
      texGirl = loadTexture(params.renderer, "res/girl.png")
      texBaitman = loadTexture(params.renderer, "res/baitman.png")
      texWall = loadTexture(params.renderer, "res/wall.png")
      texFish = loadTexture(params.renderer, "res/fish.png")
      texHook = loadTexture(params.renderer, "res/hook.png")
      texPelletBag = loadTexture(params.renderer, "res/pelletBag.png")

    var animGirlDown = Animation(
      size: (32, 32),
      offsets: @[(0, 0), (32, 0), (0, 0), (64, 0)],
      speed: 4,
      repeat: true,
    )
    params.animations.add(animGirlDown.addr)

    var animBaitman = Animation(
      size: (32, 32),
      offsets: @[(0, 0), (32, 0)],
      speed: 6,
      repeat: true,
    )
    params.animations.add(animBaitman.addr)

    var animFish = Animation(
      size: (32, 32),
      offsets: @[(0, 0)],
      speed: 0,
      repeat: true,
    )
    params.animations.add(animFish.addr)

    var
      font = openFont("res/font.ttf", 24)

    var
      target = params.renderer.createTexture(SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, viewWidth, viewHeight)
      src: Rect
      dest: Rect

    while running:
      params.renderer.setRenderTarget(target)

      params.renderer.setDrawColor(black)
      params.renderer.clear()

      for y, row in params.game.baitStage.level.tiles:
        for x, tile in row:
          if tile == tkWall:
            dest = rect(x * 16, y * 16, 16, 16)
            params.renderer.copy(texWall, nil, dest.addr)

      for y, row in params.game.baitStage.level.moveGrid:
        for x, node in row:
          case node.item:
          of ikPellet:
            params.renderer.filledCircleColor(x.int16 * 16, y.int16 * 16, 3, 0xff00eeff.uint32)
          of ikBigPellet:
            params.renderer.filledCircleColor(x.int16 * 16, y.int16 * 16, 6, 0xff66eeff.uint32)
          of ikNone: discard
      
      for i in 0..params.game.baitStage.abilities.high:
        # this is probably unsafe
        if i > params.game.baitStage.abilities.high:
          continue
        let ability = params.game.baitStage.abilities[i]
        case ability.kind
        of akBigPellet:
          dest = rect(ability.entity.pos[0] * 16 - 16, ability.entity.pos[1] * 16 - 16, 32, 32)
          params.renderer.copy(texPelletBag, nil, dest.addr)
        of akNone: discard
      
      for i in 0..params.game.baitStage.hooks.high:
        # this too
        if i > params.game.baitStage.hooks.high:
          continue
        let hook = params.game.baitStage.hooks[i]
        dest = rect(hook.entity.pos[0] * 16 - 16, hook.entity.pos[1] * 16 - 16, 32, 32)
        params.renderer.copy(texHook, nil, dest.addr)
      
      for i in 0..params.game.baitStage.fish.high:
        # this too
        if i > params.game.baitStage.fish.high:
          continue
        let fish = params.game.baitStage.fish[i]
        dest = rect(fish.entity.pos[0] * 16 - 16, fish.entity.pos[1] * 16 - 16, 32, 32)
        params.renderer.copy(texFish, nil, dest.addr)

      let
        baitman = params.game.baitStage.baitman
        frame = animBaitman.getFrame()
      src = rect(frame[0], frame[1], frame[2], frame[3])
      dest = rect(baitman.entity.pos[0] * 16 - 16, baitman.entity.pos[1] * 16 - 16, 32, 32)
      params.renderer.copy(texBaitman, src.addr, dest.addr)
      
      let
        surTimeText = font.renderTextSolid(fmt"{params.game.baitStage.time.int:03}".cstring, white)
        texTimeText = params.renderer.createTextureFromSurface(surTimeText)
      dest = rect(2, 454, surTimeText.w, surTimeText.h)
      params.renderer.copy(texTimeText, nil, dest.addr)
      freeSurface(surTimeText)
      destroyTexture(texTimeText)

      let
        surScoreText = font.renderTextSolid(fmt"{params.game.baitStage.score:06}".cstring, white)
        texScoreText = params.renderer.createTextureFromSurface(surScoreText)
      dest = rect(496, 454, surScoreText.w, surScoreText.h)
      params.renderer.copy(texScoreText, nil, dest.addr)
      freeSurface(surScoreText)
      destroyTexture(texScoreText)

      let abilitySquare = rect(88, 452, 24, 24)
      params.renderer.setDrawColor(white)
      params.renderer.drawRect(abilitySquare.addr)
      case params.game.baitStage.currentAbility
      of akBigPellet:
        params.renderer.filledCircleColor(100, 464, 6, 0xff66eeff.uint32)
      of akNone: discard 

      params.renderer.setRenderTarget(nil)
      src = rect(0, 0, viewWidth, viewHeight)
      dest = rect(0, 0, 0, 0)
      params.window.getSize(dest.w, dest.h)
      params.renderer.copy(target, src.addr, dest.addr)

      params.renderer.present()

  proc sdlErr(msg: string) =
    raise Defect.newException(msg & ", SDL error " & $getError())

  randomize()

  var
    gameState: Game
    window: WindowPtr
    renderer: RendererPtr
    thr: system.Thread[ptr Params]
  
  gameState.init()

  if not sdl2.init(INIT_EVERYTHING):
    sdlErr "SDL2 initialization failed"
  if not ttfInit():
    sdlErr "SDL2_ttf initialization failed"

  window = createWindow(
    "Baitman",
    SDL_WINDOWPOS_CENTERED,
    SDL_WINDOWPOS_CENTERED,
    viewWidth * defaultScale,
    viewHeight * defaultScale,
    SDL_WINDOW_SHOWN or SDL_WINDOW_RESIZABLE
  )
  if window == nil:
    sdlErr "Window could not be created"
  renderer = window.createRenderer(-1, Renderer_Accelerated or Renderer_PresentVsync)
  if renderer == nil:
    sdlErr "Renderer could not be created"

  discard openAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048)

  var music = loadMUS("res/huhh.wav")
  discard music.playMusic(-1)
  
  var renderParams = Params(
    window: window,
    renderer: renderer,
    game: gameState.addr,
  )

  createThread(thr, logicThread, renderParams.addr)

  renderThread(renderParams.addr)

  joinThread(thr)