import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/option.{None, Some}
import gleam/result
import gleam/string
import simplifile

const example_input = "3   4
4   3
2   5
1   3
3   9
3   3"

fn parse_input(src: String) -> List(#(Int, Int)) {
  let parse_line = fn(s: String) -> #(Int, Int) {
    let assert [a, b] = string.split(s, "   ")
    let assert Ok(n) = int.parse(a)
    let assert Ok(m) = int.parse(b)
    #(n, m)
  }
  let lines = string.split(src, "\n")
  list.map(lines, parse_line)
}

fn solve_part1(input: List(#(Int, Int))) {
  let firsts = list.map(input, fn(p) { p.0 }) |> list.sort(int.compare)
  let seconds = list.map(input, fn(p) { p.1 }) |> list.sort(int.compare)
  let diff = fn(a, b) { int.absolute_value(a - b) }
  list.map2(firsts, seconds, diff)
  |> int.sum
}

fn count(xs: List(Int)) -> dict.Dict(Int, Int) {
  let count_inner = fn(counts: dict.Dict(Int, Int), x: Int) -> dict.Dict(
    Int,
    Int,
  ) {
    dict.upsert(counts, x, fn(cnt) {
      case cnt {
        None -> 1
        Some(n) -> n + 1
      }
    })
  }
  list.fold(xs, dict.new(), count_inner)
}

fn solve_part2(input: List(#(Int, Int))) {
  let firsts = list.map(input, fn(p) { p.0 }) |> list.sort(int.compare)
  let seconds = list.map(input, fn(p) { p.1 }) |> list.sort(int.compare)
  let second_counts = count(seconds)
  firsts
  |> list.map(fn(f) {
    dict.get(second_counts, f)
    |> result.unwrap(or: 0)
    |> int.multiply(f)
  })
  |> int.sum
}

pub fn main() {
  let assert Ok(source) = simplifile.read("src/y2024/d01/input.txt")
  let input = parse_input(source)

  example_input
  |> parse_input
  |> solve_part1
  |> io.debug

  example_input
  |> parse_input
  |> solve_part2
  |> io.debug

  input
  |> solve_part1
  |> io.debug

  input
  |> solve_part2
  |> io.debug
}
