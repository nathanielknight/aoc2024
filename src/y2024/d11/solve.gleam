import gleam/dict.{type Dict}
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import gleam/yielder.{type Yielder}
import util

fn parse_source(source: String) -> Input {
  source
  |> string.split(" ")
  |> list.map(string.trim)
  |> list.map(util.unsafe_parse_int)
}

type Input =
  List(Int)

fn progress(stone: Int) -> Yielder(Int) {
  let split_stone = fn(digits: List(String)) -> #(Int, Int) {
    let len = list.length(digits)
    let lefts = list.take(digits, up_to: len / 2)
    let rights = list.drop(digits, up_to: len / 2)
    #(
      string.join(lefts, "") |> util.unsafe_parse_int,
      string.join(rights, "") |> util.unsafe_parse_int,
    )
  }

  case stone == 0 {
    True -> yielder.single(1)
    False -> {
      let digits = int.to_string(stone) |> string.to_graphemes
      case digits |> list.length |> int.is_even {
        True -> {
          let #(a, b) = split_stone(digits)
          yielder.prepend(yielder.single(b), a)
        }
        False -> {
          yielder.single(stone * 2024)
        }
      }
    }
  }
}

fn iterate_stones(stones: Input, steps: Int) -> Yielder(Int) {
  stones
  |> yielder.from_list
  |> do_iterate_stones(0, steps)
}

fn do_iterate_stones(state: Yielder(Int), step: Int, up_to: Int) -> Yielder(Int) {
  case step == up_to {
    True -> state
    False -> {
      let next = state |> yielder.map(progress) |> yielder.flatten
      do_iterate_stones(next, step + 1, up_to)
    }
  }
}

type IteratedLength {
  IteratedLength(stone: Int, iterations: Int)
}

fn do_iterated_length(
  to_calculate: List(IteratedLength),
  cache: Dict(IteratedLength, Int),
) -> Dict(IteratedLength, Int) {
  case to_calculate {
    [] -> cache
    [calc, ..calc_rest] -> {
      case calc {
        IteratedLength(_stone, 0) -> do_iterated_length(calc_rest, cache)
        IteratedLength(stone, 1) as il -> {
          let len = stone |> progress |> yielder.length
          do_iterated_length(calc_rest, dict.insert(cache, il, len))
        }
        IteratedLength(_stone, n) as il -> {
          case dict.get(cache, il) {
            Ok(length) -> do_iterated_length(calc_rest, cache)
            Error(_) -> {
              let need = next_iterated_lengths(il)
              let cached_need = need |> list.map(fn(s) { dict.get(cache, s) })
              case cached_need |> list.all(result.is_ok) {
                // if we have all the parts, calculate, cache, and continue
                True -> {
                  let l = cached_need |> result.values |> int.sum
                  do_iterated_length(calc_rest, dict.insert(cache, il, l))
                }
                // otherwise, push this back on to the stack along with the missing parts
                False -> {
                  let missing_parts =
                    need |> list.filter(fn(n) { !dict.has_key(cache, n) })
                  let add_calcs = [il, ..missing_parts] |> list.reverse
                  do_iterated_length(list.append(add_calcs, calc_rest), cache)
                }
              }
            }
          }
        }
      }
    }
  }
}

fn next_iterated_lengths(iterlen: IteratedLength) -> List(IteratedLength) {
  iterlen.stone
  |> progress
  |> yielder.map(fn(s) { IteratedLength(s, iterlen.iterations - 1) })
  |> yielder.to_list
}

fn solve_part_1(input: List(Int)) -> Int {
  input
  |> iterate_stones(25)
  |> yielder.length
}

fn solve_part_2(input: Input) -> Int {
  let calcs = input |> list.map(fn(n) { IteratedLength(n, 75) })
  let cache = do_iterated_length(calcs, dict.new())
  cache |> dict.size |> io.debug
  calcs |> list.map(dict.get(cache, _)) |> result.values |> int.sum
}

const source = "4022724 951333 0 21633 5857 97 702 6"

pub fn main() {
  source
  |> parse_source
  |> solve_part_1
  |> io.debug

  solve_part_2([0, 6, 97, 702, 5857, 21_633, 951_333, 4_022_724])
  |> io.debug
  // source
  // |> parse_source
  // |> solve_part_2
  // |> io.debug
}
