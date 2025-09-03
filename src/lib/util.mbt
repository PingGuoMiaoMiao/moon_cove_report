// 路径处理辅助函数
pub fn join_path(path1: String, path2: String) -> String {
  if path1.strip_suffix("/") != None {
    path1 + path2
  } else {
    path1 + "/" + path2
  }
}

pub fn dirname(path: String) -> String {
  // 反转字符串
  let reversed = path.rev()
  
  // 查找第一个斜杠 (反转后)
  match reversed.find("/") {
    Some(pos) => {
      // 计算原始位置
      let idx = path.length() - 1 - pos
      
      // 创建空字符串构建器
      let builder = StringBuilder::new()
      
      // 复制从 0 到 idx 的字符
      for i in 0..=idx {
        match path.get_char(i) {
          Some(c) => builder.write_char(c)
          None => break
        }
      }
      
      builder.to_string()
    }
    None => "."
  }
}

// 主函数
pub fn read_coverage_file(path: String) -> Result[CoverageData, String] {
  try {
    let content = @fs.read_file_to_string(path)
    match parse_bisect(content) {
      Ok(data) => Ok(data)
      Err(msg) => Err("Failed to parse coverage file: " + path + ", " + msg)
    }
  } catch {
    IOError(msg) => Err("Failed to read coverage file: " + path + ", " + msg)
  }
}

pub fn load_source_files(data: CoverageData, source_dir: String) -> Map[String, String] {
  let  source_map = Map::new()
  
  for filename in data.files.keys() {
    // 处理 OCaml 的特殊情况
    let source_file = match filename.strip_suffix(".re.ml") {
      Some(prefix) => prefix.to_string() // 转换为 String
      None => filename
    }
    
    // 使用自定义的路径拼接函数
    let file_path = join_path(source_dir, source_file)
    
    try {
      let content = @fs.read_file_to_string(file_path)
      // 使用 put 方法添加元素
      source_map[filename] = content
    } catch {
      IOError(msg) => println("Warning: Source file not found: " + filename + ", error: " + msg)
    }
  }
  
  source_map
}

pub fn save_report(report_html: String, output_path: String) -> Result[Unit, String] {
  try {
    // 确保输出目录存在
    match ensure_output_dir_exists(output_path) {
      Ok(_) => ignore(Ok(_))
      Err(msg) => return Err(msg)
    }
    
    @fs.write_string_to_file(output_path, report_html)
    Ok(())
  } catch {
    IOError(msg) => Err("Failed to write report: " + msg)
  }
}

pub fn ensure_output_dir_exists(output_path: String) -> Result[Unit, String] {
  // 使用自定义的目录名函数
  let dir_path = dirname(output_path)
  
  if !@fs.path_exists(dir_path) {
    try {
      @fs.create_dir(dir_path)
      Ok(())
    } catch {
      IOError(msg) => Err("Failed to create directory: " + msg)
    }
  } else {
    Ok(())
  }
}