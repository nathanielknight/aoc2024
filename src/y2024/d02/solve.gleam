import gleam/int
import gleam/io
import gleam/list
import gleam/string
import simplifile
import util

const example_source = "7 6 4 2 1
1 2 7 8 9
9 7 6 2 1
1 3 2 4 5
8 6 4 4 1
1 3 6 7 9"

fn parse_source(src: String) -> List(List(Int)) {
  let parse_line = fn(s) {
    s
    |> string.split(" ")
    |> list.map(util.unsafe_parse_int)
  }
  src
  |> string.split("\n")
  |> list.map(parse_line)
}

fn is_safe(line: List(Int)) {
  let assert Ok(rest) = list.rest(line)
  let diffs = list.map2(line, rest, int.subtract)
  let all_same_direction =
    list.all(diffs, fn(d) { d < 0 }) || list.all(diffs, fn(d) { d > 0 })
  let magnitudes_ok =
    list.all(diffs, fn(d) {
      int.absolute_value(d) > 0 && int.absolute_value(d) < 4
    })
  let result = all_same_direction && magnitudes_ok
  result
}

pub fn dampened_options(line: List(Int)) -> List(List(Int)) {
  dampened_options_step([], line, [line])
}

pub fn dampened_options_step(
  init: List(Int),
  rest: List(Int),
  options: List(List(Int)),
) -> List(List(Int)) {
  // i1 i2 i3 x r1 r2
  //
  case rest {
    // this should be unreachable
    [] -> options
    // omit the final element of line
    [_x] -> [list.reverse(init), ..options]
    // omit the first element of rest and continue
    [x, ..rest] -> {
      let option = list.append(list.reverse(init), rest)
      dampened_options_step(
        // move x to init
        [x, ..init],
        rest,
        [option, ..options],
      )
    }
  }
}

fn is_safe_if_dampened(line: List(Int)) {
  line
  |> dampened_options
  |> list.any(is_safe)
}

fn solve_part1(input: List(List(Int))) {
  let count =
    input
    |> list.filter(is_safe)
    |> list.length
  io.println("Part 1: " <> int.to_string(count))
}

fn solve_part2(input: List(List(Int))) {
  let count =
    input
    |> list.filter(is_safe_if_dampened)
    |> list.length
  io.println("Part 2: " <> int.to_string(count))
}

pub fn main() {
  let example_input = parse_source(example_source)
  example_input
  |> solve_part1

  example_input
  |> solve_part2

  let assert Ok(source) = simplifile.read("src/y2024/d02/input.txt")
  let input = parse_source(source)

  input
  |> solve_part1

  input
  |> solve_part2
}
