// 修改主函数
fn main {
  // 获取命令行参数
  let args = @sys.get_cli_args()
  
  if args.length() < 4 {
    println("Usage: " + args[0] + " <coverage_path> <source_dir> <output_dir>")
    println("Example: moon run main coverage.lcov src/ reports/")
    @sys.exit(1)
  }
  
  let coverage_path = args[1]
  let source_dir = args[2]
  let output_dir = args[3]
  
  println("Processing coverage report:")
  println("Coverage file: " + coverage_path)
  println("Source directory: " + source_dir)
  println("Output directory: " + output_dir)
  
  // 确保输出目录存在
  match ensure_output_dir_exists(output_dir) {
    Ok(_) => ignore(Ok(_))
    Err(msg) => {
      println("❌ Error creating output directory: " + msg)
      @sys.exit(1)
    }
  }
  
  // 读取覆盖率文件
  let mut coverage_data = CoverageData::{
    files: Map::new(),
    total_points: 0,
    covered_points: 0
  }
  match read_coverage_file(coverage_path) {
    Err(msg) => {
      println("❌ Error reading coverage file: " + msg)
      @sys.exit(1)
    }
    Ok(data) => {
      println("✅ Successfully read coverage data for " + 
              data.files.size().to_string() + " files")
      coverage_data = data
    }
  }
  
  // 加载源代码文件
  let source_files = load_source_files(coverage_data, source_dir)
  println("✅ Loaded " + source_files.size().to_string() + " source files")
  
  // 生成行视图
  let views = map_to_line_view(coverage_data, source_files)
  println("✅ Created coverage views for " + views.length().to_string() + " files")
  
  // 计算总体覆盖率
  let overall_coverage = get_overall_coverage(coverage_data)
  println("📊 Overall coverage: " + overall_coverage.to_string() + "%")
  
  // 生成主HTML报告
  let main_report_html = generate_main_report(views, coverage_data)
  println("🖥️ Generated main HTML report")
  
  // 保存主报告
  let main_report_path = join_path(output_dir, "index.html")
  match save_report(main_report_html, main_report_path) {
    Err(msg) => {
      println("❌ Error saving main report: " + msg)
      @sys.exit(1)
    }
    Ok(_) => {
      println("✅ Main report successfully saved to: " + main_report_path)
    }
  }
  
  // 为每个文件生成详细报告
  let mut current_view = views
  while current_view.length() > 0 {
    match current_view.head() {
      Some(view) => {
        let detail_report_html = generate_file_detail_report(view, coverage_data)
        
        // 生成安全的文件名
        let safe_filename = generate_safe_filename(view.filename)
        let detail_report_path = join_path(output_dir, safe_filename)
        
        match save_report(detail_report_html, detail_report_path) {
          Err(msg) => {
            println("❌ Error saving detail report for " + view.filename + ": " + msg)
          }
          Ok(_) => {
            println("✅ Detail report successfully saved to: " + detail_report_path)
          }
        }
        current_view = current_view.tail()
      }
      None => break
    }
  }
  
  println("🎉 Coverage report generation complete!")
  @sys.exit(0)
}

// 生成安全文件名的函数
fn generate_safe_filename(filename: String) -> String {
    // 替换所有可能引起路径问题的字符
    filename.replace(old = "/", new = "_")
        .replace(old = "\\", new = "_")
        .replace(old = ":", new = "_")
        .replace(old = "*", new = "_")
        .replace(old = "?", new = "_")
        .replace(old = "\"", new = "_")
        .replace(old = "<", new = "_")
        .replace(old = ">", new = "_")
        .replace(old = "|", new = "_")
        .replace(old = ".", new = "_") + ".html"
}

// util.mbt
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

// serializer.mbt
pub fn serialize_bisect(data: CoverageData) -> String {
  let buffer = StringBuilder::new()
  
  // 文件头
  buffer.write_object("BISECT-COVERAGE-4")
  
  // 文件数量
  buffer.write_object(" ")
  buffer.write_object(data.files.size().to_string())
  
  // 遍历每个文件
  data.files.each(fn(filename: String, coverage: FileCoverage) {
    // 文件名长度
    buffer.write_object(" ")
    buffer.write_object(filename.length().to_string())
    
    // 文件名
    buffer.write_object(" ")
    buffer.write_object(filename)
    
    // 点位数据（每两个元素表示一个点位）
    let mut points_arr = @list.empty()
    coverage.points.each(fn(point: CoveragePoint) {
      points_arr = @list.add(points_arr, point.start_offset)
      points_arr = @list.add(points_arr, point.end_offset)
    })
    
    // 点位数组长度
    buffer.write_object(" ")
    buffer.write_object(points_arr.length().to_string())
    
    // 点位数组内容
    points_arr.each(fn(point: Int) {
      buffer.write_object(" ")
      buffer.write_object(point.to_string())
    })
    
    // 执行次数数组
    let mut counts_arr = @list.empty()
    coverage.points.each(fn(point: CoveragePoint) {
      counts_arr = @list.add(counts_arr, point.count)
    })
    
    // 执行次数数组长度
    buffer.write_object(" ")
    buffer.write_object(counts_arr.length().to_string())
    
    // 执行次数内容
    counts_arr.each(fn(count: Int) {
      buffer.write_object(" ")
      buffer.write_object(count.to_string())
    })
  })
  
  // 返回生成的字符串
  buffer.to_string()
}

// 修改 generate_html_report 函数以生成完整的覆盖率报告
pub fn generate_html_report(views: @list.List[FileCoverageView], coverage_data: CoverageData) -> String {
    let overall_coverage = get_overall_coverage(coverage_data)
    let coverage_str = format_percentage(overall_coverage)
    
    // 构建 HTML 头部
    let html_header = 
        "<!DOCTYPE html>\n" +
        "<html lang=\"en\">\n" +
        "  <head>\n" +
        "    <meta charset=\"utf-8\"/>\n" +
        "    <title>Coverage report</title>\n" +
        "    <meta name=\"description\" content=\"" + coverage_str + " coverage overall\"/>\n" +
        "    <style>\n" +
        "      body { font-family: sans-serif; margin: 0; padding: 0; line-height: 1.6; background-color: #f8f8f8; }\n" +
        "      #header { text-align: center; margin-bottom: 20px; padding: 20px; background-color: white; border-bottom: 1px solid #ddd; }\n" +
        "      h1 { margin: 0; color: #333; }\n" +
        "      h2 { margin: 10px 0 0 0; font-size: 24px; color: #4CAF50; }\n" +
        "      #files { background-color: white; margin: 0 auto; max-width: 900px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }\n" +
        "      .file-item { display: flex; align-items: center; padding: 10px 15px; border-bottom: 1px solid #eee; }\n" +
        "      .meter { display: inline-block; width: 100px; height: 16px; background-color: #f0f0f0; border-radius: 3px; overflow: hidden; margin-right: 15px; }\n" +
        "      .covered { display: block; height: 100%; background-color: #4CAF50; border-radius: 3px; }\n" +
        "      .percentage { display: inline-block; width: 80px; text-align: right; margin-right: 15px; color: #4CAF50; font-weight: bold; }\n" +
        "      .dirname { color: #888; }\n" +
        "      .file-link { color: #0366d6; text-decoration: none; flex: 1; }\n" +
        "      .file-link:hover { text-decoration: underline; }\n" +
        "      .file-details { display: none; background-color: white; margin: 20px auto; max-width: 900px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); padding: 20px; }\n" +
        "      .file-header { margin-bottom: 15px; padding-bottom: 10px; border-bottom: 1px solid #eee; }\n" +
        "      .line-coverage { font-family: monospace; font-size: 14px; line-height: 1.4; }\n" +
        "      .line-number { display: inline-block; width: 40px; text-align: right; margin-right: 10px; color: #999; user-select: none; }\n" +
        "      .line-count { display: inline-block; width: 40px; text-align: right; margin-right: 10px; color: #4CAF50; font-weight: bold; user-select: none; }\n" +
        "      .line-content { white-space: pre-wrap; }\n" +
        "      .covered-line { background-color: #e8f5e9; }\n" +
        "      .uncovered-line { background-color: #ffebee; }\n" +
        "      .partial-line { background-color: #fff8e1; }\n" +
        "      .back-button { margin-bottom: 15px; padding: 5px 10px; background-color: #f0f0f0; border: 1px solid #ddd; border-radius: 3px; cursor: pointer; }\n" +
        "      .back-button:hover { background-color: #e0e0e0; }\n" +
        "    </style>\n" +
        "  </head>\n" +
        "  <body>\n" +
        "    <div id=\"header\">\n" +
        "      <h1>Coverage report</h1>\n" +
        "      <h2>" + coverage_str + "</h2>\n" +
        "    </div>\n" +
        "    <div id=\"files\">\n"
    
    // 生成文件行
    let file_rows = generate_file_rows(views, coverage_data)
    
    // 构建 HTML 尾部
    let html_footer = 
        "    </div>\n" +
        "    <div id=\"file-details-container\"></div>\n" +
        "    <script>\n" +
        "      function showFileCoverage(filename, source, lineData) {\n" +
        "        // 隐藏文件列表\n" +
        "        document.getElementById('files').style.display = 'none';\n" +
        "        \n" +
        "        // 创建文件详情容器\n" +
        "        const container = document.getElementById('file-details-container');\n" +
        "        container.innerHTML = '';\n" +
        "        \n" +
        "        // 创建返回按钮\n" +
        "        const backButton = document.createElement('div');\n" +
        "        backButton.className = 'back-button';\n" +
        "        backButton.textContent = '← Back to file list';\n" +
        "        backButton.onclick = function() {\n" +
        "          container.innerHTML = '';\n" +
        "          document.getElementById('files').style.display = 'block';\n" +
        "        };\n" +
        "        container.appendChild(backButton);\n" +
        "        \n" +
        "        // 创建文件详情区域\n" +
        "        const fileDetails = document.createElement('div');\n" +
        "        fileDetails.className = 'file-details';\n" +
        "        \n" +
        "        // 添加文件头部\n" +
        "        const fileHeader = document.createElement('div');\n" +
        "        fileHeader.className = 'file-header';\n" +
        "        fileHeader.innerHTML = '<h3>' + filename + '</h3>';\n" +
        "        fileDetails.appendChild(fileHeader);\n" +
        "        \n" +
        "        // 添加代码行覆盖详情\n" +
        "        const lineCoverage = document.createElement('div');\n" +
        "        lineCoverage.className = 'line-coverage';\n" +
        "        \n" +
        "        // 分割源代码为行\n" +
        "        const lines = source.split('\\n');\n" +
        "        \n" +
        "        // 为每行生成HTML\n" +
        "        for (let i = 0; i < lines.length; i++) {\n" +
        "          const lineNumber = i + 1;\n" +
        "          const lineContent = escapeHtml(lines[i]);\n" +
        "          \n" +
        "          // 获取行的执行次数\n" +
        "          const lineCount = lineData[lineNumber] || 0;\n" +
        "          \n" +
        "          // 确定行的样式类\n" +
        "          let lineClass = 'uncovered-line';\n" +
        "          if (lineCount > 0) {\n" +
        "            lineClass = 'covered-line';\n" +
        "          }\n" +
        "          \n" +
        "          const lineDiv = document.createElement('div');\n" +
        "          lineDiv.className = lineClass;\n" +
        "          lineDiv.innerHTML = \n" +
        "            '<span class=\"line-number\">' + lineNumber + '</span>' +\n" +
        "            '<span class=\"line-count\">' + lineCount + '</span>' +\n" +
        "            '<span class=\"line-content\">' + lineContent + '</span>';\n" +
        "          \n" +
        "          lineCoverage.appendChild(lineDiv);\n" +
        "        }\n" +
        "        \n" +
        "        fileDetails.appendChild(lineCoverage);\n" +
        "        container.appendChild(fileDetails);\n" +
        "      }\n" +
        "      \n" +
        "      function escapeHtml(text) {\n" +
        "        return text\n" +
        "          .replace(/&/g, '&amp;')\n" +
        "          .replace(/</g, '&lt;')\n" +
        "          .replace(/>/g, '&gt;')\n" +
        "          .replace(/\"/g, '&quot;')\n" +
        "          .replace(/'/g, '&#39;');\n" +
        "      }\n" +
        "    </script>\n" +
        "  </body>\n" +
        "</html>\n"
    
    // 组合所有部分
    html_header + file_rows + html_footer
}

// 生成单个文件的详细覆盖率报告
pub fn generate_file_detail_report(view: FileCoverageView, coverage_data: CoverageData) -> String {
    let file_percentage = match get_file_coverage(coverage_data, view.filename) {
        Some(percentage) => percentage
        None => 0.0
    }
    
    let percent_str = format_percentage(file_percentage)
    
    // 构建 HTML 头部
    let html_header = 
        "<!DOCTYPE html>\n" +
        "<html lang=\"en\">\n" +
        "  <head>\n" +
        "    <meta charset=\"utf-8\"/>\n" +
        "    <title>" + view.filename + " - Coverage Report</title>\n" +
        "    <style>\n" +
        "      body { font-family: sans-serif; margin: 0; padding: 0; line-height: 1.6; background-color: #f8f8f8; }\n" +
        "      #header { text-align: center; margin-bottom: 20px; padding: 20px; background-color: white; border-bottom: 1px solid #ddd; }\n" +
        "      h1 { margin: 0; color: #333; }\n" +
        "      h2 { margin: 10px 0 0 0; font-size: 24px; color: #4CAF50; }\n" +
        "      .back-link { display: inline-block; margin: 10px 20px; padding: 5px 10px; background-color: #f0f0f0; border: 1px solid #ddd; border-radius: 3px; text-decoration: none; color: #333; }\n" +
        "      .back-link:hover { background-color: #e0e0e0; }\n" +
        "      .file-details { background-color: white; margin: 0 auto; max-width: 1200px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); padding: 20px; }\n" +
        "      .file-header { margin-bottom: 15px; padding-bottom: 10px; border-bottom: 1px solid #eee; }\n" +
        "      .line-coverage { font-family: monospace; font-size: 14px; line-height: 1.4; }\n" +
        "      .line-number { display: inline-block; width: 40px; text-align: right; margin-right: 10px; color: #999; user-select: none; }\n" +
        "      .line-count { display: inline-block; width: 40px; text-align: right; margin-right: 10px; color: #4CAF50; font-weight: bold; user-select: none; }\n" +
        "      .line-content { white-space: pre-wrap; }\n" +
        "      .covered-line { background-color: #e8f5e9; }\n" +
        "      .uncovered-line { background-color: #ffebee; }\n" +
        "      .partial-line { background-color: #fff8e1; }\n" +
        "    </style>\n" +
        "  </head>\n" +
        "  <body>\n" +
        "    <a href=\"index.html\" class=\"back-link\">← Back to file list</a>\n" +
        "    <div class=\"file-details\">\n" +
        "      <div class=\"file-header\">\n" +
        "        <h1>" + view.filename + "</h1>\n" +
        "        <h2>" + percent_str + " covered</h2>\n" +
        "      </div>\n" +
        "      <div class=\"line-coverage\">\n"
    
    // 生成代码行覆盖详情
    let line_coverage = generate_line_coverage(view)
    
    // 构建 HTML 尾部
    let html_footer = 
        "      </div>\n" +
        "    </div>\n" +
        "  </body>\n" +
        "</html>\n"
    
    // 组合所有部分
    html_header + line_coverage + html_footer
}

// 修改生成文件行的函数，使用点位覆盖率
fn generate_file_rows(views: @list.List[FileCoverageView], coverage_data: CoverageData) -> String {
    let mut rows = ""
    
    let mut current = views
    while current.length() > 0 {
        match current.head() {
            Some(view) => {
                // 使用点位覆盖率而不是行覆盖率
                let file_percentage = match get_file_coverage(coverage_data, view.filename) {
                    Some(percentage) => percentage
                    None => 0.0
                }
                
                // 格式化百分比
                let percent_str = format_percentage(file_percentage)
                
                // 获取文件的点位覆盖数据
                let file_cov = match coverage_data.files.get(view.filename) {
                    Some(cov) => cov
                    None => {
                        println("警告: 未找到文件的覆盖率数据: " + view.filename)
                        current = current.tail()
                        continue
                    }
                }
                
                let covered_points = file_cov.covered_points
                let total_points = file_cov.total_points
                
                // 拆分文件路径为目录和文件名
                let (dir_part, file_part) = split_path(view.filename)
                
                // 构建文件行
                let row = 
                    "      <div class=\"file-item\">\n" +
                    "        <span class=\"meter\">\n" +
                    "          <span class=\"covered\" style=\"width: " + file_percentage.to_string() + "%;\"></span>\n" +
                    "        </span>\n" +
                    "        <span class=\"percentage\">" + percent_str + "</span>\n" +
                    "        <a href=\"" + generate_safe_filename(view.filename) + "\" class=\"file-link\">\n" +
                    "          <span class=\"dirname\">" + dir_part + "</span>" + file_part + "\n" +
                    "        </a>\n" +
                    "      </div>\n"
                
                rows = rows + row
                current = current.tail()
            }
            None => break
        }
    }
    
    if rows.is_empty() {
        rows = "      <div class=\"file-item\">\n" +
               "        <span class=\"percentage\">0%</span>\n" +
               "        <span>未找到覆盖率数据</span>\n" +
               "      </div>\n"
    }
    
    rows
}

// 生成文件详细覆盖率信息
pub fn generate_file_details(views: @list.List[FileCoverageView]) -> String {
    let mut details = ""
    
    // 遍历视图列表
    let mut current = views
    while current.length() > 0 {
        match current.head() {
            Some(view) => {
                let file_details = 
                    "    <div id=\"file-" + view.filename.replace(old = "/", new = "-").replace(old = "\\", new = "-") + "\" style=\"display: none;\" class=\"line-coverage\">\n" +
                    "      <h3>" + view.filename + "</h3>\n" +
                    "      <div>\n" +
                    generate_line_coverage(view) +
                    "      </div>\n" +
                    "    </div>\n"
                
                details = details + file_details
                current = current.tail()
            }
            None => break
        }
    }
    
    details
}

// 生成行覆盖率详情
fn generate_line_coverage(view: FileCoverageView) -> String {
    let mut lines = ""
    let source_lines = view.source.split("\n").collect()
    
    // 遍历所有行
    for i in 0..<source_lines.length() {
        let line_number = i + 1
        let line_content = source_lines[i].to_string()
        
        // 获取行的执行次数
        let line_count = match view.lines.get(line_number) {
            Some(line_cov) => line_cov.count
            None => 0
        }
        
        // 确定行的样式类
        let line_class = if line_count > 0 { "covered-line" } else { "uncovered-line" }
        
        let line = 
            "        <div class=\"" + line_class + "\">\n" +
            "          <span class=\"line-number\">" + line_number.to_string() + "</span>\n" +
            "          <span class=\"line-count\">" + line_count.to_string() + "</span>\n" +
            "          <span class=\"line-content\">" + escape_html(line_content) + "</span>\n" +
            "        </div>\n"
        
        lines = lines + line
    }
    
    lines
}

// HTML转义函数
pub fn escape_html(text: String) -> String {
    text.replace(old = "&", new = "&amp;")
        .replace(old = "<", new = "&lt;")
        .replace(old = ">", new = "&gt;")
        .replace(old = "\"", new = "&quot;")
        .replace(old = "'", new = "&#39;")
        .replace(old = "`", new = "&#96;")
        .replace(old = "${", new = "\\${")
}

// 拆分路径为目录和文件名
pub fn split_path(path: String) -> (String, String) {
    // 查找最后一个斜杠
    let last_slash = path.rev().find("/")
    match last_slash {
        Some(pos) => {
            let dir_end = path.length() - pos
            let dir_part = path.substring(start = 0, end = dir_end)
            let file_part = path.substring(start = dir_end)
            (dir_part, file_part)
        }
        None => ("", path)
    }
}
// 辅助函数：格式化百分比
fn format_percentage(percentage: Double) -> String {
    if percentage == 100.0 {
        "100%"
    } else {
        // 保留两位小数
        let integer_part = percentage.to_int()
        let decimal_part = ((percentage - integer_part.to_double()) * 100.0).to_int()
        
        // 确保两位小数
        let decimal_str = if decimal_part < 10 {
            "0" + decimal_part.to_string()
        } else {
            decimal_part.to_string()
        }
        
        integer_part.to_string() + "." + decimal_str + "%"
    }
}
// 添加JavaScript函数到HTML尾部
let html_footer: String = 
    "    </div>\n" +
    "    <script>\n" +
    "      function showFileCoverage(filename) {\n" +
    "        // 隐藏所有文件详情\n" +
    "        var allDetails = document.querySelectorAll('.line-coverage');\n" +
    "        for (var i = 0; i < allDetails.length; i++) {\n" +
    "          allDetails[i].style.display = 'none';\n" +
    "        }\n" +
    "        \n" +
    "        // 显示选中的文件详情\n" +
    "        var fileId = 'file-' + filename.replace(/[\\\\/]/g, '-');\n" +
    "        var fileDetail = document.getElementById(fileId);\n" +
    "        if (fileDetail) {\n" +
    "          fileDetail.style.display = 'block';\n" +
    "        }\n" +
    "        \n" +
    "        // 滚动到文件详情\n" +
    "        if (fileDetail) {\n" +
    "          fileDetail.scrollIntoView({ behavior: 'smooth' });\n" +
    "        }\n" +
    "      }\n" +
    "    </script>\n" +
    "  </body>\n" +
    "</html>\n"

// 辅助函数：计算行覆盖率
fn calculate_line_coverage(view: FileCoverageView) -> (Int, Int) {
    let total_lines = view.lines.size()
    if total_lines == 0 {
        return (0, 0)
    }
    
    // 计算覆盖行数（执行次数大于0的行）
    let covered_lines = view.lines.values().fold(init=0, fn(count, line) {
        if line.count > 0 { count + 1 } else { count }
    })
    
    (covered_lines, total_lines)
}


// 修改文件覆盖率计算函数
fn calculate_view_coverage(view: FileCoverageView) -> Double {
    let total_lines = view.lines.size()
    if total_lines == 0 {
        return 0.0
    }
    
    // 计算覆盖行数（执行次数大于0的行）
    let covered_lines = view.lines.values().fold(init=0, fn(count, line) {
        if line.count > 0 { count + 1 } else { count }
    })
    
    // 计算覆盖率百分比
    covered_lines.to_double() * 100.0 / total_lines.to_double()
}

// 修改 generate_html_report 函数以生成主页面
pub fn generate_main_report(views: @list.List[FileCoverageView], coverage_data: CoverageData) -> String {
    let overall_coverage = get_overall_coverage(coverage_data)
    let coverage_str = format_percentage(overall_coverage)
    
    // 构建 HTML 头部
    let html_header = 
        "<!DOCTYPE html>\n" +
        "<html lang=\"en\">\n" +
        "  <head>\n" +
        "    <meta charset=\"utf-8\"/>\n" +
        "    <title>Coverage report</title>\n" +
        "    <meta name=\"description\" content=\"" + coverage_str + " coverage overall\"/>\n" +
        "    <style>\n" +
        "      body { font-family: sans-serif; margin: 0; padding: 0; line-height: 1.6; background-color: #f8f8f8; }\n" +
        "      #header { text-align: center; margin-bottom: 20px; padding: 20px; background-color: white; border-bottom: 1px solid #ddd; }\n" +
        "      h1 { margin: 0; color: #333; }\\n" +
        "      h2 { margin: 10px 0 0 0; font-size: 24px; color: #4CAF50; }\n" +
        "      #files { background-color: white; margin: 0 auto; max-width: 900px; border-radius: 5px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }\n" +
        "      .file-item { display: flex; align-items: center; padding: 10px 15极速px; border-bottom: 1px solid #eee; }\n" +
        "      .meter { display: inline-block; width: 100px; height: 16px; background-color: #f0f0f0; border-radius: 3px; overflow: hidden; margin-right: 15px; }\n" +
        "      .covered { display: block; height: 100%; background-color: #4CAF50; border-radius: 3px; }\n" +
        "      .percentage { display: inline-block; width: 80px; text-align: right; margin-right: 15px; color: #4CAF50; font-weight: bold; }\n" +
        "      .dirname { color: #888; }\n" +
        "      .file-link { color: #0366d6; text-decoration: none; flex: 1; }\n" +
        "      .file-link:hover { text-decoration: underline; }\n" +
        "    </style>\n" +
        "  </head>\n" +
        "  <body>\n" +
        "    <div id=\"header\">\n" +
        "      <h1>Coverage report</h1>\n" +
        "      <h2>" + coverage_str + "</h2>\n" +
        "    </div>\n" +
        "    <div id=\"files\">\n"
    
    // 生成文件行
    let file_rows = generate_file_rows(views, coverage_data)
    
    // 构建 HTML 尾部
    let html_footer = 
        "    </div>\n" +
        "  </body>\n" +
        "</html>\n"
    
    // 组合所有部分
    html_header + file_rows + html_footer
}

// query.mbt
// 查询点位执行次数
pub fn get_point_execution(data: CoverageData, file: String, start: Int, end: Int) -> Option[Int] {
  match data.files.get(file) {
    Some(coverage) => {
      // 使用 find 方法查找匹配的点位
      match coverage.points.find(fn(point: CoveragePoint) {
        point.start_offset == start && point.end_offset == end
      }) {
        Some(point) => Some(point.count)
        None => None
      }
    }
    None => None
  }
}

// 查询文件所有点位
pub fn get_file_points(data: CoverageData, file: String) -> @list.List[CoveragePoint] {
  match data.files.get(file) {
    Some(coverage) => coverage.points
    None => @list.empty()
  }
}

// 查询文件覆盖率百分比
pub fn get_file_coverage(data: CoverageData, file: String) -> Option[Double] {
  match data.files.get(file) {
    Some(f) => {
      if f.total_points == 0 {
        Some(0.0)
      } else {
        Some(f.covered_points.to_double() * 100.0 / f.total_points.to_double())
      }
    }
    None => None
  }
}

// 修改总体覆盖率计算函数
pub fn get_overall_coverage(data: CoverageData) -> Double {
    if data.total_points == 0 {
        0.0
    } else {
        data.covered_points.to_double() * 100.0 / data.total_points.to_double()
    }
}

// 导出CSV
pub fn export_to_csv(data: CoverageData) -> String {
  let mut csv = "File,Start Offset,End Offset,Execution Count\n"
  
  // 使用 each 方法遍历文件
  data.files.each(fn(filename: String, coverage: FileCoverage) {
    // 使用 each 方法遍历点位
    coverage.points.each(fn(point: CoveragePoint) {
      csv = csv + 
        filename + "," + 
        point.start_offset.to_string() + "," + 
        point.end_offset.to_string() + "," + 
        point.count.to_string() + "\n"
    })
  })
  
  csv
}

// parser.mbt
pub fn parse_bisect(input: String) -> Result[CoverageData, String] {
    // 辅助函数：将字符串转换为整数
    fn parse_int(s: String) -> Option[Int] {
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
        
        if valid { Some(num) } else { None }
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
    let tokens = content.split(" ").filter(fn(s) { !s.is_empty() }).map(fn(s) { s.to_string() }).collect()
    println("Tokens: " + tokens.to_string())
    
    let mut index = 0
    let  files = Map::new()
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
                None => 0  // 如果解析失败，使用0
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
                None => return Err("Missing start offset at index " + (i * 2).to_string())
            }
            
            let end_offset = match points.nth(i * 2 + 1) {
                Some(val) => val
                None => return Err("Missing end offset at index " + (i * 2 + 1).to_string())
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
                start_offset: start_offset,
                end_offset: end_offset,
                count: count
            })
        }
        
        // 添加到文件集
        files.set(filename, FileCoverage::{
            filename: filename,
            points: file_points_list,
            total_points: point_count,
            covered_points: file_covered
        })
        
        total_points += point_count
        covered_points += file_covered
    }
    
    // 返回完整覆盖数据
    Ok(CoverageData::{
        files: files,
        total_points: total_points,
        covered_points: covered_points
    })
}

// merger.mbt
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

// mapper.mbt
struct LineMapEntry {
  line : Int
  start_offset : Int
  end_offset : Int
}

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
        println("构建行映射表完成，行数: " + line_map.length().to_string())
        
        let lines_map : Map[Int, LineCoverage] = Map::new()
        
        // 初始化行覆盖信息
        line_map.iter().each(fn(entry : LineMapEntry) {
          lines_map.set(entry.line, LineCoverage::{ line: entry.line, count: 0 })
        })
        println("初始化行覆盖信息完成")
        
        // 计算每行的最大执行次数
        coverage.points.iter().each(fn(point : CoveragePoint) {
          line_map.iter().each(fn(entry : LineMapEntry) {
            // 修复1: 检查点位是否在行范围内
            if point.start_offset >= entry.start_offset && point.start_offset <= entry.end_offset {
              let current = match lines_map.get(entry.line) {
                Some(lc) => lc
                None => LineCoverage::{ line: entry.line, count: 0 }
              }
              
              // 取该行点的最大执行次数
              lines_map.set(entry.line, LineCoverage::{
                line: entry.line,
                count: if point.count > current.count { point.count } else { current.count },
              })
            }
          })
        })
        println("计算行覆盖率完成")
        
        // 添加到视图列表
        views = @list.add(views, FileCoverageView::{
          filename: filename,
          source: source,
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

// coverage_data.mbt
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