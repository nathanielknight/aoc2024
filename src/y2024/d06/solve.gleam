import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/otp/task
import gleam/set.{type Set}
import gleam/string
import simplifile
import util

const example_source = "....#.....
.........#
..........
..#.......
.......#..
..........
.#..^.....
........#.
#.........
......#..."

type Point =
  #(Int, Int)

pub type Direction {
  North
  South
  East
  West
}

pub type Guard {
  Guard(location: Point, direction: Direction)
}

pub type Input {
  Input(area: #(Int, Int), obstacles: Set(Point), guard: Guard)
}

type ParsingInput {
  ParsingInput(obstacles: Set(Point), guard: Option(Guard))
}

type InputContent {
  Empty
  Obstacle
  GuardStart
}

pub fn parse_source(source: String) -> Input {
  let lines = string.split(source, "\n")
  let size = #(
    lines |> list.map(string.length) |> list.fold(from: 0, with: int.max),
    list.length(lines),
  )
  lines
  |> list.index_map(fn(line, y) {
    parse_row(y, line, ParsingInput(set.new(), None))
  })
  |> list.fold(from: ParsingInput(set.new(), None), with: combine_parsing_input)
  |> finalize_input(size)
}

fn combine_parsing_input(a: ParsingInput, b: ParsingInput) -> ParsingInput {
  ParsingInput(
    obstacles: set.union(a.obstacles, b.obstacles),
    guard: option.or(a.guard, b.guard),
  )
}

fn finalize_input(parsing: ParsingInput, size: Point) -> Input {
  case parsing.guard {
    Some(g) -> Input(size, parsing.obstacles, g)
    None -> panic as "no guard"
  }
}

fn parse_row(y: Int, source: String, input: ParsingInput) -> ParsingInput {
  source
  |> string.to_graphemes
  |> list.index_map(fn(c, x) {
    case c {
      "." -> #(#(x, y), Empty)
      "#" -> #(#(x, y), Obstacle)
      "^" -> #(#(x, y), GuardStart)
      _ -> panic as { "bad input char: " <> c }
    }
  })
  |> list.fold(from: input, with: fn(input, mapped) {
    let #(pos, content) = mapped
    case content {
      Empty -> input
      Obstacle ->
        ParsingInput(..input, obstacles: set.insert(input.obstacles, pos))
      GuardStart ->
        ParsingInput(
          ..input,
          guard: Some(Guard(location: pos, direction: North)),
        )
    }
  })
}

type Simulation {
  Simulation(
    area: Point,
    obstacles: Set(Point),
    guard: Guard,
    visited: Set(Point),
  )
}

fn advance_direction(direction: Direction) -> Point {
  case direction {
    North -> #(0, -1)
    South -> #(0, 1)
    East -> #(1, 0)
    West -> #(-1, 0)
  }
}

fn turn_right(direction: Direction) -> Direction {
  case direction {
    North -> East
    East -> South
    South -> West
    West -> North
  }
}

fn advance(sim: Simulation) -> Simulation {
  let guard_next_pos =
    util.add_points(sim.guard.location, advance_direction(sim.guard.direction))
  case set.contains(sim.obstacles, guard_next_pos) {
    True ->
      Simulation(
        ..sim,
        guard: Guard(..sim.guard, direction: turn_right(sim.guard.direction)),
      )
    False ->
      Simulation(
        ..sim,
        guard: Guard(..sim.guard, location: guard_next_pos),
        visited: set.insert(sim.visited, sim.guard.location),
      )
  }
}

fn simulate(sim: Simulation) -> Int {
  let out_of_bounds = fn() {
    let #(x, y) = sim.guard.location
    let #(ax, ay) = sim.area
    x < 0 || x >= ax || y < 0 || y >= ay
  }
  case out_of_bounds() {
    True -> set.size(sim.visited)
    False -> simulate(advance(sim))
  }
}

fn solve_part_1(input: Input) {
  let simulation =
    Simulation(
      area: input.area,
      obstacles: input.obstacles,
      guard: input.guard,
      visited: set.new(),
    )
  simulate(simulation)
}

type LoopSimulation {
  LoopSimulation(
    area: Point,
    obstacles: Set(Point),
    guard: Guard,
    visited: Set(Guard),
  )
}

type LoopSimulationOutcome {
  OutOfBounds
  Loop
}

fn loop_simulate(sim: LoopSimulation) -> LoopSimulationOutcome {
  let out_of_bounds = fn() {
    let #(x, y) = sim.guard.location
    let #(ax, ay) = sim.area
    x < 0 || x >= ax || y < 0 || y >= ay
  }
  let looping = set.contains(sim.visited, sim.guard)
  case out_of_bounds(), looping {
    False, True -> Loop
    True, _ -> OutOfBounds
    False, False -> loop_simulate(loop_advance(sim))
  }
}

fn loop_advance(sim: LoopSimulation) -> LoopSimulation {
  let guard_next_pos =
    util.add_points(sim.guard.location, advance_direction(sim.guard.direction))
  case set.contains(sim.obstacles, guard_next_pos) {
    True ->
      LoopSimulation(
        ..sim,
        guard: Guard(..sim.guard, direction: turn_right(sim.guard.direction)),
      )
    False ->
      LoopSimulation(
        ..sim,
        guard: Guard(..sim.guard, location: guard_next_pos),
        visited: set.insert(sim.visited, sim.guard),
      )
  }
}

fn solve_part_2(input: Input) -> Int {
  let base_simulation =
    LoopSimulation(
      area: input.area,
      obstacles: input.obstacles,
      guard: input.guard,
      visited: set.new(),
    )
  let #(ax, ay) = input.area
  let potential_obstacles =
    // NOTE: range is inclusive, which isn't what I'd expect based on list's 0-start indexing
    // This bit me when submitting a solution! :P
    list.range(0, ax - 1)
    |> list.map(fn(x) {
      list.range(0, ay - 1)
      |> list.map(fn(y) { #(x, y) })
    })
    |> list.flatten
    |> set.from_list
    |> set.difference(base_simulation.obstacles)
    |> set.to_list

  potential_obstacles
  |> list.map(fn(obst) {
    // Doing this map in parallel vs. sequentially results in a 3-4x speedup
    // on my 8-core laptop.
    task.async(fn() {
      loop_simulate(
        LoopSimulation(
          ..base_simulation,
          obstacles: set.insert(base_simulation.obstacles, obst),
        ),
      )
    })
  })
  |> list.map(task.await_forever)
  |> list.count(fn(sim) {
    case sim {
      OutOfBounds -> False
      Loop -> True
    }
  })
}

pub fn main() {
  let example_input = parse_source(example_source)
  let assert Ok(source) = simplifile.read("src/y2024/d06/input.txt")
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
