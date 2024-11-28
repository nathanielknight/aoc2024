import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/result
import gleam/string
import simplifile

type Draw =
  dict.Dict(String, Int)

fn parse_entry(src: String) -> #(String, Int) {
  let assert [number_src, color] = string.split(src, " ")
  let assert Ok(number) = int.parse(number_src)
  #(color, number)
}

pub fn parse_draw(src: String) -> Draw {
  src
  |> string.split(", ")
  |> list.map(parse_entry)
  |> dict.from_list
}

pub type Game {
  Game(number: Int, draws: List(Draw))
}

fn parse_gamenumber(src: String) -> Int {
  case src {
    "Game " <> n ->
      int.parse(n) |> or_panic("Couldn't parse game number: " <> src)
    _ -> panic as string.inspect("Ill formed game :" <> src)
  }
}

pub fn parse_game(src: String) -> Result(Game, String) {
  use [number_src, draws_src] <- result.try(case string.split(src, ": ") {
    [n, s] -> Ok([n, s])
    _ -> Error("Bad game source: " <> src)
  })
  let number = parse_gamenumber(number_src)
  let draws =
    draws_src
    |> string.split("; ")
    |> list.map(parse_draw)
  Ok(Game(number: number, draws: draws))
}

fn parse_input(src: String) -> Result(List(Game), String) {
  src
  |> string.split("\n")
  |> list.filter(fn(s) { !string.is_empty(s) })
  |> list.map(parse_game)
  |> result.all
}

fn or_panic(r: Result(t, _), msg: String) -> t {
  case r {
    Ok(v) -> v
    Error(_) -> panic as msg
  }
}

pub fn draw_compatible(draw: Draw, contents: Draw) -> Bool {
  let color_compatible = fn(pair: #(String, Int)) -> Bool {
    let #(color, number) = pair
    case dict.get(contents, color) {
      Ok(bag) -> number <= bag
      Error(Nil) -> False
    }
  }
  draw
  |> dict.to_list
  |> list.all(color_compatible)
}

pub fn game_compatible(game: Game, draw: Draw) -> Bool {
  game.draws
  |> list.all(draw_compatible(_, draw))
}

pub fn test_part1() {
  let bag_contents: Draw =
    dict.from_list([#("red", 12), #("green", 13), #("blue", 14)])
  use games <- result.try(parse_input(example_src))

  let result =
    games
    |> list.filter(game_compatible(_, bag_contents))
    |> list.map(fn(g) { g.number })
    |> int.sum
  io.println("Test part 1: " <> int.to_string(result))
  Ok(result)
}

fn part1(games: List(Game)) {
  let bag_contents: Draw =
    dict.from_list([#("red", 12), #("green", 13), #("blue", 14)])
  let result =
    games
    |> list.filter(game_compatible(_, bag_contents))
    |> list.map(fn(g) { g.number })
    |> int.sum

  io.println("Part 1: " <> int.to_string(result))
}

fn acc_draw(contents: Draw, p: #(String, Int)) -> Draw {
  case dict.get(contents, p.0) {
    Error(Nil) -> dict.insert(contents, p.0, p.1)
    Ok(n) -> dict.insert(contents, p.0, int.max(n, p.1))
  }
}

pub fn minimum_contents(game: Game) -> Draw {
  let all_draws: List(#(String, Int)) =
    game.draws
    |> list.map(dict.to_list)
    |> list.flatten
  list.fold(over: all_draws, from: dict.new(), with: acc_draw)
}

pub fn power(draw: Draw) -> Int {
  ["green", "red", "blue"]
  |> list.map(fn(color) { dict.get(draw, color) |> result.unwrap(0) })
  |> list.fold(from: 1, with: int.multiply)
}

fn sum_power(games: List(Game)) -> Int {
  games
  |> list.map(minimum_contents)
  |> list.map(power)
  |> int.sum
}

fn test_part2() {
  use games <- result.try(parse_input(example_src))
  let result = sum_power(games)
  io.println("Test part 2: " <> int.to_string(result))
  Ok(result)
}

fn part2(games: List(Game)) {
  let result = sum_power(games)
  io.println("Part 2: " <> int.to_string(result))
}

pub fn main() {
  let _ = test_part1()
  let _ = test_part2()

  let assert Ok(input) = simplifile.read("src/y2023/day02/input.txt")
  use games <- result.try(parse_input(input))

  part1(games)
  part2(games)

  io.println("Done")
  Ok(Nil)
}

const example_src = "Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green
Game 2: 1 blue, 2 green; 3 green, 4 blue, 1 red; 1 green, 1 blue
Game 3: 8 green, 6 blue, 20 red; 5 blue, 4 red, 13 green; 5 green, 1 red
Game 4: 1 green, 3 red, 6 blue; 3 green, 6 red; 3 green, 15 blue, 14 red
Game 5: 6 red, 1 blue, 3 green; 2 blue, 1 red, 2 green"
