import algorithm
import sets
import heapqueue

type Node[T] = object
  n: T
  prevI: int
  totalDist: float

func `<`*(a, b: Node): bool =
  a.totalDist < b.totalDist

proc node[T](n: T; prevI: int; totalDist: float): ptr Node[T] =
  result = create(Node[T])
  result.n = n
  result.prevI = prevI
  result.totalDist = totalDist

proc calculatePath*[T, H](
  src: T;
  destCheckProc: proc(n: T): bool {.noSideEffect.};
  connectProc: proc(n: T): seq[(T, float)] {.noSideEffect.};
  hashProc: proc(n: T): H {.noSideEffect.}
): seq[T] =
  ## Returns an optimal path of nodes (type T) between a source and a destination.
  ## Uses custom procs to check for the destination and obtain a seq of connected nodes and their distances.
  ## Path does not include the source node.
  var
    next: HeapQueue[ptr Node[T]]
    cache: HashSet[H]
    tail: seq[ptr Node[T]]
  next.push(node(src, -1, 0))
  while next.len > 0:
    let curr = next.pop()
    if destCheckProc(curr.n):
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
      if hashProc(c) in cache: continue
      next.push(node(c, tail.high, curr.totalDist + d))
      cache.incl(hashProc(c))
  while tail.len > 0:
    var n = tail.pop()
    dealloc(n)
