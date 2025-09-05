// parser.mbt
///|
pub fn parse_bisect(input : String) -> Result[CoverageData, String] {
  // 辅助函数：将字符串转换为整数
  fn parse_int(s : String) -> Int? {
    let mut num = 0
    let mut valid = false
    for c in s.iter() {
      let char_val = c.to_int()
      if char_val >= '0'.to_int() && char_val <= '9'.to_int() {
        num = num * 10 + (char_val - '0'.to_int())
        valid = true
      } else {
        return None
      }
    }
    if valid {
      Some(num)
    } else {
      None
    }
  }

  println("开始解析覆盖率文件...")
  let identifier = "BISECT-COVERAGE-4"

  // 检查文件头
  if input.starts_with(identifier) == None {
    return Err("Invalid Bisect coverage file format: missing header")
  }

  // 移除文件头
  let content = input.strip_prefix(identifier).unwrap_or("")

  // 分割字符串为token列表
  let tokens = content
    .split(" ")
    .filter(fn(s) { !s.is_empty() })
    .map(fn(s) { s.to_string() })
    .collect()
  println("Tokens: " + tokens.to_string())
  let mut index = 0
  let files = Map::new()
  let mut total_points = 0
  let mut covered_points = 0

  // 解析文件数量
  if index >= tokens.length() {
    return Err("Missing file count")
  }
  let file_count = match parse_int(tokens[index]) {
    Some(count) => {
      index += 1
      count
    }
    None => return Err("Failed to parse file count: " + tokens[index])
  }
  println("文件数量: " + file_count.to_string())

  // 循环解析每个文件
  for file_idx in 0..<file_count {
    // 解析文件名长度
    if index >= tokens.length() {
      return Err("Unexpected end of file while parsing filename length")
    }
    let filename_len = match parse_int(tokens[index]) {
      Some(len) => {
        index += 1
        len
      }
      None => return Err("Failed to parse filename length: " + tokens[index])
    }

    // 解析文件名
    if index >= tokens.length() {
      return Err("Unexpected end of file while parsing filename")
    }
    let filename = tokens[index]
    index += 1

    // 解析点位数组长度
    if index >= tokens.length() {
      return Err("Unexpected end of file while parsing points length")
    }
    let points_length = match parse_int(tokens[index]) {
      Some(len) => {
        index += 1
        len
      }
      None => return Err("Failed to parse points length: " + tokens[index])
    }

    // 解析点位数组
    if index + points_length > tokens.length() {
      return Err("Unexpected end of file while parsing points array")
    }
    let mut points = @list.empty()
    for i in 0..<points_length {
      let point_val = match parse_int(tokens[index + i]) {
        Some(val) => val
        None => return Err("Failed to parse point value: " + tokens[index + i])
      }
      points = @list.add(points, point_val)
    }
    index += points_length

    // 计算点位数（每个点由两个整数表示）
    let point_count = points_length / 2

    // 解析计数数组长度声明（但我们忽略它）
    if index >= tokens.length() {
      return Err("Unexpected end of file while parsing counts length")
    }
    let counts_length_declared = match parse_int(tokens[index]) {
      Some(len) => {
        index += 1
        len
      }
      None => return Err("Failed to parse counts length: " + tokens[index])
    }

    // 解析计数数组 - 我们只读取 point_count 个值
    let mut counts = @list.empty()
    for i in 0..<point_count {
      if index >= tokens.length() {
        // 如果计数不足，使用0填充
        counts = @list.add(counts, 0)
        continue
      }
      let count_val = match parse_int(tokens[index]) {
        Some(val) => val
        None => 0 // 如果解析失败，使用0
      }
      counts = @list.add(counts, count_val)
      index += 1
    }

    // 跳过多余的计数值（如果有）
    let remaining_counts = counts_length_declared - point_count
    if remaining_counts > 0 {
      if index + remaining_counts > tokens.length() {
        println("⚠️ Warning: Extra counts missing for file: " + filename)
      } else {
        index += remaining_counts
      }
    }

    // 构建覆盖点列表并计算覆盖率
    let mut file_points_list = @list.empty()
    let mut file_covered = 0
    for i in 0..<point_count {
      let start_offset = match points.nth(i * 2) {
        Some(val) => val
        None =>
          return Err("Missing start offset at index " + (i * 2).to_string())
      }
      let end_offset = match points.nth(i * 2 + 1) {
        Some(val) => val
        None =>
          return Err("Missing end offset at index " + (i * 2 + 1).to_string())
      }
      let count = if i < counts.length() {
        counts.nth(i).unwrap_or(0)
      } else {
        0
      }
      if count > 0 {
        file_covered += 1
      }
      file_points_list = @list.add(file_points_list, CoveragePoint::{
        start_offset,
        end_offset,
        count,
      })
    }

    // 添加到文件集
    files.set(filename, FileCoverage::{
      filename,
      points: file_points_list,
      total_points: point_count,
      covered_points: file_covered,
    })
    total_points += point_count
    covered_points += file_covered
  }

  // 返回完整覆盖数据
  Ok(CoverageData::{ files, total_points, covered_points })
}
