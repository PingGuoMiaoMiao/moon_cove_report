pub struct CoveragePoint {
  start_offset : Int
  end_offset : Int
  count : Int
}

pub struct FileCoverage {
  filename : String
  points : @list.List[CoveragePoint]
  total_points : Int
  covered_points : Int
}

pub struct CoverageData {
  files : Map[String, FileCoverage]
  total_points : Int
  covered_points : Int
}

// 用于可视化的扩展数据结构
pub struct LineCoverage {
  line : Int
  count : Int
}

pub struct FileCoverageView {
  filename : String
  source : String
  lines : Map[Int, LineCoverage]
}