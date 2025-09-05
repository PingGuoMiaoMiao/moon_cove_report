// query.mbt
// 查询点位执行次数

///|
pub fn get_point_execution(
  data : CoverageData,
  file : String,
  start : Int,
  end : Int,
) -> Int? {
  match data.files.get(file) {
    Some(coverage) =>
      // 使用 find 方法查找匹配的点位
      match
        coverage.points.find(fn(point : CoveragePoint) {
          point.start_offset == start && point.end_offset == end
        }) {
        Some(point) => Some(point.count)
        None => None
      }
    None => None
  }
}

// 查询文件所有点位

///|
pub fn get_file_points(
  data : CoverageData,
  file : String,
) -> @list.List[CoveragePoint] {
  match data.files.get(file) {
    Some(coverage) => coverage.points
    None => @list.empty()
  }
}

// 查询文件覆盖率百分比

///|
pub fn get_file_coverage(data : CoverageData, file : String) -> Double? {
  match data.files.get(file) {
    Some(f) =>
      if f.total_points == 0 {
        Some(0.0)
      } else {
        Some(f.covered_points.to_double() * 100.0 / f.total_points.to_double())
      }
    None => None
  }
}

// 修改总体覆盖率计算函数

///|
pub fn get_overall_coverage(data : CoverageData) -> Double {
  if data.total_points == 0 {
    0.0
  } else {
    data.covered_points.to_double() * 100.0 / data.total_points.to_double()
  }
}

// 导出CSV

///|
pub fn export_to_csv(data : CoverageData) -> String {
  let mut csv = "File,Start Offset,End Offset,Execution Count\n"

  // 使用 each 方法遍历文件
  data.files.each(fn(filename : String, coverage : FileCoverage) {
    // 使用 each 方法遍历点位
    coverage.points.each(fn(point : CoveragePoint) {
      csv = csv +
        filename +
        "," +
        point.start_offset.to_string() +
        "," +
        point.end_offset.to_string() +
        "," +
        point.count.to_string() +
        "\n"
    })
  })
  csv
}
