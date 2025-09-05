// 主函数

///|
pub fn read_coverage_file(path : String) -> Result[CoverageData, String] {
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

///|
pub fn load_source_files(
  data : CoverageData,
  source_dir : String,
) -> Map[String, String] {
  let source_map = Map::new()

  // 使用 each 方法遍历文件
  data.files.each(fn(filename : String, coverage : FileCoverage) {
    // 尝试多种可能的路径格式
    let possible_paths = [
      // 1. 直接使用文件名
      filename,
      // 2. 移除可能的路径前缀
      filename.replace(old="src/", new=""),
      filename.replace(old="src\\", new=""),
      // 3. 只保留文件名部分
      basename(filename),
      // 4. 尝试不同扩展名
      filename.replace(old=".mbt", new=".ml"),
      filename.replace(old=".ml", new=".mbt"),
      // 5. 尝试不同路径分隔符
      filename.replace(old="/", new="\\"),
      filename.replace(old="\\", new="/"),
    ]
    let mut found = false
    for path in possible_paths {
      // 使用自定义的路径拼接函数
      let file_path = join_path(source_dir, path)
      try {
        let content = @fs.read_file_to_string(file_path)
        source_map.set(filename, content)
        println("✅ 找到源文件: " + file_path)
        found = true
        break
      } catch {
        IOError(_) => ignore(())
      }
    }
    if !found {
      println("⚠️ 警告: 源文件未找到: " + filename)
      // 尝试在源代码目录中搜索文件名
      match find_file_in_directory(source_dir, basename(filename)) {
        Some(found_path) =>
          try {
            let content = @fs.read_file_to_string(found_path)
            source_map.set(filename, content)
            println("✅ 在 " + found_path + " 找到匹配文件")
          } catch {
            IOError(msg) =>
              println(
                "⚠️ 警告: 无法读取找到的文件: " +
                found_path +
                ", " +
                msg,
              )
          }
        None => println("❌ 错误: 未找到任何匹配文件")
      }
    }
  })
  source_map
}
