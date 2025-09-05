// 修改 generate_html_report 函数以生成完整的覆盖率报告

///|
pub fn generate_html_report(
  views : @list.List[FileCoverageView],
  coverage_data : CoverageData,
) -> String {
  let overall_coverage = get_overall_coverage(coverage_data)
  let coverage_str = format_percentage(overall_coverage)

  // 构建 HTML 头部
  let html_header = "<!DOCTYPE html>\n" +
    "<html lang=\"en\">\n" +
    "  <head>\n" +
    "    <meta charset=\"utf-8\"/>\n" +
    "    <title>Coverage report</title>\n" +
    "    <meta name=\"description\" content=\"" +
    coverage_str +
    " coverage overall\"/>\n" +
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
    "      <h2>" +
    coverage_str +
    "</h2>\n" +
    "    </div>\n" +
    "    <div id=\"files\">\n"

  // 生成文件行
  let file_rows = generate_file_rows(views, coverage_data)

  // 构建 HTML 尾部
  let html_footer = "    </div>\n" +
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

///|
pub fn generate_file_detail_report(
  view : FileCoverageView,
  coverage_data : CoverageData,
) -> String {
  let file_percentage = match get_file_coverage(coverage_data, view.filename) {
    Some(percentage) => percentage
    None => 0.0
  }
  let percent_str = format_percentage(file_percentage)

  // 构建 HTML 头部
  let html_header = "<!DOCTYPE html>\n" +
    "<html lang=\"en\">\n" +
    "  <head>\n" +
    "    <meta charset=\"utf-8\"/>\n" +
    "    <title>" +
    view.filename +
    " - Coverage Report</title>\n" +
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
    "        <h1>" +
    view.filename +
    "</h1>\n" +
    "        <h2>" +
    percent_str +
    " covered</h2>\n" +
    "      </div>\n" +
    "      <div class=\"line-coverage\">\n"

  // 生成代码行覆盖详情
  let line_coverage = generate_line_coverage(view)

  // 构建 HTML 尾部
  let html_footer = "      </div>\n" +
    "    </div>\n" +
    "  </body>\n" +
    "</html>\n"

  // 组合所有部分
  html_header + line_coverage + html_footer
}

// 修改 generate_html_report 函数以生成主页面

///|
pub fn generate_main_report(
  views : @list.List[FileCoverageView],
  coverage_data : CoverageData,
) -> String {
  let overall_coverage = get_overall_coverage(coverage_data)
  let coverage_str = format_percentage(overall_coverage)

  // 构建 HTML 头部
  let html_header = "<!DOCTYPE html>\n" +
    "<html lang=\"en\">\n" +
    "  <head>\n" +
    "    <meta charset=\"utf-8\"/>\n" +
    "    <title>Coverage report</title>\n" +
    "    <meta name=\"description\" content=\"" +
    coverage_str +
    " coverage overall\"/>\n" +
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
    "      <h2>" +
    coverage_str +
    "</h2>\n" +
    "    </div>\n" +
    "    <div id=\"files\">\n"

  // 生成文件行
  let file_rows = generate_file_rows(views, coverage_data)

  // 构建 HTML 尾部
  let html_footer = "    </div>\n" + "  </body>\n" + "</html>\n"

  // 组合所有部分
  html_header + file_rows + html_footer
}

// 修改生成文件行的函数，使用点位覆盖率

///|
fn generate_file_rows(
  views : @list.List[FileCoverageView],
  coverage_data : CoverageData,
) -> String {
  let mut rows = ""
  let mut current = views
  while current.length() > 0 {
    match current.head() {
      Some(view) => {
        // 使用点位覆盖率而不是行覆盖率
        let file_percentage = match
          get_file_coverage(coverage_data, view.filename) {
          Some(percentage) => percentage
          None => 0.0
        }

        // 格式化百分比
        let percent_str = format_percentage(file_percentage)

        // 获取文件的点位覆盖数据
        let file_cov = match coverage_data.files.get(view.filename) {
          Some(cov) => cov
          None => {
            println(
              "警告: 未找到文件的覆盖率数据: " + view.filename,
            )
            current = current.tail()
            continue
          }
        }
        let covered_points = file_cov.covered_points
        let total_points = file_cov.total_points

        // 拆分文件路径为目录和文件名
        let (dir_part, file_part) = split_path(view.filename)

        // 构建文件行
        let row = "      <div class=\"file-item\">\n" +
          "        <span class=\"meter\">\n" +
          "          <span class=\"covered\" style=\"width: " +
          file_percentage.to_string() +
          "%;\"></span>\n" +
          "        </span>\n" +
          "        <span class=\"percentage\">" +
          percent_str +
          "</span>\n" +
          "        <a href=\"" +
          generate_safe_filename(view.filename) +
          "\" class=\"file-link\">\n" +
          "          <span class=\"dirname\">" +
          dir_part +
          "</span>" +
          file_part +
          "\n" +
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

// 生成行覆盖率详情

///|
fn generate_line_coverage(view : FileCoverageView) -> String {
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
    let line_class = if line_count > 0 {
      "covered-line"
    } else {
      "uncovered-line"
    }
    let line = "        <div class=\"" +
      line_class +
      "\">\n" +
      "          <span class=\"line-number\">" +
      line_number.to_string() +
      "</span>\n" +
      "          <span class=\"line-count\">" +
      line_count.to_string() +
      "</span>\n" +
      "          <span class=\"line-content\">" +
      escape_html(line_content) +
      "</span>\n" +
      "        </div>\n"
    lines = lines + line
  }
  lines
}
// 辅助函数：计算行覆盖率

///|
fn calculate_line_coverage(view : FileCoverageView) -> (Int, Int) {
  let total_lines = view.lines.size()
  if total_lines == 0 {
    return (0, 0)
  }

  // 计算覆盖行数（执行次数大于0的行）
  let covered_lines = view.lines
    .values()
    .fold(init=0, fn(count, line) {
      if line.count > 0 {
        count + 1
      } else {
        count
      }
    })
  (covered_lines, total_lines)
}
