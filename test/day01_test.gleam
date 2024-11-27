import day01/solve
import gleam/list
import gleeunit/should

pub fn parse_test() {
  "1foo2"
  |> solve.find_digits_two
  |> should.equal(12)

  "onefootwo"
  |> solve.find_digits_two
  |> should.equal(12)

  "zerone2nine"
  |> solve.find_digits_two
  |> should.equal(19)

  "asdfonejkl"
  |> solve.find_digits_two
  |> should.equal(11)

  "eighthree"
  |> solve.find_digits_two
  |> should.equal(83)

  "sevenine"
  |> solve.find_digits_two
  |> should.equal(79)
}

pub fn parse_aoc_int_test() {
  let cases = [
    #("1", 1),
    #("2", 2),
    #("3", 3),
    #("4", 4),
    #("5", 5),
    #("6", 6),
    #("7", 7),
    #("8", 8),
    #("9", 9),
    #("one", 1),
    #("two", 2),
    #("three", 3),
    #("four", 4),
    #("five", 5),
    #("six", 6),
    #("seven", 7),
    #("eight", 8),
    #("nine", 9),
  ]

  list.map(cases, fn(p) { solve.parse_aoc_int(p.0) |> should.equal(Ok(p.1)) })
}
