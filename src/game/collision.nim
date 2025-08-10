import space

type
  Line = array[2, Vec2f]

func closestPointOnLine(vP, vA, vB: Vec2f): Vec2f =
  let
    vAB = vB - vA
    vPA = vA - vP
    dotABPA = dot(vAB, vPA)
    dotABAB = dot(vAB, vAB)
    alpha = -dotABPA / dotABAB
  if alpha < 0:
    vA
  elif alpha > 1:
    vB
  else:
    vA * (1 - alpha) + vB * alpha

template closestPointOnLine(p: Vec2f; l: Line): untyped =
  closestPointOnLine(p, l[0], l[1])

func isLeft(vP, vA, vB: Vec2f): bool =
  let
    vAB = vB - vA
    vAP = vP - vA
  vAB.x * vAP.y - vAB.y * vAP.x > 0

template isLeft(p: Vec2f; l: Line): untyped =
  isLeft(p, l[0], l[1])

func collide*(pos: Vec2f; walls: seq[Line]; clipProc: proc(v: Vec2f): float64 {.noSideEffect.}): Vec2f =
  result = pos
  for wall in walls:
    if not pos.isLeft(wall):
      let 
        closest = closestPointOnLine(pos, wall)
        closestRel = pos - closest
        dist = closestRel.mag
        clip = clipProc(closest)
      if dist < clip:
        let
          wallDir = (wall[0] - wall[1]).norm
          pushDir = [-wallDir.y, wallDir.x]
          clipMag = clip - dist
          pushMag = clipMag
        result = result + pushDir * pushMag