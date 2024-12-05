import gleam/list
import gleeunit/should
import y2024/d05/solve

const test_input = "1|2\n4|3\n\n1,2,4,3\n1,2,3,4\n2,1,4,3\n1,9,2,2"

pub fn parse_src_test() {
  test_input
  |> solve.parse_source
  |> should.equal(
    solve.Update(rules: [#(1, 2), #(4, 3)], updates: [
      [1, 2, 4, 3],
      [1, 2, 3, 4],
      [2, 1, 4, 3],
      [1, 9, 2, 2],
    ]),
  )
}

pub fn update_ok_test() {
  let input = solve.parse_source(test_input)

  input.updates
  |> list.map(solve.update_ok(input.rules, _))
  |> should.equal([True, False, False, True])
}

pub fn get_middle_test() {
  [1, 2, 3]
  |> solve.get_middle
  |> should.equal(2)

  [1, 2, 3, 4, 5, 6, 7]
  |> solve.get_middle
  |> should.equal(4)
}
