import math

type
  Vec*[N, T] = array[N, T]
  Vec2*[T] = Vec[2, T]
  Vec3*[T] = Vec[3, T]
  Vec4*[T] = Vec[4, T]
  Vec2f* = Vec2[float64]
  Vec3f* = Vec3[float64]
  Vec4f* = Vec4[float64]
  Vec2i* = Vec2[int]
  Vec3i* = Vec3[int]
  Vec4i* = Vec4[int]

func `$`*[N, T](v: Vec[N, T]): string =
  result = "["
  for i in 0..N.high:
    if i != 0:
      result &= ", "
    result &= $v[i]
  result &= "]"

# idk how to do this using generics
converter toVec2f*(v: Vec2i): Vec2f = [v[0].float64, v[1].float64]
converter toVec2i*(v: Vec2f): Vec2i = [v[0].int, v[1].int]

template x*[N, T](v: Vec[N, T]): T = v[0]

template y*[N, T](v: Vec[N, T]): T = v[1]

template z*[N, T](v: Vec[N, T]): T = v[2]

template w*[N, T](v: Vec[N, T]): T = v[3]

func `+`*[N, T](v1, v2: Vec[N, T]): Vec[N, T] =
  for i in 0..N.high:
    result[i] = v1[i] + v2[i]

func `-`*[N, T](v1, v2: Vec[N, T]): Vec[N, T] =
  for i in 0..N.high:
    result[i] = v1[i] - v2[i]

func `*`*[N, T](v: Vec[N, T]; val: T): Vec[N, T] =
  for i in 0..N.high:
    result[i] = v[i] * val

func `/`*[N, T](v: Vec[N, T]; val: T): Vec[N, float64] =
  for i in 0..N.high:
    result[i] = v[i] / val

func sum*[N, T](v: Vec[N, T]): T =
  for i in 0..N.high:
    result += v[i]

func mag2*[N, T](v: Vec[N, T]): float64 =
  for i in 0..N.high:
    result += pow(v[i].float64, 2.0)

func mag*[N, T](v: Vec[N, T]): float64 =
  sqrt(v.mag2)

func norm*[N](v: Vec[N, float64]): Vec[N, float64] =
  let len = v.mag
  if len > 0:
    v / len
  else:
    v

func dot*[N, T](v1, v2: Vec[N, T]): float64 =
  for i in 0..N.high:
    result += v1[i] * v2[i]

func cos*[N, T](v1, v2: Vec[N, T]): float64 =
  dot(v1, v2) / (v1.mag * v2.mag)

func sin*[N, T](v1, v2: Vec[N, T]): float64 =
  sqrt(1 - pow(cos(v1, v2), 2))