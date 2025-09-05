///|
struct LineMapEntry {
  line : Int
  start_offset : Int
  end_offset : Int
}

///|
fn build_line_map(source : String) -> @list.List[LineMapEntry] {
  println("开始构建行映射表...")
  let mut entries : @list.List[LineMapEntry] = @list.empty()
  let mut current_offset = 0
  let mut current_line = 1
  let mut line_start = 0
  let mut char_count = 0
  for c in source.iter() {
    char_count += 1
    let char_val = c.to_int()

    // 计算字符在UTF-16中的长度
    let char_size = if char_val <= 0xFFFF { 1 } else { 2 }
    current_offset += char_size

    // 遇到换行符时创建新行
    if c == '\n' {
      let entry = LineMapEntry::{
        line: current_line,
        start_offset: line_start,
        end_offset: current_offset - 1, // 换行符前的位置
      }
      entries = @list.add(entries, entry)
      line_start = current_offset
      current_line += 1
    }
  }

  // 添加最后一行（如果没有以换行符结尾）
  if char_count > 0 && source.get_char(char_count - 1) != Some('\n') {
    let entry = LineMapEntry::{
      line: current_line,
      start_offset: line_start,
      end_offset: current_offset,
    }
    entries = @list.add(entries, entry)
  }
  println("构建行映射表完成，总行数: " + current_line.to_string())
  entries
}

///|
pub fn map_to_line_view(
  data : CoverageData,
  source_files : Map[String, String],
) -> @list.List[FileCoverageView] {
  let mut views : @list.List[FileCoverageView] = @list.empty()

  // 遍历每个文件的覆盖率数据
  data.files.each(fn(filename : String, coverage : FileCoverage) {
    println("处理文件: " + filename)
    match source_files.get(filename) {
      Some(source) => {
        println("找到源代码文件: " + filename)
        let line_map = build_line_map(source)
        println(
          "构建行映射表完成，行数: " + line_map.length().to_string(),
        )
        let lines_map : Map[Int, LineCoverage] = Map::new()

        // 初始化行覆盖信息
        line_map
        .iter()
        .each(fn(entry : LineMapEntry) {
          lines_map.set(entry.line, LineCoverage::{ line: entry.line, count: 0 })
        })
        println("初始化行覆盖信息完成")

        // 计算每行的最大执行次数
        coverage.points
        .iter()
        .each(fn(point : CoveragePoint) {
          line_map
          .iter()
          .each(fn(entry : LineMapEntry) {
            // 修复1: 检查点位是否在行范围内
            if point.start_offset >= entry.start_offset &&
              point.start_offset <= entry.end_offset {
              let current = match lines_map.get(entry.line) {
                Some(lc) => lc
                None => LineCoverage::{ line: entry.line, count: 0 }
              }

              // 取该行点的最大执行次数
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
        println("计算行覆盖率完成")

        // 添加到视图列表
        views = @list.add(views, FileCoverageView::{
          filename,
          source,
          lines: lines_map,
        })
        println("添加文件视图: " + filename)
      }
      None => println("警告: 未找到源代码文件: " + filename)
    }
  })
  println("映射完成，生成视图数量: " + views.length().to_string())
  views
}
