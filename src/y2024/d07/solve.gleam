import gleam/int
import gleam/io
import gleam/list
import gleam/string
import gleam/yielder
import simplifile

import util

pub type Calibration {
  Calibration(result: Int, operands: List(Int))
}

type Input =
  List(Calibration)

fn parse_source(src: String) -> Input {
  let parse_line = fn(line: String) -> Calibration {
    let assert [cal, ops] = string.split(line, ": ")
    let operands =
      ops
      |> string.split(" ")
      |> list.map(util.unsafe_parse_int)
    Calibration(result: util.unsafe_parse_int(cal), operands: operands)
  }

  src
  |> string.split("\n")
  |> list.map(parse_line)
}

type Operator {
  Add
  Multiply
  Concat
}

fn do_op(op: Operator, a: Int, b: Int) -> Int {
  case op {
    Add -> a + b
    Multiply -> a * b
    Concat -> util.unsafe_parse_int(int.to_string(a) <> int.to_string(b))
  }
}

// Evaluate a list of operands and a list of operators
fn eval(operands: List(Int), operators: List(Operator)) -> Int {
  case operands, operators {
    [a], [] -> a
    [a, b], [op] -> do_op(op, a, b)
    [a, b, ..r_operands], [op, ..r_operators] ->
      eval([do_op(op, a, b), ..r_operands], r_operators)
    _, _ ->
      panic as {
        "bad ops: "
        <> string.inspect(operands)
        <> " and "
        <> string.inspect(operators)
      }
  }
}

// Check if the given list of operators satisfies the calibration
fn check_ops(calibration: Calibration, operators: List(Operator)) -> Bool {
  eval(calibration.operands, operators) == calibration.result
}

// Get all possible combinations of a particular number of operators
fn part_1_ops(size: Int) -> yielder.Yielder(List(Operator)) {
  let as_ops = fn(n: Int) -> List(Operator) {
    n
    |> int.to_base2
    |> string.pad_start(size, "0")
    |> string.to_graphemes
    |> list.map(fn(c) {
      case c {
        "0" -> Add
        "1" -> Multiply
        _ -> panic as { "bad op: " <> c }
      }
    })
  }

  list.repeat(2, size)
  |> int.product
  |> int.subtract(1)
  |> yielder.range(from: 0, to: _)
  |> yielder.map(as_ops)
}

// Check if _any_ possible list of operators satisfies the calibration
fn check_1(calibration: Calibration) -> Bool {
  part_1_ops(list.length(calibration.operands) - 1)
  |> yielder.any(check_ops(calibration, _))
}

fn solve_part_1(input: Input) -> Int {
  input
  |> util.pmap(fn(calibration) {
    case check_1(calibration) {
      True -> calibration.result
      False -> 0
    }
  })
  |> int.sum
}

fn part_2_ops(size: Int) -> yielder.Yielder(List(Operator)) {
  let as_ops = fn(n: Int) -> List(Operator) {
    n
    |> int.to_base_string(3)
    |> fn(r) {
      case r {
        Ok(n) -> n
        Error(_) -> panic as { "bad base 3: " <> int.to_string(n) }
      }
    }
    |> string.pad_start(size, "0")
    |> string.to_graphemes
    |> list.map(fn(c) {
      case c {
        "0" -> Add
        "1" -> Multiply
        "2" -> Concat
        _ -> panic as { "bad op: " <> c }
      }
    })
  }

  list.repeat(3, size)
  |> int.product
  |> int.subtract(1)
  |> yielder.range(from: 0, to: _)
  |> yielder.map(as_ops)
}

fn check_2(calibration: Calibration) -> Bool {
  part_2_ops(list.length(calibration.operands) - 1)
  |> yielder.any(check_ops(calibration, _))
}

fn solve_part_2(input: Input) -> Int {
  input
  |> util.pmap(fn(calibration) {
    case check_2(calibration) {
      True -> calibration.result
      False -> 0
    }
  })
  |> int.sum
}

const example_source = "190: 10 19
3267: 81 40 27
83: 17 5
156: 15 6
7290: 6 8 6 15
161011: 16 10 13
192: 17 8 14
21037: 9 7 18 13
292: 11 6 16 20"

pub fn main() {
  let example_input = example_source |> parse_source
  let assert Ok(source) = simplifile.read("src/y2024/d07/input.txt")
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
