import gleeunit/should
import y2024/d03/solve

pub fn parse_operations_test() {
  "mul(1,2)"
  |> solve.parse_operations
  |> should.equal([solve.Mult(left: 1, right: 2)])

  "mul(1,2)mul(3,4)"
  |> solve.parse_operations
  |> should.equal([solve.Mult(left: 1, right: 2), solve.Mult(left: 3, right: 4)])

  "alfalfamul(1,2)asdji290 9mul(1, 2adsfmul(3,4)a92$3)"
  |> solve.parse_operations
  |> should.equal([solve.Mult(1, 2), solve.Mult(3, 4)])

  "alfalfamul(1,2)asdji29don't()0 9mul(1, 2adsfmul(3,4)a92$3)do()a890no y90 1 mul(5,6)"
  |> solve.parse_operations
  |> should.equal([
    solve.Mult(1, 2),
    solve.Dont,
    solve.Mult(3, 4),
    solve.Do,
    solve.Mult(5, 6),
  ])

  "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))"
  |> solve.parse_operations
  |> should.equal([
    solve.Mult(2, 4),
    solve.Dont,
    solve.Mult(5, 5),
    solve.Mult(11, 8),
    solve.Do,
    solve.Mult(8, 5),
  ])
}
