import gleam/dict
import gleam/int
import gleam/io
import gleam/list
import gleam/order
import gleam/pair
import gleam/result
import gleam/string
import simplifile
import util

pub type Update {
  Update(rules: List(#(Int, Int)), updates: List(List(Int)))
}

pub fn parse_source(src: String) -> Update {
  let assert [rules_src, updates_src] = string.split(src, "\n\n")

  let parse_rule = fn(src: String) -> #(Int, Int) {
    let assert [a, b] = string.split(src, "|")
    #(util.unsafe_parse_int(a), util.unsafe_parse_int(b))
  }

  let rules =
    rules_src
    |> string.split("\n")
    |> list.map(parse_rule)

  let parse_update = fn(src: String) -> List(Int) {
    src
    |> string.split(",")
    |> list.map(util.unsafe_parse_int)
  }

  let updates =
    updates_src
    |> string.split("\n")
    |> list.map(parse_update)

  Update(rules, updates)
}

fn must_come_before(rules: List(#(Int, Int)), page: Int) -> List(Int) {
  rules
  |> list.filter(fn(r) { r.0 == page })
  |> list.map(pair.second)
}

fn must_come_after(rules: List(#(Int, Int)), page: Int) -> List(Int) {
  rules
  |> list.filter(fn(r) { r.1 == page })
  |> list.map(pair.first)
}

pub fn update_ok(rules: List(#(Int, Int)), update: List(Int)) -> Bool {
  let indices =
    update
    |> list.index_map(fn(page, idx) { #(page, idx) })
    |> dict.from_list

  let page_ok = fn(page: Int) -> Bool {
    let befores = must_come_before(rules, page)
    let afters = must_come_after(rules, page)

    check_befores(indices, befores, page) && check_afters(indices, afters, page)
  }

  list.all(update, page_ok)
}

fn check_befores(
  indices: dict.Dict(Int, Int),
  pages: List(Int),
  page: Int,
) -> Bool {
  let assert Ok(page_index) = dict.get(indices, page)
  let page_indices =
    pages
    |> list.map(dict.get(indices, _))
    |> result.values

  case page_index, page_indices {
    _, [] -> True
    n, xs -> list.all(xs, fn(x) { x > n })
  }
}

fn check_afters(
  indices: dict.Dict(Int, Int),
  pages: List(Int),
  page: Int,
) -> Bool {
  let assert Ok(page_index) = dict.get(indices, page)
  let page_indices =
    pages
    |> list.map(dict.get(indices, _))
    |> result.values

  case page_index, page_indices {
    _, [] -> True
    n, xs -> list.all(xs, fn(x) { x < n })
  }
}

pub fn solve_part_1(input: Update) -> Int {
  input.updates
  |> list.filter(update_ok(input.rules, _))
  |> list.map(get_middle)
  |> int.sum
}

pub fn get_middle(xs: List(t)) -> t {
  let assert #(_head, [x, ..]) = list.split(xs, list.length(xs) / 2)
  x
}

fn make_comparator(rules: List(#(Int, Int))) -> fn(Int, Int) -> order.Order {
  fn(a: Int, b: Int) -> order.Order {
    let a_before =
      rules |> list.filter(fn(p) { p.0 == a }) |> list.map(pair.second)
    let b_before =
      rules |> list.filter(fn(p) { p.0 == b }) |> list.map(pair.second)
    let a_after =
      rules |> list.filter(fn(p) { p.1 == a }) |> list.map(pair.first)
    let b_after =
      rules |> list.filter(fn(p) { p.1 == b }) |> list.map(pair.first)

    let #(a_before_b, b_before_a, a_after_b, b_after_a) = #(
      list.contains(a_before, b),
      list.contains(b_before, a),
      list.contains(a_after, b),
      list.contains(b_after, a),
    )
    case a_before_b, b_before_a, a_after_b, b_after_a {
      True, _, _, _ -> order.Lt
      _, True, _, _ -> order.Gt
      _, _, True, _ -> order.Lt
      _, _, _, True -> order.Gt
      _, _, _, _ -> order.Eq
    }
  }
}

pub fn solve_part_2(input: Update) -> Int {
  let comparator = make_comparator(input.rules)

  input.updates
  |> list.filter(fn(upd) { !update_ok(input.rules, upd) })
  |> list.map(list.sort(_, comparator))
  |> list.map(get_middle)
  |> int.sum
}

const example_src = "47|53
97|13
97|61
97|47
75|29
61|13
75|53
29|13
97|29
53|29
61|53
97|53
61|29
47|13
75|47
97|75
47|61
75|61
47|29
75|13
53|13

75,47,61,53,29
97,61,53,29,13
75,29,13
75,97,47,61,53
61,13,29
97,13,75,29,47"

pub fn main() {
  let example_input = parse_source(example_src)
  let assert Ok(src) = simplifile.read("src/y2024/d05/input.txt")
  let input = parse_source(src)

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
