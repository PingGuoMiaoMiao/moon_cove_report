///|
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
  match @cove.ensure_output_dir_exists(output_dir) {
    Ok(_) => ignore(Ok(_))
    Err(msg) => {
      println("❌ Error creating output directory: " + msg)
      @sys.exit(1)
    }
  }

  // 读取覆盖率文件
  let mut coverage_data = @cove.CoverageData::{
    files: Map::new(),
    total_points: 0,
    covered_points: 0,
  }
  match @cove.read_coverage_file(coverage_path) {
    Err(msg) => {
      println("❌ Error reading coverage file: " + msg)
      @sys.exit(1)
    }
    Ok(data) => {
      println(
        "✅ Successfully read coverage data for " +
        data.files.size().to_string() +
        " files",
      )
      coverage_data = data
    }
  }

  // 加载源代码文件 - 使用改进的函数
  println("🔄 加载源代码文件...")
  let source_files = @cove.load_source_files(coverage_data, source_dir)
  println("✅ 加载 " + source_files.size().to_string() + " 个源文件")

  // 如果加载的源文件数量少于覆盖率文件数量，尝试备用方法
  if source_files.size() < coverage_data.files.size() {
    println("⚠️ 警告: 部分源文件未找到，尝试备用方法...")

    // 尝试使用相对路径
    let relative_source_dir = "src" // 或者从覆盖率数据中推断
    let alt_source_files = @cove.load_source_files(
      coverage_data, relative_source_dir,
    )

    // 合并找到的源文件
    alt_source_files.each(fn(filename : String, content : String) {
      if !source_files.contains(filename) {
        source_files.set(filename, content)
        println("✅ 备用方法找到文件: " + filename)
      }
    })
    println(
      "🔄 最终加载 " + source_files.size().to_string() + " 个源文件",
    )
  }

  // 生成行视图
  let views = @cove.map_to_line_view(coverage_data, source_files)
  println(
    "✅ Created coverage views for " + views.length().to_string() + " files",
  )

  // 计算总体覆盖率
  let overall_coverage = @cove.get_overall_coverage(coverage_data)
  println("📊 Overall coverage: " + overall_coverage.to_string() + "%")

  // 生成主HTML报告
  let main_report_html = @cove.generate_main_report(views, coverage_data)
  println("🖥️ Generated main HTML report")

  // 保存主报告
  let main_report_path = @cove.join_path(output_dir, "index.html")
  match @cove.save_report(main_report_html, main_report_path) {
    Err(msg) => {
      println("❌ Error saving main report: " + msg)
      @sys.exit(1)
    }
    Ok(_) =>
      println("✅ Main report successfully saved to: " + main_report_path)
  }

  // 为每个文件生成详细报告
  let mut current_view = views
  while current_view.length() > 0 {
    match current_view.head() {
      Some(view) => {
        let detail_report_html = @cove.generate_file_detail_report(
          view, coverage_data,
        )

        // 生成安全的文件名
        let safe_filename = @cove.generate_safe_filename(view.filename)
        let detail_report_path = @cove.join_path(output_dir, safe_filename)
        match @cove.save_report(detail_report_html, detail_report_path) {
          Err(msg) =>
            println(
              "❌ Error saving detail report for " + view.filename + ": " + msg,
            )
          Ok(_) =>
            println(
              "✅ Detail report successfully saved to: " + detail_report_path,
            )
        }
        current_view = current_view.tail()
      }
      None => break
    }
  }
  println("🎉 Coverage report generation complete!")
  @sys.exit(0)
}
