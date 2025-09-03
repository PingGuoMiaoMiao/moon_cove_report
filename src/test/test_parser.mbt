import parser
import coverage_data
import test

fn test_parse_basic() {
  let content = file::read_to_string("test_data/sample.bisect").expect("Read file")
  let data = parser::parse_bisect(content)
  
  test::assert_eq(data.files.size(), 1, "Should have one file")
  
  match data.files.get("sample.ml") {
    Some(file) => {
      test::assert_eq(file.points.length(), 3, "Should have 3 coverage points")
      test::assert_eq(file.points[0].start_offset, 10, "First point start offset")
      test::assert_eq(file.points[0].end_offset, 15, "First point end offset")
      test::assert_eq(file.points[0].count, 1, "First point count")
      
      test::assert_eq(file.points[1].start_offset, 20, "Second point start offset")
      test::assert_eq(file.points[1].end_offset, 25, "Second point end offset")
      test::assert_eq(file.points[1].count, 0, "Second point count")
      
      test::assert_eq(file.points[2].start_offset, 30, "Third point start offset")
      test::assert_eq(file.points[2].end_offset, 35, "Third point end offset")
      test::assert_eq(file.points[2].count, 1, "Third point count")
    }
    None => test::fail("File 'sample.ml' not found")
  }
}

fn test_parse_multiple_files() {
  let content = "BISECT-COVERAGE-4 2 8 file1.ml 4 10 20 30 40 2 1 2 8 file2.ml 4 50 60 70 80 2 3 4"
  let data = parser::parse_bisect(content)
  
  test::assert_eq(data.files.size(), 2, "Should have two files")
  
  match data.files.get("file1.ml") {
    Some(file) => {
      test::assert_eq(file.points.length(), 2, "File1 should have 2 points")
      test::assert_eq(file.points[0].start_offset, 10, "File1 point1 start")
      test::assert_eq(file.points[0].end_offset, 20, "File1 point1 end")
      test::assert_eq(file.points[0].count, 1, "File1 point1 count")
    }
    None => test::fail("File 'file1.ml' not found")
  }
}

fn run_tests() {
  test::run("Parser Tests", [
    test_parse_basic,
    test_parse_multiple_files
  ])
}