import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/set
import gleam/string
import simplifile

type Point =
  #(Int, Int)

fn add_point(p1: Point, p2: Point) -> Point {
  #(p1.0 + p2.0, p1.1 + p2.1)
}

type Map(t) =
  Dict(Point, t)

pub type PartNumber {
  PartNumber(number: Int, indices: List(Point))
}

pub type Schematic {
  Schematic(symbols: Map(String), parts: List(PartNumber))
}

fn merge_schematic(s1: Schematic, s2: Schematic) -> Schematic {
  Schematic(
    symbols: dict.merge(s1.symbols, s2.symbols),
    parts: list.flatten([s1.parts, s2.parts]),
  )
}

pub fn parse_input_line(src: String, lineno: Int) -> Schematic {
  inner_parse_line(ParserState(
    lineno: lineno,
    position: 0,
    schematic: Schematic(symbols: dict.new(), parts: []),
    tokens: string.to_graphemes(src),
  ))
}

fn inner_parse_line(state: ParserState) -> Schematic {
  case parser_status(state.tokens) {
    Done -> state.schematic
    Dots -> inner_parse_line(drop_dots(state))
    Number -> inner_parse_line(take_number(state))
    Symbol -> inner_parse_line(take_symbol(state))
  }
}

pub type ParserStatus {
  Dots
  Number
  Symbol
  Done
}

type ParserState {
  ParserState(
    lineno: Int,
    position: Int,
    schematic: Schematic,
    tokens: List(String),
  )
}

pub fn parser_status(tokens: List(String)) -> ParserStatus {
  case tokens {
    [] -> Done
    [".", ..] -> Dots
    ["0", ..]
    | ["1", ..]
    | ["2", ..]
    | ["3", ..]
    | ["4", ..]
    | ["5", ..]
    | ["6", ..]
    | ["7", ..]
    | ["8", ..]
    | ["9", ..] -> Number
    [_, ..] -> Symbol
  }
}

fn drop_dots(state: ParserState) -> ParserState {
  let dots =
    list.take_while(state.tokens, fn(c) { c == "." })
    |> list.length
  ParserState(
    ..state,
    position: state.position + dots,
    tokens: list.drop(state.tokens, dots),
  )
}

fn is_digit(c: String) -> Bool {
  c == "0"
  || c == "1"
  || c == "2"
  || c == "3"
  || c == "4"
  || c == "5"
  || c == "6"
  || c == "7"
  || c == "8"
  || c == "9"
}

fn take_number(state: ParserState) -> ParserState {
  let digits = list.take_while(state.tokens, is_digit)
  let assert Ok(n) = int.parse(string.join(digits, ""))
  let indices =
    list.range(0, list.length(digits) - 1)
    |> list.map(fn(offset) { #(state.lineno, state.position + offset) })
  let part = PartNumber(number: n, indices: indices)
  let schematic =
    Schematic(
      ..state.schematic,
      parts: list.prepend(state.schematic.parts, part),
    )
  ParserState(
    ..state,
    position: state.position + list.length(digits),
    schematic: schematic,
    tokens: list.drop_while(state.tokens, is_digit),
  )
}

fn take_symbol(state: ParserState) -> ParserState {
  let assert Ok(c) = list.first(state.tokens)
  let assert Ok(rest) = list.rest(state.tokens)
  let symbols =
    dict.insert(state.schematic.symbols, #(state.lineno, state.position), c)
  ParserState(
    ..state,
    tokens: rest,
    position: state.position + 1,
    schematic: Schematic(..state.schematic, symbols: symbols),
  )
}

pub fn parse_input(input: String) -> Schematic {
  input
  |> string.split("\n")
  |> list.index_map(parse_input_line)
  |> list.fold(
    from: Schematic(symbols: dict.new(), parts: []),
    with: merge_schematic,
  )
}

pub fn neighbors_of(points: List(Point)) -> List(Point) {
  let self = set.from_list(points)

  let ns = fn(p: Point) -> List(Point) {
    let ds = [
      #(-1, -1),
      #(-1, 0),
      #(-1, 1),
      #(0, -1),
      #(0, 0),
      #(0, 1),
      #(1, -1),
      #(1, 0),
      #(1, 1),
    ]
    ds
    |> list.map(fn(d) { add_point(p, d) })
  }

  points
  |> list.map(ns)
  |> list.flatten()
  |> set.from_list()
  |> set.difference(self)
  |> set.to_list
}

fn active_numbers(schematic: Schematic) -> List(PartNumber) {
  let is_active = fn(n: PartNumber) -> Bool {
    n.indices
    |> neighbors_of
    |> list.any(dict.has_key(schematic.symbols, _))
  }
  schematic.parts
  |> list.filter(is_active)
}

fn solve_part_1(schematic: Schematic) {
  let result =
    schematic
    |> active_numbers
    |> list.map(fn(n) { n.number })
    |> int.sum
  io.println("Part number sum: " <> int.to_string(result))
}

fn solve_part_2(schematic: Schematic) {
  let parts_index =
    schematic.parts
    |> list.map(fn(part) {
      part.indices
      |> list.map(fn(point) { #(point, part) })
    })
    |> list.flatten
    |> dict.from_list

  let adjacent_partnumbers = fn(p: Point) -> List(PartNumber) {
    [p]
    |> neighbors_of
    |> list.map(dict.get(parts_index, _))
    |> result.values
    |> list.unique
  }

  let result =
    schematic.symbols
    |> dict.to_list
    |> list.filter(fn(sym) { sym.1 == "*" })
    |> list.map(fn(sym) { adjacent_partnumbers(sym.0) })
    |> list.map(fn(nums) -> Int {
      case nums {
        [n1, n2] -> n1.number * n2.number
        _ -> 0
      }
    })
    |> int.sum
  io.println("Total gear power: " <> int.to_string(result))
}

const test_input: String = "467..114..
...*......
..35..633.
......#...
617*......
.....+.58.
..592.....
......755.
...$.*....
.664.598.."

pub fn main() {
  let test_schematic = parse_input(test_input)
  io.println("Example---")
  solve_part_1(test_schematic)
  solve_part_2(test_schematic)

  let assert Ok(input) = simplifile.read("src/y2023/day03/input.txt")
  let schematic = parse_input(input)
  io.println("Solution---")
  solve_part_1(schematic)
  solve_part_2(schematic)
}
