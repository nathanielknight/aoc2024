import gleam/dict.{type Dict}
import gleam/io
import gleam/list
import gleam/option
import gleam/result
import gleam/set
import gleam/string
import simplifile
import util

const example_source = "............
........0...
.....0......
.......0....
....0.......
......A.....
............
............
........A...
.........A..
............
............"

type Point =
  #(Int, Int)

type Input {
  Input(range: Point, antennas: List(#(Point, String)))
}

fn parse_source(source: String) -> Input {
  let lines = string.split(source, "\n")
  let xrange = case list.first(lines) {
    Ok(l) -> string.length(l)
    Error(_) -> panic as "unreachable"
  }
  let yrange = list.length(lines)

  let assert Ok(antennas) =
    lines
    |> list.index_map(parse_line)
    |> list.reduce(list.append)

  Input(range: #(xrange, yrange), antennas: antennas)
}

fn parse_line(line: String, y: Int) -> List(#(Point, String)) {
  let cells = string.to_graphemes(line)
  cells
  |> list.index_map(fn(c, x) { #(#(x, y), c) })
  |> list.filter(fn(pair) { pair.1 != "." })
}

fn make_antenna_index(input: Input) -> Dict(String, List(Point)) {
  input.antennas
  |> list.fold(
    from: dict.new(),
    with: fn(idx: Dict(String, List(Point)), pt: #(Point, String)) -> Dict(
      String,
      List(Point),
    ) {
      dict.upsert(idx, pt.1, fn(maybe_list) {
        case maybe_list {
          option.None -> [pt.0]
          option.Some(l) -> [pt.0, ..l]
        }
      })
    },
  )
}

fn find_antinodes(points: List(Point), range: Point) -> List(Point) {
  let in_bounds = util.bounds_checker(range)

  points
  |> list.combination_pairs
  |> list.map(fn(p) { point_antinodes(p.0, p.1) })
  |> list.flatten
  |> list.filter(in_bounds)
}

fn point_antinodes(p1: Point, p2: Point) -> List(Point) {
  let c1 = util.add_points(p1, util.sub_points(p1, p2))
  let c2 = util.add_points(p2, util.sub_points(p2, p1))
  [c1, c2]
  |> list.filter(antinode_is_valid(p1, p2, _))
}

fn antinode_is_valid(p1: Point, p2: Point, node: Point) -> Bool {
  let d1 = util.rectilinear_distance(node, p1)
  let d2 = util.rectilinear_distance(node, p2)
  d1 == { 2 * d2 } || d2 == { 2 * d1 }
}

fn find_resonant_antinodes(points: List(Point), range: Point) -> List(Point) {
  let in_bounds = util.bounds_checker(range)

  points
  |> list.combination_pairs
  |> list.map(fn(p) { point_resonant_antinodes(p.0, p.1) })
  |> list.flatten
  |> list.filter(in_bounds)
}

fn point_resonant_antinodes(p1: Point, p2: Point) -> List(Point) {
  let d1 = util.sub_points(p1, p2)
  let d2 = util.sub_points(p2, p1)

  let range = list.range(from: 0, to: 50)

  let h1 =
    range
    |> list.map(fn(t) { util.add_points(p1, util.mul_points(d1, t)) })

  let h2 =
    range
    |> list.map(fn(t) { util.add_points(p2, util.mul_points(d2, t)) })

  list.flatten([h1, h2])
}

fn solve_part_1(input: Input) -> Int {
  let index = make_antenna_index(input)

  let assert Ok(count) =
    index
    |> dict.values
    |> list.map(fn(pts) { find_antinodes(pts, input.range) |> set.from_list })
    |> list.reduce(set.union)
    |> result.map(set.size)

  count
}

fn solve_part_2(input: Input) -> Int {
  let index = make_antenna_index(input)
  let assert Ok(count) =
    index
    |> dict.values
    |> list.map(fn(pts) {
      find_resonant_antinodes(pts, input.range) |> set.from_list
    })
    |> list.reduce(set.union)
    |> result.map(set.size)

  count
}

pub fn main() {
  let example_input = parse_source(example_source)
  let assert Ok(source) = simplifile.read("src/y2024/d08/input.txt")
  let input = parse_source(source)

  example_input
  |> solve_part_1
  |> io.debug

  example_input
  |> solve_part_2
  |> io.debug

  input
  |> solve_part_1
  |> io.debug

  input
  |> solve_part_2
  |> io.debug
}
