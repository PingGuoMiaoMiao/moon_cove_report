pub fn merge_coverage(a: CoverageData, b: CoverageData) -> CoverageData {
  // 创建 a.files 的副本
  let merged_files = a.files.copy()
  let mut total_points = a.total_points
  let mut covered_points = a.covered_points
  
  // 使用 each 方法遍历 b.files
  b.files.each(fn(filename: String, b_file: FileCoverage) {
    match merged_files.get(filename) {
      Some(a_file) => {
        match merge_file_coverage(a_file, b_file) {
          Ok(merged_file) => {
            merged_files.set(filename, merged_file)
            total_points = total_points - a_file.total_points + merged_file.total_points
            covered_points = covered_points - a_file.covered_points + merged_file.covered_points
          }
          Err(err) => {
            println("Warning: " + err)
            // 保留原始文件覆盖率
          }
        }
      }
      None => {
        merged_files.set(filename, b_file)
        total_points += b_file.total_points
        covered_points += b_file.covered_points
      }
    }
  })
  
  CoverageData::{
    files: merged_files,
    total_points: total_points,
    covered_points: covered_points
  }
}

fn merge_file_coverage(a: FileCoverage, b: FileCoverage) -> Result[FileCoverage, String] {
  // 检查点位结构一致性
  if a.points.length() != b.points.length() {
    return Err("Cannot merge coverage for different versions of the same file")
  }
  
  // 使用 fold 处理点对
  let merged_points_result = 
    a.points.zip(b.points).fold(
      init = Ok(@list.empty()), 
      fn(acc: Result[@list.List[CoveragePoint], String], pair: (CoveragePoint, CoveragePoint)) {
        match acc {
          Err(err) => Err(err) // 保持已有错误
          Ok(points) => {
            let (a_point, b_point) = pair
            // 检查点位位置
            if a_point.start_offset != b_point.start_offset || a_point.end_offset != b_point.end_offset {
              Err("Point offset mismatch in file " + a.filename)
            } else {
              let merged_point = CoveragePoint::{
                start_offset: a_point.start_offset,
                end_offset: a_point.end_offset,
                count: a_point.count + b_point.count
              }
              Ok(@list.add(points, merged_point))
            }
          }
        }
      }
    )
  
  match merged_points_result {
    Err(err) => Err(err)
    Ok(merged_points) => {
      // 使用 fold 实现 count 功能
      let new_covered = merged_points.fold(init=0, fn(count, point) {
        if point.count > 0 { count + 1 } else { count }
      })
      
      Ok(FileCoverage::{
        filename: a.filename,
        points: merged_points,
        total_points: a.total_points,
        covered_points: new_covered
      })
    }
  }
}