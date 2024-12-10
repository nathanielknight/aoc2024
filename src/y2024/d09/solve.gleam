import gleam/int
import gleam/io
import gleam/list
import gleam/option.{type Option, None, Some}
import gleam/order.{Eq, Gt, Lt}
import gleam/string
import simplifile
import util

const example_source = "2333133121414131402"

type Input =
  List(Option(Int))

pub type DiskLayout =
  Input

pub fn parse_source(source: String) -> Input {
  source
  |> string.trim
  |> string.to_graphemes
  |> list.map(util.unsafe_parse_int)
  |> do_parse_source(0, [])
  |> list.flatten
  |> list.reverse
}

fn do_parse_source(
  chars: List(Int),
  block_id: Int,
  inputs: List(List(Option(Int))),
) -> List(Input) {
  case chars {
    [] -> inputs
    [blk] -> [list.repeat(Some(block_id), blk), ..inputs]
    [blk, empty, ..rest] ->
      do_parse_source(rest, block_id + 1, [
        list.repeat(None, empty),
        list.repeat(Some(block_id), blk),
        ..inputs
      ])
  }
}

pub fn format_input(input: Input) {
  let print_blk = fn(blk: Option(Int)) {
    case blk {
      Some(n) -> int.to_string(n)
      None -> "."
    }
  }
  list.map(input, print_blk)
  |> string.join("")
}

pub fn compact(input: Input) -> Input {
  let insert_sectors =
    input
    |> list.reverse
    |> list.filter(option.is_some)
  let fillsize = list.count(input, option.is_some)
  let compacted = do_compact([], input, insert_sectors, fillsize)
  list.flatten([list.repeat(None, list.length(input) - fillsize), compacted])
  |> list.reverse
}

fn do_compact(
  layout: DiskLayout,
  input: DiskLayout,
  insert_sectors: DiskLayout,
  fillsize: Int,
) -> DiskLayout {
  case list.length(layout) >= fillsize {
    True -> layout
    False ->
      case input {
        [Some(n), ..rest] ->
          do_compact([Some(n), ..layout], rest, insert_sectors, fillsize)
        [None, ..rest_input] ->
          case insert_sectors {
            [Some(m), ..rest_insert] ->
              do_compact([Some(m), ..layout], rest_input, rest_insert, fillsize)
            [] -> do_compact([None, ..layout], rest_input, [], fillsize)
            _ -> panic as "unreachable none insert"
          }
        [] -> panic as "unreachable empty layout"
      }
  }
}

fn checksum(layout: DiskLayout) -> Int {
  layout
  |> list.index_map(fn(sector, idx) {
    case sector {
      Some(n) -> idx * n
      None -> 0
    }
  })
  |> int.sum
}

pub type File {
  File(id: Int, size: Int)
}

pub type FileEntity {
  EntityEmpty(size: Int)
  EntityFile(File)
}

pub type FileMap =
  List(FileEntity)

pub fn parse_file_map(source: String) -> FileMap {
  source
  |> string.trim
  |> string.to_graphemes
  |> list.map(util.unsafe_parse_int)
  |> do_parse_file(0, [])
  |> list.reverse
}

fn do_parse_file(inputs: List(Int), file_id: Int, map: FileMap) -> FileMap {
  case inputs {
    [] -> map
    [n] -> [EntityFile(File(id: file_id, size: n)), ..map]
    [n, e, ..rest] ->
      do_parse_file(rest, file_id + 1, [
        EntityEmpty(size: e),
        EntityFile(File(id: file_id, size: n)),
        ..map
      ])
  }
}

pub fn compact_files(inputs: FileMap) -> FileMap {
  let files =
    inputs
    |> list.reverse
    |> list.filter_map(fn(f) {
      case f {
        EntityEmpty(_) -> Error(Nil)
        EntityFile(f) -> Ok(f)
      }
    })
  do_compact_files(inputs, files)
}

fn do_compact_files(inputs: FileMap, files: List(File)) -> FileMap {
  case files {
    [] -> inputs
    [f, ..files] -> do_compact_files(try_place_file(inputs, f), files)
  }
}

fn try_place_file(inputs: FileMap, file: File) -> FileMap {
  do_try_place_file([], inputs, file)
}

fn do_try_place_file(seen: FileMap, inputs: FileMap, file: File) -> FileMap {
  // TODO: replace the moved file with empty space
  // TODO: consolidate adjacent empty spaces
  case inputs {
    [] -> list.reverse(seen)
    [EntityFile(f), ..rest_inputs] -> {
      case f.id == file.id {
        True -> list.append(list.reverse(seen), inputs)
        False -> do_try_place_file([EntityFile(f), ..seen], rest_inputs, file)
      }
    }
    [EntityEmpty(size) as e, ..rest_inputs] -> {
      case int.compare(size, file.size) {
        Lt -> do_try_place_file([e, ..seen], rest_inputs, file)
        Eq -> {
          let rest_inputs = remove_file(file, rest_inputs)
          list.flatten([list.reverse(seen), [EntityFile(file)], rest_inputs])
        }
        Gt -> {
          let rest_inputs = remove_file(file, rest_inputs)
          let remainder = EntityEmpty(size - file.size)
          list.flatten([
            list.reverse(seen),
            [EntityFile(file), remainder],
            rest_inputs,
          ])
        }
      }
    }
  }
}

fn remove_file(f: File, map: FileMap) -> FileMap {
  map
  |> list.map(fn(e) {
    case e == EntityFile(f) {
      True -> EntityEmpty(f.size)
      False -> e
    }
  })
  |> consolidate_empty_memory
}

fn consolidate_empty_memory(layout: FileMap) -> FileMap {
  let do_fold = fn(consolidated, next) {
    case consolidated, next {
      _, EntityFile(_) as f -> [f, ..consolidated]
      [EntityEmpty(a), ..rest], EntityEmpty(b) -> [EntityEmpty(a + b), ..rest]
      xs, EntityEmpty(_) as e -> [e, ..xs]
    }
  }
  layout |> list.fold([], do_fold) |> list.reverse
}

fn solve_part_1(input: Input) -> Int {
  input
  |> compact
  |> checksum
}

fn solve_part_2(map: FileMap) -> Int {
  map
  |> compact_files
  |> filemap_to_disklayout
  |> checksum
}

pub fn filemap_to_disklayout(map: FileMap) -> DiskLayout {
  map
  |> list.map(fn(m) {
    case m {
      EntityFile(f) -> list.repeat(Some(f.id), f.size)
      EntityEmpty(e) -> list.repeat(None, e)
    }
  })
  |> list.flatten
}

fn format_filemap(m: FileMap) -> String {
  m
  |> filemap_to_disklayout
  |> format_input
}

fn debug_filemap(m: FileMap) -> FileMap {
  m
  |> filemap_to_disklayout
  |> format_input
  |> io.debug

  m
}

pub fn main() {
  let example_input = parse_source(example_source)
  let example_input_part2 = parse_file_map(example_source)
  let assert Ok(source) = simplifile.read("src/y2024/d09/input.txt")
  let input = parse_source(source)
  let input_part2 = parse_file_map(source)

  example_input
  |> solve_part_1
  |> io.debug

  example_input_part2
  |> compact_files
  |> filemap_to_disklayout
  |> checksum
  |> io.debug

  // input
  // |> solve_part_1
  // |> io.debug

  input_part2
  |> compact_files
  |> filemap_to_disklayout
  |> checksum
  |> io.debug

  Nil
}
