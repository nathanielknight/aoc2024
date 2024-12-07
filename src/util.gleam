import gleam/int
import gleam/list
import gleam/otp/task

pub fn unsafe_parse_int(src: String) -> Int {
  let assert Ok(n) = int.parse(src)
  n
}

type Point =
  #(Int, Int)

pub fn add_points(p1: Point, p2: Point) -> Point {
  #(p1.0 + p2.0, p1.1 + p2.1)
}

pub fn pmap(ts: List(t), f: fn(t) -> u) -> List(u) {
  ts
  |> list.map(fn(t) { task.async(fn() { f(t) }) })
  |> list.map(task.await_forever)
}
