import math
import tables
import random
import strformat

import sdl2
import sdl2/image
import sdl2/gfx
import sdl2/ttf
import sdl2/mixer

import anim
import game/gamestate
import game/baitstage/bait

const
  viewWidth = 640
  viewHeight = 480
  defaultScale = 2
  ticksPerSecond = 60

type
  Keys = Table[cint, bool]
  Params = object
    animations: seq[ptr Animation]

when isMainModule:
  var
    running = true
    window: WindowPtr
    renderer: RendererPtr
    context: GlContextPtr
    game: ptr Game

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
      while pollEvent(e):
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
        game.paused = not game.paused
      if keysPressed.check(K_Z):
        game[].input(ikInteract)

      if keysHeld.check(K_UP):
        game[].input(ikMoveUp)
      if keysHeld.check(K_DOWN):
        game[].input(ikMoveDown)
      if keysHeld.check(K_LEFT):
        game[].input(ikMoveLeft)
      if keysHeld.check(K_RIGHT):
        game[].input(ikMoveRight)

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
        if not game[].tick(1 / ticksPerSecond): running = false

        #if game.baitStage.time <= 0:
        #  discard haltMusic()
        #elif gameState.baitStage.time < 30:
        #  music.pitch = 1.5

        # unsafe if the thread somehow gets here between animations getting added to the seq?
        for anim in params.animations:
          discard anim[].next(1 / ticksPerSecond)

        delta = delta mod (1 / ticksPerSecond)

  proc renderThread(params: ptr Params) {.thread.} =

    proc rect(x, y, w, h: SomeNumber): Rect =
      sdl2.rect(x.cint, y.cint, w.cint, h.cint)

    proc renderText(font: FontPtr; text: string; x, y: SomeNumber; colour: Color) =
      let
        surText = font.renderTextSolid(text.cstring, colour)
        texText = renderer.createTextureFromSurface(surText)
        dest = rect(x, y, surText.w, surText.h)
      renderer.copy(texText, nil, dest.addr)
      freeSurface(surText)
      destroyTexture(texText)

    let
      black = color(0x00, 0x00, 0x00, 0xff)
      white = color(0xff, 0xff, 0xff, 0xff)
      lightBlue = color(0x00, 0x99, 0xff, 0xff)

    let
      texGirl = loadTexture(renderer, "res/girl.png")
      texBaitman = loadTexture(renderer, "res/baitman.png")
      texWall = loadTexture(renderer, "res/wall.png")
      texFish = loadTexture(renderer, "res/mika.png")
      texHook = loadTexture(renderer, "res/hook.png")
      texPelletBag = loadTexture(renderer, "res/pelletBag.png")

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
      target = renderer.createTexture(SDL_PIXELFORMAT_RGBA8888, SDL_TEXTUREACCESS_TARGET, viewWidth, viewHeight)
      src: Rect
      dest: Rect

    discard window.glMakeCurrent(context)
    while running:
      renderer.setRenderTarget(target)

      case game.currentStage
      of csWalk:
        renderer.setDrawColor(lightBlue)
        renderer.clear()

        let
          girl = game.walkStage.girl
          frame = animGirlDown.getFrame()
        src = rect(frame[0], frame[1], frame[2], frame[3])
        dest = rect(girl.entity.pos[0] * 16 - 16, girl.entity.pos[1] * 16 - 16, 32, 32)
        renderer.copy(texGirl, src.addr, dest.addr)

        renderer.setDrawColor(black)
        for wall in game.walkStage.level.walls:
          renderer.drawLine(
            (wall[0][0] * 16).cint,
            (wall[0][1] * 16).cint,
            (wall[1][0] * 16).cint,
            (wall[1][1] * 16).cint
          )

      of csBait:
        renderer.setDrawColor(black)
        renderer.clear()

        for y, row in game.baitStage.level.tiles:
          for x, tile in row:
            if tile == tkWall:
              dest = rect(x * 16, y * 16, 16, 16)
              renderer.copy(texWall, nil, dest.addr)

        for y, row in game.baitStage.level.moveGrid:
          for x, node in row:
            case node.item:
            of ikPellet:
              renderer.filledCircleColor(x.int16 * 16, y.int16 * 16, 3, 0xff00eeff.uint32)
            of ikBigPellet:
              renderer.filledCircleColor(x.int16 * 16, y.int16 * 16, 6, 0xff66eeff.uint32)
            of ikNone: discard
        
        for i in 0..game.baitStage.abilities.high:
          # this is probably unsafe
          if i > game.baitStage.abilities.high:
            continue
          let ability = game.baitStage.abilities[i]
          case ability.kind
          of akBigPellet:
            dest = rect(ability.entity.pos[0] * 16 - 16, ability.entity.pos[1] * 16 - 16, 32, 32)
            renderer.copy(texPelletBag, nil, dest.addr)
          of akNone: discard
        
        for i in 0..game.baitStage.hooks.high:
          # this too
          if i > game.baitStage.hooks.high:
            continue
          let hook = game.baitStage.hooks[i]
          dest = rect(hook.entity.pos[0] * 16 - 16, hook.entity.pos[1] * 16 - 16, 32, 32)
          renderer.copy(texHook, nil, dest.addr)
        
        for i in 0..game.baitStage.fish.high:
          # this too
          if i > game.baitStage.fish.high:
            continue
          let fish = game.baitStage.fish[i]
          dest = rect(fish.entity.pos[0] * 16 - 16, fish.entity.pos[1] * 16 - 16, 32, 32)
          renderer.copy(texFish, nil, dest.addr)

        let
          baitman = game.baitStage.baitman
          frame = animBaitman.getFrame()
        src = rect(frame[0], frame[1], frame[2], frame[3])
        dest = rect(baitman.entity.pos[0] * 16 - 16, baitman.entity.pos[1] * 16 - 16, 32, 32)
        renderer.copy(texBaitman, src.addr, dest.addr)

        renderText(font, fmt"{game.baitStage.time.int:03}", 2, 454, white)
        renderText(font, fmt"{game.baitStage.score:06}", 496, 454, white)

        let abilitySquare = rect(88, 452, 24, 24)
        renderer.setDrawColor(white)
        renderer.drawRect(abilitySquare.addr)
        case game.baitStage.currentAbility
        of akBigPellet:
          renderer.filledCircleColor(100, 464, 6, 0xff66eeff.uint32)
        of akNone: discard 

      renderer.setRenderTarget(nil)
      
      src = rect(0, 0, viewWidth, viewHeight)
      var
        windowWidth: cint
        windowHeight: cint
      window.getSize(windowWidth, windowHeight)
      let targetScale = min(windowWidth.float / viewWidth, windowHeight.float / viewHeight)
      dest = rect(
        (windowWidth.float - viewWidth * targetScale) * 0.5,
        (windowHeight.float - viewHeight * targetScale) * 0.5,
        viewWidth * targetScale,
        viewHeight * targetScale
      )
      renderer.copy(target, src.addr, dest.addr)

      renderer.present()

  proc sdlErr(msg: string) =
    raise Defect.newException(msg & ", SDL error " & $getError())

  randomize()

  var
    params = create(Params)
    thr: system.Thread[ptr Params]

  game = create(Game)
  game[].init()

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
  context = window.glCreateContext()
  if context == nil:
    sdlErr "GL context could not be created"

  discard openAudio(44100, MIX_DEFAULT_FORMAT, 2, 2048)

  #var music = loadMUS("res/huhh.wav")
  #discard music.playMusic(-1)

  discard window.glMakeCurrent(nil)
  createThread(thr, renderThread, params)

  logicThread(params)

  joinThread(thr)

  glDeleteContext(context)
  destroyRenderer(renderer)
  destroyWindow(window)

  dealloc(params)
  dealloc(game)