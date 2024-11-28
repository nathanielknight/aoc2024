import gleam/int
import gleam/io
import gleam/list
import gleam/regexp
import gleam/result
import gleam/string
import simplifile

fn get_input() -> List(String) {
  let assert Ok(input) = simplifile.read("src/y2023/day01/input.txt")
  // let assert Ok(input) = simplifile.read("src/day01/example-input-2.txt")
  string.split(input, "\n")
  |> list.filter(fn(s: String) { !string.is_empty(s) })
}

fn find_digits_one(s: String) -> #(Int, Int) {
  let assert Ok(p) = regexp.from_string("[1-9]")
  let matches = regexp.scan(p, s)
  let assert Ok(f) =
    matches
    |> list.first
    |> result.map(fn(m) { int.parse(m.content) })
    |> result.flatten
  let assert Ok(l) =
    matches
    |> list.last
    |> result.map(fn(m) { int.parse(m.content) })
    |> result.flatten
  #(f, l)
}

pub fn find_digits_two(inputline: String) -> Int {
  let assert Ok(pattern_first) =
    regexp.from_string("[1-9]|one|two|three|four|five|six|seven|eight|nine")
  let assert Ok(pattern_last) =
    regexp.from_string("[1-9]|eno|owt|eerht|ruof|evif|xis|neves|thgie|enin")
  let assert Ok(first) =
    find_first_match(inputline, pattern_first) |> parse_aoc_int
  let assert Ok(second) =
    find_first_match(string.reverse(inputline), pattern_last)
    |> string.reverse
    |> parse_aoc_int

  let result = 10 * first + second

  // io.debug(inputline <> " -> " <> string.inspect(result))
  result
}

fn find_first_match(inputline: String, pattern: regexp.Regexp) -> String {
  let matches = regexp.scan(pattern, inputline)
  let assert Ok(m) = matches |> list.first
  m.content
}

pub fn parse_aoc_int(s: String) -> Result(Int, String) {
  case s {
    "one" -> Ok(1)
    "two" -> Ok(2)
    "three" -> Ok(3)
    "four" -> Ok(4)
    "five" -> Ok(5)
    "six" -> Ok(6)
    "seven" -> Ok(7)
    "eight" -> Ok(8)
    "nine" -> Ok(9)
    s ->
      s
      |> int.parse
      |> result.map_error(fn(e) {
        "Error parsing " <> s <> ": " <> string.inspect(e)
      })
  }
}

fn part1(input: List(String)) -> Int {
  input
  |> list.map(find_digits_one)
  |> list.map(fn(p) { 10 * p.0 + p.1 })
  |> int.sum
}

fn part2(input: List(String)) -> Int {
  input
  |> list.map(find_digits_two)
  |> int.sum
}

pub fn main() {
  let input = get_input()

  part1(input) |> io.debug
  part2(input) |> io.debug
}
