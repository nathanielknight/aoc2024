import gleeunit/should
import y2024/d02/solve

pub fn dampening_test() {
  []
  |> solve.dampened_options
  |> should.equal([[]])

  [1, 2, 3]
  |> solve.dampened_options
  |> should.equal([[1, 2], [1, 3], [2, 3], [1, 2, 3]])

  [8, 6, 4, 4, 1]
  |> solve.dampened_options
  |> should.equal([
    [8, 6, 4, 4],
    [8, 6, 4, 1],
    [8, 6, 4, 1],
    [8, 4, 4, 1],
    [6, 4, 4, 1],
    [8, 6, 4, 4, 1],
  ])
}
