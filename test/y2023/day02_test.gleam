import gleam/dict
import gleam/result
import gleeunit/should
import y2023/day02/solve

pub fn parse_draw_test() {
  "3 blue, 4 red"
  |> solve.parse_draw
  |> should.equal(dict.from_list([#("red", 4), #("blue", 3)]))

  "2 yellow, 1 orange, 5 crimson"
  |> solve.parse_draw
  |> should.equal(
    dict.from_list([#("yellow", 2), #("orange", 1), #("crimson", 5)]),
  )
}

pub fn parse_game_test() {
  "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green"
  |> solve.parse_game
  |> should.equal(
    Ok(
      solve.Game(number: 1, draws: [
        dict.from_list([#("blue", 3), #("red", 4)]),
        dict.from_list([#("red", 1), #("green", 2), #("blue", 6)]),
        dict.from_list([#("green", 2)]),
      ]),
    ),
  )

  "Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red"
  |> solve.parse_game
  |> should.equal(
    Ok(
      solve.Game(number: 4, draws: [
        dict.from_list([#("green", 1), #("red", 3), #("blue", 6)]),
        dict.from_list([#("green", 3), #("red", 6)]),
        dict.from_list([#("green", 3), #("blue", 15), #("red", 14)]),
      ]),
    ),
  )
}

pub fn draw_compatible_test() {
  let base = dict.from_list([#("red", 1), #("blue", 1)])

  "1 blue, 1 red"
  |> solve.parse_draw
  |> solve.draw_compatible(base)
  |> should.equal(True)

  "1 red, 1 blue"
  |> solve.parse_draw
  |> solve.draw_compatible(base)
  |> should.equal(True)

  "1 red"
  |> solve.parse_draw
  |> solve.draw_compatible(base)
  |> should.equal(True)

  "2 red"
  |> solve.parse_draw
  |> solve.draw_compatible(base)
  |> should.equal(False)

  "1 green, 1 red"
  |> solve.parse_draw
  |> solve.draw_compatible(base)
  |> should.equal(False)
}

pub fn minimum_contents_test() {
  use g <- result.try(solve.parse_game(
    "Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red",
  ))
  g
  |> solve.minimum_contents
  |> should.equal(dict.from_list([#("green", 3), #("blue", 15), #("red", 14)]))
  |> Ok
}
