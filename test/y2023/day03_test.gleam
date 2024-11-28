import gleam/dict
import gleam/list
import gleam/set
import gleam/string
import gleeunit/should
import y2023/day03/solve

pub fn parser_status_test() {
  let cases = [
    #("..", solve.Dots),
    #("", solve.Done),
    #("123..", solve.Number),
    #("#..123", solve.Symbol),
  ]

  cases
  |> list.map(fn(c) {
    c.0
    |> string.to_graphemes
    |> solve.parser_status
    |> should.equal(c.1)
  })
}

pub fn parser_input_line_test() {
  let lineno = 3
  let line = "...#..123#..4.$"

  let expected =
    solve.Schematic(
      symbols: dict.from_list([
        #(#(3, 3), "#"),
        #(#(3, 9), "#"),
        #(#(3, 14), "$"),
      ]),
      parts: [
        solve.PartNumber(4, [#(3, 12)]),
        solve.PartNumber(123, [#(3, 6), #(3, 7), #(3, 8)]),
      ],
    )

  line
  |> solve.parse_input_line(lineno)
  |> should.equal(expected)
}

pub fn parse_input_test() {
  let test_input =
    "123.#.$.9
..34..#.."

  let expected =
    solve.Schematic(
      symbols: dict.from_list([
        #(#(0, 4), "#"),
        #(#(0, 6), "$"),
        #(#(1, 6), "#"),
      ]),
      parts: [
        solve.PartNumber(9, [#(0, 8)]),
        solve.PartNumber(123, [#(0, 0), #(0, 1), #(0, 2)]),
        solve.PartNumber(34, [#(1, 2), #(1, 3)]),
      ],
    )

  test_input
  |> solve.parse_input
  |> should.equal(expected)
}

pub fn neighbors_of_test() {
  solve.neighbors_of([#(1, 1)])
  |> set.from_list
  |> should.equal(
    set.from_list([
      #(0, 0),
      #(0, 1),
      #(0, 2),
      #(1, 0),
      #(1, 2),
      #(2, 0),
      #(2, 1),
      #(2, 2),
    ]),
  )
}
