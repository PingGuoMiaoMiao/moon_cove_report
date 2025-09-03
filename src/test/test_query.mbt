import parser
import query
import coverage_data
import test

fn test_point_query() {
  let content = file::read_to_string("test_data/sample.bisect").expect("Read file")
  let data = parser::parse_bisect(content)
  
  let count = query::get_point_execution(data, "sample.ml", 20, 25)
  test::assert_eq(count, Some(0), "Point execution count")
  
  let count = query::get_point_execution(data, "sample.ml", 30, 35)
  test::assert_eq(count, Some(1), "Point execution count")
}

fn test_line_query() {
  let content = file::read_to_string("test_data/sample.bisect").expect("Read file")
  let data = parser::parse_bisect(content)
  
  let source = "let add a b = a + b\n\nlet sub a b = a - b\n\nlet main () =\n  let result = add 3 2 in\n  print_int result"
  
  let line1 = query::get_line_execution(data, "sample.ml", 1, source)
  test::assert_eq(line1, Some(1), "Line 1 coverage")
  
  let line3 = query::get_line_execution(data, "sample.ml", 3, source)
  test::assert_eq(line3, Some(0), "Line 3 coverage")
}

fn test_file_coverage() {
  let content = file::read_to_string("test_data/sample.bisect").expect("Read file")
  let data = parser::parse_bisect(content)
  
  let coverage = query::get_file_coverage(data, "sample.ml")
  test::assert_eq(coverage, Some(66.67), "File coverage percentage")
}

fn run_tests() {
  test::run("Query Tests", [
    test_point_query,
    test_line_query,
    test_file_coverage
  ])
}