import math

type
  Vec*[N, T] = array[N, T]
  Vec2*[T] = Vec[2, T]
  Vec3*[T] = Vec[3, T]
  Vec4*[T] = Vec[4, T]
  Vec2f* = Vec2[float64]
  Vec3f* = Vec3[float64]
  Vec4f* = Vec4[float64]

proc `$`*[N, T](v: Vec[N, T]): string =
  result = "["
  for i in 0..N.high:
    if i != 0:
      result &= ", "
    result &= $v[i]
  result &= "]"

func x*[N, T](v: Vec[N, T]): T = v[0]

func y*[N, T](v: Vec[N, T]): T = v[1]

func z*[N, T](v: Vec[N, T]): T = v[2]

func w*[N, T](v: Vec[N, T]): T = v[3]

func `+`*[N, T](v1, v2: Vec[N, T]): Vec[N, T] =
  for i in 0..N.high:
    result[i] = v1[i] + v2[i]

func `-`*[N, T](v1, v2: Vec[N, T]): Vec[N, T] =
  for i in 0..N.high:
    result[i] = v1[i] - v2[i]

func `*`*[N, T](v: Vec[N, T]; val: T): Vec[N, T] =
  for i in 0..N.high:
    result[i] = v[i] * val

func `/`*[N, T](v: Vec[N, T]; val: T): Vec[N, T] =
  for i in 0..N.high:
    result[i] = v[i] / val

func len2*[N, T](v: Vec[N, T]): T =
  for i in 0..v.high: result += pow(v[i], 2)

func len*[N, T](v: Vec[N, T]): T =
  sqrt(v.len2)

func normalised*[N, T](v: Vec[N, T]): Vec[N, T] =
  let len = v.len
  if len > 0:
    v / len
  else:
    v