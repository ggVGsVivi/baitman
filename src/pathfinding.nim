import algorithm
import sets
import heapqueue

type Node[T] = object
  n: T
  prevI: int
  totalDist: float

func `<`*(a, b: Node): bool =
  a.totalDist < b.totalDist

func node[T](n: T; prevI: int; totalDist: float): Node[T] =
  result.n = n
  result.prevI = prevI
  result.totalDist = totalDist

func calculatePath*[T](
  src, dest: T;
  connectProc: proc(n: T): seq[(T, float)] {.noSideEffect.}
): seq[T] =
  ## Returns an optimal path of nodes (type T) between a source and a destination.
  ## Uses a custom proc to obtain a seq of connected nodes and their distances.
  ## Path does not include the source node.
  var
    next: HeapQueue[Node[T]]
    cache: HashSet[T]
    tail: seq[Node[T]]
  next.push(node(src, -1, 0))
  while next.len > 0:
    let curr = next.pop()
    if curr.n == dest:
      result.add(curr.n)
      var
        p = curr.prevI
      while true:
        let n = tail[p]
        p = n.prevI
        if p == -1: break
        result.add(n.n)
      result.reverse()
      break
    tail.add(curr)
    for (c, d) in connectProc(curr.n):
      if cache.contains(c): continue
      next.push(node(c, tail.high, curr.totalDist + d))
      cache.incl(c)
