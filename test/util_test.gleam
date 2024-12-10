import gleeunit/should
import util

pub fn rectilinear_distance_test() {
  util.rectilinear_distance(#(0, 0), #(1, 1))
  |> should.equal(2)

  util.rectilinear_distance(#(1, 1), #(0, 0))
  |> should.equal(2)

  util.rectilinear_distance(#(5, 0), #(0, 0))
  |> should.equal(5)

  util.rectilinear_distance(#(-1, 1), #(1, -1))
  |> should.equal(4)
}
