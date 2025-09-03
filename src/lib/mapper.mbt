struct LineMapEntry {
  line : Int
  start_offset : Int
  end_offset : Int
}

fn build_line_map(source : String) -> @list.List[LineMapEntry] {
  // 初始化状态变量
  let mut current_offset = 0
  let mut current_line = 1
  let mut line_start = 0
  let mut entries : @list.List[LineMapEntry] = @list.empty()
  for ch in source.iter() {
    let char_size = match ch.utf16_len() {
      1 =>
        if ch.to_int() < 0x80 {
          1
        } else if ch.to_int() < 0x800 {
          2
        } else {
          3
        }
      _ => 4
    }
    current_offset = current_offset + char_size
    if ch == '\n' {
      // 创建新行记录
      let entry = LineMapEntry::{
        line: current_line,
        start_offset: line_start,
        end_offset: current_offset - 1, // 换行符前的位置
      }

      // 添加条目到列表
      entries = entries.add(entry)

      // 更新行起始位置和行号
      line_start = current_offset
      current_line += 1
    }
  }
  entries // 返回行映射表
}

pub fn map_to_line_view(
  data : CoverageData,
  source_files : Map[String, String],
) -> @list.List[FileCoverageView] {
  let mut views : @list.List[FileCoverageView] = @list.empty()

  // 遍历每个文件的覆盖率数据
  data.files.each(fn(filename : String, coverage : FileCoverage) {
    match source_files.get(filename) {
      Some(source) => {
        let line_map = build_line_map(source)
        let lines_map : Map[Int, LineCoverage] = Map::new() // 创建新的Map

        // 正确使用List的iter方法：获取迭代器然后遍历
        line_map
        .iter()
        .each(fn(entry : LineMapEntry) {
          // 使用Map的set方法添加键值对
          lines_map.set(entry.line, LineCoverage::{ line: entry.line, count: 0 })
        })

        // 计算每行的最大执行次数
        coverage.points
        .iter()
        .each(fn(point : CoveragePoint) {
          // 查找包含点位的行
          line_map
          .iter()
          .each(fn(entry : LineMapEntry) {
            if point.start_offset >= entry.start_offset &&
              point.start_offset <= entry.end_offset {
              // 使用Map的get方法获取当前值
              let current = match lines_map.get(entry.line) {
                Some(lc) => lc
                None => LineCoverage::{ line: entry.line, count: 0 }
              }

              // 取该行点的最大执行次数
              // 使用Map的set方法更新值
              lines_map.set(entry.line, LineCoverage::{
                line: entry.line,
                count: if point.count > current.count {
                  point.count
                } else {
                  current.count
                },
              })
            }
          })
        })

        // 转换为视图并添加到结果列表
        views = @list.add(views, FileCoverageView::{
          filename,
          source,
          lines: lines_map,
        })
      }
      None => println("Warning: Source file not found: " + filename)
    }
  })
  views
}