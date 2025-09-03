import parser
import serializer
import coverage_data
import test

fn test_serialize_basic() {
  let file = coverage_data::FileCoverage {
    filename: "test.ml",
    points: [
      {start_offset: 10, end_offset: 15, count: 1},
      {start_offset: 20, end_offset: 25, count: 0}
    ],
    total_points: 2,
    covered_points: 1
  }
  
  let data = coverage_data::CoverageData {
    files: Map::empty().insert("test.ml", file),
    total_points: 2,
    covered_points: 1
  }
  
  let serialized = serializer::serialize_bisect(data)
  let expected = "BISECT-COVERAGE-4 1 6 test.ml 4 10 15 20 25 2 1 0"
  
  test::assert_eq(serialized, expected, "Serialization output")
}

fn test_round_trip() {
  let original_content = file::read_to_string("test_data/sample.bisect").expect("Read file")
  let data = parser::parse_bisect(original_content)
  let serialized = serializer::serialize_bisect(data)
  
  test::assert_eq(serialized, original_content, "Round trip serialization")
}

fn run_tests() {
  test::run("Serializer Tests", [
    test_serialize_basic,
    test_round_trip
  ])
}