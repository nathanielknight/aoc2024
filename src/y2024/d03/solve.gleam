import gleam/int
import gleam/io
import gleam/list
import gleam/option
import gleam/regexp
import simplifile

pub type Operation {
  Mult(left: Int, right: Int)
  Do
  Dont
}

pub fn parse_operations(src: String) -> List(Operation) {
  let assert Ok(re) =
    regexp.from_string("mul\\((\\d+),(\\d+)\\)|don't\\(\\)|do\\(\\)")
  let matches = regexp.scan(re, src)
  matches
  |> list.map(parse_op)
}

fn parse_op(match: regexp.Match) -> Operation {
  case match.content {
    "don't()" -> Dont
    "do()" -> Do
    _ -> {
      let assert [option.Some(a_src), option.Some(b_src)] = match.submatches
      let assert Ok(a) = int.parse(a_src)
      let assert Ok(b) = int.parse(b_src)
      Mult(left: a, right: b)
    }
  }
}

fn evaluate_1(mults: List(Operation)) -> Int {
  mults
  |> list.map(fn(m) {
    case m {
      Mult(a, b) -> a * b
      _ -> 0
    }
  })
  |> int.sum
}

type EvaluatorState {
  Active
  Inactive
}

fn evaluate_2(ops: List(Operation)) -> Int {
  let #(_state, total) =
    list.fold(
      ops,
      #(Active, 0),
      fn(state: #(EvaluatorState, Int), op: Operation) -> #(EvaluatorState, Int) {
        case op {
          Mult(a, b) ->
            case state.0 {
              Active -> #(Active, state.1 + { a * b })
              Inactive -> #(Inactive, state.1)
            }
          Do -> #(Active, state.1)
          Dont -> #(Inactive, state.1)
        }
      },
    )
  total
}

const example_input_1 = "xmul(2,4)%&mul[3,7]!@^do_not_mul(5,5)+mul(32,64]then(mul(11,8)mul(8,5))"

const example_input_2 = "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"

pub fn main() {
  let example_mults = parse_operations(example_input_1)
  let example_ops = parse_operations(example_input_2)
  let assert Ok(input) = simplifile.read("src/y2024/d03/input.txt")
  let mults = parse_operations(input)

  example_mults
  |> evaluate_1
  |> io.debug

  example_ops
  |> evaluate_2
  |> io.debug

  mults
  |> evaluate_1
  |> io.debug

  mults
  |> evaluate_2
  |> io.debug
}
