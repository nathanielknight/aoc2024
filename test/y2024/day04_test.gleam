import gleam/dict
import gleam/string
import gleeunit/should
import y2024/d04/solve

pub fn parse_src_test() {
  "ABCD"
  |> solve.parse_src
  |> should.equal(
    dict.from_list([
      #(#(0, 0), "A"),
      #(#(1, 0), "B"),
      #(#(2, 0), "C"),
      #(#(3, 0), "D"),
    ]),
  )

  "AB\nCD"
  |> solve.parse_src
  |> should.equal(
    dict.from_list([
      #(#(0, 0), "A"),
      #(#(1, 0), "B"),
      #(#(0, 1), "C"),
      #(#(1, 1), "D"),
    ]),
  )
}

const testgrid = "ABC
DEF
GHI"

pub fn line_from_test() {
  solve.line_from(#(0, 0), #(1, 1), 2)
  |> should.equal([#(0, 0), #(1, 1)])

  solve.line_from(#(2, 2), #(0, -1), 3)
  |> should.equal([#(2, 2), #(2, 1), #(2, 0)])
}

pub fn search_at_direction_test() {
  let grid = solve.parse_src(testgrid)

  solve.search_at_direction(grid, #(0, 0), string.to_graphemes("ABC"), #(1, 0))
  |> should.be_true

  solve.search_at_direction(grid, #(0, 0), string.to_graphemes("ABC"), #(0, 1))
  |> should.be_false

  solve.search_at_direction(grid, #(0, 0), string.to_graphemes("ABC"), #(0, -1))
  |> should.be_false

  solve.search_at_direction(grid, #(0, 0), string.to_graphemes("AEI"), #(1, 1))
  |> should.be_true
}
