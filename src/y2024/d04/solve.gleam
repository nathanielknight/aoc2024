import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

pub type Point =
  #(Int, Int)

pub type WordSearch =
  Dict(Point, String)

pub fn parse_src(src: String) -> WordSearch {
  src
  |> string.split("\n")
  |> list.index_map(fn(line, line_number) {
    line
    |> string.to_graphemes
    |> list.index_map(fn(char, col) { #(#(col, line_number), char) })
  })
  |> list.flatten
  |> dict.from_list
}

pub fn add_points(p1: Point, p2: Point) -> Point {
  #(p1.0 + p2.0, p1.1 + p2.1)
}

const search_directions = [
  #(1, 0), #(1, 1), #(0, 1), #(-1, 1), #(-1, 0), #(-1, -1), #(0, -1), #(1, -1),
]

/// How many times does `word` occur at `start` in `ws`.
pub fn search_at(ws: WordSearch, start: Point, word: List(String)) -> Int {
  search_directions
  |> list.map(search_at_direction(ws, start, word, _))
  |> list.count(fn(found) { found })
}

/// Does `word` occur at `start` in `ws` in `direction`
pub fn search_at_direction(
  ws: WordSearch,
  start: Point,
  word: List(String),
  direction: Point,
) -> Bool {
  let indices = line_from(start, direction, list.length(word))
  let ws_letters =
    indices
    |> list.map(dict.get(ws, _))
    |> result.all
  case ws_letters {
    Error(Nil) -> False
    Ok(letters) -> letters == word
  }
}

pub fn line_from(start: Point, direction: Point, length: Int) -> List(Point) {
  do_line_from(start, direction, length, [])
  |> list.reverse
}

fn do_line_from(
  start: Point,
  direction: Point,
  length: Int,
  points: List(Point),
) -> List(Point) {
  case length {
    0 -> points
    n ->
      do_line_from(add_points(start, direction), direction, n - 1, [
        start,
        ..points
      ])
  }
}

fn solve_part_1(input: WordSearch) -> Int {
  let word = string.to_graphemes("XMAS")
  let points = dict.keys(input)
  points
  |> list.map(search_at(input, _, word))
  |> int.sum
}

fn diagonals(start: Point) -> #(List(Point), List(Point)) {
  #(
    line_from(add_points(#(-1, -1), start), #(1, 1), 3),
    line_from(add_points(#(-1, 1), start), #(1, -1), 3),
  )
}

fn xmas_search_at(ws: WordSearch, start: Point) -> Bool {
  let #(diag1_pts, diag2_pts) = diagonals(start)

  let check_xmas = fn(pts: List(Point)) -> Bool {
    case get_seq(ws, pts) {
      Error(Nil) -> False
      Ok(letters) -> letters == ["M", "A", "S"] || letters == ["S", "A", "M"]
    }
  }

  check_xmas(diag1_pts) && check_xmas(diag2_pts)
}

fn get_seq(d: Dict(Point, t), ks: List(Point)) -> Result(List(t), Nil) {
  ks |> list.map(dict.get(d, _)) |> result.all
}

fn solve_part_2(input: WordSearch) {
  input
  |> dict.keys
  |> list.map(xmas_search_at(input, _))
  |> list.count(fn(b) { b })
}

const example_source = "MMMSXXMASM
MSAMXMSMSA
AMXSXMAAMM
MSAMASMSMX
XMASAMXAMM
XXAMMXXAMA
SMSMSASXSS
SAXAMASAAA
MAMMMXMMMM
MXMXAXMASX"

pub fn main() {
  let example_input = parse_src(example_source)
  let assert Ok(source) = simplifile.read("src/y2024/d04/input.txt")
  let input = parse_src(source)

  solve_part_1(example_input)
  |> io.debug
  solve_part_2(example_input)
  |> io.debug

  solve_part_1(input)
  |> io.debug
  solve_part_2(input)
  |> io.debug
}
