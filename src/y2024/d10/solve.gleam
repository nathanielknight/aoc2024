import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set.{type Set}
import gleam/string
import simplifile
import util.{type Point}

const example_source = "89010123
78121874
87430965
96549874
45678903
32019012
01329801
10456732"

type Input =
  Dict(Point, Int)

type HeightCoord =
  #(Point, Int)

fn parse_source(source: String) -> Input {
  let parse_line = fn(line: String, y: Int) -> Input {
    line
    |> string.to_graphemes
    |> list.index_map(fn(c, x) {
      case int.parse(c) {
        Ok(n) -> Ok(#(#(x, y), n))
        Error(Nil) -> Error(Nil)
      }
    })
    |> result.values
    |> dict.from_list
  }

  source
  |> string.split("\n")
  |> list.index_map(parse_line)
  |> list.fold(dict.new(), dict.merge)
}

type HikingSearch {
  HikingSearch(
    map: Input,
    members: Set(HeightCoord),
    boundary: List(HeightCoord),
    predicate: fn(Int, Int) -> Bool,
    start: HeightCoord,
  )
}

fn hikingsearch(map: Input, start: Point) -> HikingSearch {
  let predicate = fn(a, b) { b == a + 1 }
  do_hikingsearch(
    HikingSearch(
      map: map,
      members: set.from_list([#(start, 0)]),
      boundary: neighbors_of(map, start)
        |> list.filter(fn(p) { predicate(0, p.1) }),
      predicate: predicate,
      start: #(start, 0),
    ),
  )
}

fn do_hikingsearch(search: HikingSearch) -> HikingSearch {
  case next_boundary(search) {
    [] ->
      HikingSearch(
        ..search,
        members: set.union(search.members, set.from_list(search.boundary)),
      )
    b ->
      do_hikingsearch(
        HikingSearch(
          ..search,
          members: set.union(search.members, set.from_list(search.boundary)),
          boundary: b,
        ),
      )
  }
}

fn next_boundary(search: HikingSearch) -> List(HeightCoord) {
  search.boundary
  |> list.map(fn(coord) {
    neighbors_of(search.map, coord.0)
    |> list.filter(fn(neighbor) { search.predicate(coord.1, neighbor.1) })
  })
  |> list.flatten
  |> list.unique
}

fn neighbors_of(map: Input, p: Point) -> List(HeightCoord) {
  p
  |> orthogonal_adjacents
  |> list.map(fn(p) {
    dict.get(map, p)
    |> result.map(fn(v) { #(p, v) })
  })
  |> result.values
}

fn orthogonal_adjacents(p: Point) -> List(Point) {
  let #(x, y) = p
  [#(x + 1, y), #(x, y + 1), #(x - 1, y), #(x, y - 1)]
}

fn score_trail(trail: Set(HeightCoord)) -> Int {
  trail
  |> set.filter(fn(p) { p.1 == 9 })
  |> set.size
}

type TrailPaths {
  Step(s: HeightCoord, next: List(TrailPaths))
  End(s: HeightCoord)
}

fn trail_path_from(map: Dict(Point, Int), hc: HeightCoord) -> TrailPaths {
  let nexts =
    neighbors_of(map, hc.0)
    |> list.filter(fn(c) { c.1 == hc.1 + 1 })
  case nexts {
    [] -> End(hc)
    _ -> Step(hc, next: list.map(nexts, trail_path_from(map, _)))
  }
}

fn score_trail_paths(ps: TrailPaths) -> Int {
  case ps {
    // summit!
    End(#(_, 9)) -> 1
    // dead end
    End(_) -> 0
    Step(_, next) -> next |> list.map(score_trail_paths) |> int.sum
  }
}

fn solve_part_1(input: Input) {
  let trailheads =
    input
    |> dict.to_list
    |> list.filter_map(fn(hc) {
      case hc.1 == 0 {
        True -> Ok(hc.0)
        False -> Error(Nil)
      }
    })
  trailheads
  |> list.map(hikingsearch(input, _))
  |> list.map(fn(s) { score_trail(s.members) })
  |> int.sum
}

fn solve_part_2(input: Input) {
  let trailheads =
    input
    |> dict.to_list
    |> list.filter_map(fn(hc) {
      case hc.1 == 0 {
        True -> Ok(hc.0)
        False -> Error(Nil)
      }
    })

  trailheads
  |> list.map(hikingsearch(input, _))
  |> list.map(fn(s) {
    let map = s.members |> set.to_list |> dict.from_list
    trail_path_from(map, s.start)
    |> score_trail_paths
  })
  |> int.sum
}

pub fn main() {
  let example_input = parse_source(example_source)
  let assert Ok(source) = simplifile.read("src/y2024/d10/input.txt")
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

fn debug_search(search: HikingSearch) -> HikingSearch {
  let max_x =
    search.map
    |> dict.keys
    |> list.map(fn(p) { p.0 })
    |> list.fold(from: -1, with: int.max)
  let max_y =
    search.map
    |> dict.keys
    |> list.map(fn(p) { p.1 })
    |> list.fold(from: -1, with: int.max)
  let index =
    search.members
    |> set.to_list
    |> dict.from_list

  list.range(from: 0, to: max_y)
  |> list.each(fn(y) {
    list.range(from: 0, to: max_x)
    |> list.each(fn(x) {
      case dict.get(index, #(x, y)) {
        Ok(h) -> io.print(int.to_string(h))
        Error(_) -> io.print(".")
      }
    })
    io.print("\n")
  })

  search
}
