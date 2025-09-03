import parser
import mapper
import reporter
import coverage_data
import test

fn test_html_generation() {
  let content = file::read_to_string("test_data/sample.bisect").expect("Read file")
  let data = parser::parse_bisect(content)
  
  let source = "let add a b = a + b\n\nlet sub a b = a - b\n\nlet main () =\n  let result = add 3 2 in\n  print_int result"
  let source_map = Map::empty().insert("sample.ml", source)
  
  let views = mapper::map_to_line_view(data, source_map)
  let html = reporter::generate_html_report(views, 66.67)
  
  test::assert_true(html.contains("MoonCove Coverage Report"), "HTML title")
  test::assert_true(html.contains("sample.ml"), "Filename in report")
  test::assert_true(html.contains("let add a b = a + b"), "Source code in report")
  test::assert_true(html.contains("covered"), "Coverage CSS class")
}

fn test_line_mapping() {
  let source = "line1\nline2\nline3"
  let line_map = mapper::build_line_map(source)
  
  test::assert_eq(line_map.length(), 3, "Line count")
  test::assert_eq(line_map[0].line, 1, "First line number")
  test::assert_eq(line_map[0].start_offset, 0, "First line start")
  test::assert_eq(line_map[0].end_offset, 5, "First line end")
  
  test::assert_eq(line_map[1].line, 2, "Second line number")
  test::assert_eq(line_map[1].start_offset, 6, "Second line start")
  test::assert_eq(line_map[1].end_offset, 11, "Second line end")
}

fn run_tests() {
  test::run("Visualization Tests", [
    test_html_generation,
    test_line_mapping
  ])
}