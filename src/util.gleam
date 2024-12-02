import gleam/int

pub fn unsafe_parse_int(src: String) -> Int {
  let assert Ok(n) = int.parse(src)
  n
}
