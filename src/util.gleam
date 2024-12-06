import gleam/int

pub fn unsafe_parse_int(src: String) -> Int {
  let assert Ok(n) = int.parse(src)
  n
}

type Point =
  #(Int, Int)

pub fn add_points(p1: Point, p2: Point) -> Point {
  #(p1.0 + p2.0, p1.1 + p2.1)
}
