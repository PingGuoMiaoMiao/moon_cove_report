import parser
import merger
import coverage_data
import test

fn create_file(name: String, points: List<coverage_data::CoveragePoint>) -> coverage_data::FileCoverage {
  let covered = points.count(fn(p) { p.count > 0 })
  coverage_data::FileCoverage {
    filename: name,
    points: points,
    total_points: points.length(),
    covered_points: covered
  }
}

fn test_merge_same_file() {
  let file1 = create_file("test.ml", [
    {start_offset: 10, end_offset: 15, count: 1},
    {start_offset: 20, end_offset: 25, count: 0}
  ])
  
  let file2 = create_file("test.ml", [
    {start_offset: 10, end_offset: 15, count: 2},
    {start_offset: 20, end_offset: 25, count: 1}
  ])
  
  let data1 = coverage_data::CoverageData {
    files: Map::empty().insert("test.ml", file1),
    total_points: 2,
    covered_points: 1
  }
  
  let data2 = coverage_data::CoverageData {
    files: Map::empty().insert("test.ml", file2),
    total_points: 2,
    covered_points: 2
  }
  
  let merged = merger::merge_coverage(data1, data2)
  
  test::assert_eq(merged.files.size(), 1, "Should have one file")
  
  match merged.files.get("test.ml") {
    Some(file) => {
      test::assert_eq(file.points.length(), 2, "Should have 2 points")
      test::assert_eq(file.points[0].count, 3, "First point count")
      test::assert_eq(file.points[1].count, 1, "Second point count")
      test::assert_eq(file.covered_points, 2, "Covered points")
    }
    None => test::fail("File not found")
  }
}

fn test_merge_different_files() {
  let file1 = create_file("file1.ml", [
    {start_offset: 10, end_offset: 15, count: 1}
  ])
  
  let file2 = create_file("file2.ml", [
    {start_offset: 20, end_offset: 25, count: 2}
  ])
  
  let data1 = coverage_data::CoverageData {
    files: Map::empty().insert("file1.ml", file1),
    total_points: 1,
    covered_points: 1
  }
  
  let data2 = coverage_data::CoverageData {
    files: Map::empty().insert("file2.ml", file2),
    total_points: 1,
    covered_points: 1
  }
  
  let merged = merger::merge_coverage(data1, data2)
  
  test::assert_eq(merged.files.size(), 2, "Should have two files")
  test::assert_eq(merged.total_points, 2, "Total points")
  test::assert_eq(merged.covered_points, 2, "Covered points")
}

fn run_tests() {
  test::run("Merger Tests", [
    test_merge_same_file,
    test_merge_different_files
  ])
}