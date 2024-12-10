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

pub fn sub_points(p1: Point, p2: Point) -> Point {
  #(p1.0 - p2.0, p1.1 - p2.1)
}

pub fn mul_points(p: Point, s: Int) -> Point {
  #(p.0 * s, p.1 * s)
}

pub fn rectilinear_distance(p1: Point, p2: Point) -> Int {
  { int.absolute_value(p2.1 - p1.1) } + { int.absolute_value(p2.0 - p1.0) }
}

pub fn pmap(ts: List(t), f: fn(t) -> u) -> List(u) {
  ts
  |> list.map(fn(t) { task.async(fn() { f(t) }) })
  |> list.map(task.await_forever)
}

pub fn bounds_checker(range: Point) -> fn(Point) -> Bool {
  fn(p: Point) -> Bool {
    p.0 >= 0 && p.0 < range.0 && p.1 >= 0 && p.1 < range.1
  }
}
