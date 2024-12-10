import gleeunit/should
import y2024/d09/solve

pub fn parse_source_test() {
  "2333133121414131402"
  |> solve.parse_source
  |> solve.format_input
  |> should.equal("00...111...2...333.44.5555.6666.777.888899")
}

pub fn compact_test() {
  "2333133121414131402"
  |> solve.parse_source
  |> solve.compact
  |> solve.format_input
  |> should.equal("0099811188827773336446555566..............")
}

pub fn compact_file_test() {
  "2333133121414131402"
  |> solve.parse_file_map
  |> solve.compact_files
  |> solve.filemap_to_disklayout
  |> solve.format_input
  |> should.equal("00992111777.44.333....5555.6666.....8888..")
}
