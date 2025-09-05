///|
pub fn join_path(path1 : String, path2 : String) -> String {
  // 处理空路径
  if path1.is_empty() {
    return path2
  }
  if path2.is_empty() {
    return path1
  }

  // 标准化路径分隔符
  let p1 = path1.replace(old="\\", new="/")
  let p2 = path2.replace(old="\\", new="/")

  // 移除 path1 末尾的分隔符
  let p1_clean = match p1.strip_suffix("/") {
    Some(stripped) => stripped.to_string()
    None => p1
  }

  // 移除 path2 开头的分隔符
  let p2_clean = match p2.starts_with("/") {
    Some(_) => p2.substring(start=1)
    None => p2
  }

  // 使用统一的分隔符拼接路径
  p1_clean + "/" + p2_clean
}

///|
pub fn dirname(path : String) -> String {
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

///|
fn basename(path : String) -> String {
  match path.rev().find("/") {
    Some(pos) => path.substring(start=path.length() - pos)
    None =>
      match path.rev().find("\\") {
        Some(pos) => path.substring(start=path.length() - pos)
        None => path
      }
  }
}

// 拆分路径为目录和文件名

///|
pub fn split_path(path : String) -> (String, String) {
  // 查找最后一个斜杠
  let last_slash = path.rev().find("/")
  match last_slash {
    Some(pos) => {
      let dir_end = path.length() - pos
      let dir_part = path.substring(start=0, end=dir_end)
      let file_part = path.substring(start=dir_end)
      (dir_part, file_part)
    }
    None => ("", path)
  }
}

///|
pub fn ensure_output_dir_exists(output_path : String) -> Result[Unit, String] {
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

///|
pub fn save_report(
  report_html : String,
  output_path : String,
) -> Result[Unit, String] {
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

// HTML转义函数

///|
pub fn escape_html(text : String) -> String {
  text
  .replace(old="&", new="&amp;")
  .replace(old="<", new="&lt;")
  .replace(old=">", new="&gt;")
  .replace(old="\"", new="&quot;")
  .replace(old="'", new="&#39;")
  .replace(old="`", new="&#96;")
  .replace(old="${", new="\\${")
}

// 辅助函数：格式化百分比

///|
fn format_percentage(percentage : Double) -> String {
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
// 生成安全文件名的函数

///|
pub fn generate_safe_filename(filename : String) -> String {
  // 替换所有可能引起路径问题的字符
  filename
  .replace(old="/", new="_")
  .replace(old="\\", new="_")
  .replace(old=":", new="_")
  .replace(old="*", new="_")
  .replace(old="?", new="_")
  .replace(old="\"", new="_")
  .replace(old="<", new="_")
  .replace(old=">", new="_")
  .replace(old="|", new="_")
  .replace(old=".", new="_") +
  ".html"
}

// 辅助函数：在目录中递归查找文件

///|
fn find_file_in_directory(dir_path : String, filename : String) -> String? {
  try {
    let entries = @fs.read_dir(dir_path)
    for entry in entries {
      if @fs.is_dir(entry) {
        match find_file_in_directory(entry, filename) {
          Some(path) => return Some(path)
          None => ignore(())
        }
      } else if basename(entry) == filename {
        return Some(entry)
      }
    }
    None
  } catch {
    IOError(_) => None
  }
}
