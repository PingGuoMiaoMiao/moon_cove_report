pub fn generate_html_report(views: @list.List[FileCoverageView], overall_coverage: Double) -> String {
  // 辅助函数：替换字符串中的点
  fn replace_dot(s: String) -> String {
    let parts = s.split(".")
    let string_parts = parts.map(fn(v) { v.to_string() })
    string_parts.join("_")
  }

  // 使用 StringBuilder 提高性能
  let html = StringBuilder::new()
  
  // HTML 头部 - 使用多个 write_object 调用避免长字符串
  html.write_object("<!DOCTYPE html>")
  html.write_object("<html>")
  html.write_object("<head>")
  html.write_object("  <title>Coverage Report</title>")
  html.write_object("  <style>")
  html.write_object("    .covered { background-color: #dfd; }")
  html.write_object("    .uncovered { background-color: #fdd; }")
  html.write_object("    .line { font-family: monospace; white-space: pre; }")
  html.write_object("    .line-number { display: inline-block; width: 40px; text-align: right; padding-right: 10px; color: #666; }")
  html.write_object("    .coverage-badge { display: inline-block; width: 30px; text-align: center; }")
  html.write_object("    .file-content { display: none; }")
  html.write_object("  </style>")
  html.write_object("</head>")
  html.write_object("<body>")
  html.write_object("  <h1>Coverage Report: ")
  html.write_object(overall_coverage.to_string())
  html.write_object("%</h1>")
  html.write_object("  <div class=\"file-list\">")
  html.write_object("    <ul>")
  
  // 生成文件列表
  @list.each(views, fn(view: FileCoverageView) {
    let coverage = calculate_view_coverage(view)
    let file_id = replace_dot(view.filename) // 使用辅助函数
    
    html.write_object("      <li><a href=\"#")
    html.write_object(file_id)
    html.write_object("\" onclick=\"showFile('")
    html.write_object(view.filename)
    html.write_object("')\">")
    html.write_object(view.filename)
    html.write_object(" - ")
    html.write_object(coverage.to_string())
    html.write_object("%</a></li>")
  })
  
  html.write_object("    </ul>")
  html.write_object("  </div>")
  html.write_object("  <div class=\"file-contents\">")
  
  // 生成文件内容
  @list.each(views, fn(view: FileCoverageView) {
    let file_id = replace_dot(view.filename) // 使用辅助函数
    
    html.write_object("    <div id=\"")
    html.write_object(file_id)
    html.write_object("\" class=\"file-content\">")
    html.write_object("      <h2>")
    html.write_object(view.filename)
    html.write_object("</h2>")
    html.write_object("      <pre>")
    
    // 处理源代码行
    let lines = @list.from_iter(view.source.split("\n"))
    for i in 0..=lines.length() {
      let line_no = i + 1
      let count = match view.lines.get(line_no) {
        Some(l) => l.count
        None => 0
      }
      let class = if count > 0 { "covered" } else { "uncovered" }
      let badge = if count > 0 { count.to_string() } else { "" }
      
      html.write_object("        <div class=\"line ")
      html.write_object(class)
      html.write_object("\" data-line=\"")
      html.write_object(line_no.to_string())
      html.write_object("\">")
      html.write_object("          <span class=\"line-number\">")
      html.write_object(line_no.to_string())
      html.write_object("</span>")
      html.write_object("          <span class=\"coverage-badge\">")
      html.write_object(badge)
      html.write_object("</span>")
      html.write_object("          <span class=\"source\">")
      html.write_object("</span>")
      html.write_object("        </div>")
    }
    
    html.write_object("      </pre>")
    html.write_object("    </div>")
  })
  
  html.write_object("  </div>")
  html.write_object("  <script>")
  html.write_object("    function showFile(filename) {")
  html.write_object("      document.querySelectorAll('.file-content').forEach(function(el) {")
  html.write_object("        el.style.display = 'none';")
  html.write_object("      });")
  html.write_object("      document.getElementById(filename.replace('.', '_')).style.display = 'block';")
  html.write_object("    }")
  html.write_object("  </script>")
  html.write_object("</body>")
  html.write_object("</html>")
  
  // 返回生成的 HTML
  html.to_string()
}

fn calculate_view_coverage(view: FileCoverageView) -> Double {
  let total_lines = view.lines.size()
  if total_lines == 0 { 
    return 0.0 
  }
  
  let covered_lines = view.lines.values().fold(init=0, fn(count, line) {
    if line.count > 0 { count + 1 } else { count }
  })
  
  covered_lines.to_double() * 100.0 / total_lines.to_double()
}
