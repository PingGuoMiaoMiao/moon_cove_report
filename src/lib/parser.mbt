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
    println("输入内容: " + input)
    
    let identifier = "BISECT-COVERAGE-4"
    
    // 使用 strip_prefix 获取内容视图
    let content_view = match input.strip_prefix(identifier.view()) {
        Some(view) => {
            println("找到文件头标识符")
            view
        }
        None => {
            println("错误：找不到文件头标识符")
            return Err("Invalid Bisect coverage file format: missing header")
        }
    }
    
    // 转换为 String
    let content_str = content_view.to_string()
    println("内容: " + content_str)
    
    // 手动分割字符串
    let mut tokens = @list.empty()
    let mut current_token = ""
    let mut token_count = 0
    
    println("开始分割字符串...")
    for c in content_str.iter() {
        if c == ' ' || c == '\t' || c == '\n' || c == '\r' {
            if !current_token.is_empty() {
                tokens = @list.add(tokens, current_token)
                current_token = ""
                token_count += 1
            }
        } else {
            current_token = current_token + c.to_string()
        }
    }
    
    // 添加最后一个 token
    if !current_token.is_empty() {
        tokens = @list.add(tokens, current_token)
        token_count += 1
    }
    
    println("分割完成，共 " + token_count.to_string() + " 个 token")
    
    // 打印所有 token 用于调试
    println("所有 token:")
    let mut temp_tokens = tokens
    let mut index = 0
    while temp_tokens.length() > 0 {
        match temp_tokens.head() {
            Some(token) => {
                println("Token[" + index.to_string() + "]: " + token)
                temp_tokens = temp_tokens.tail()
                index += 1
            }
            None => break
        }
    }
    
    // 反转 tokens 列表（因为 add 在头部添加）
    tokens = tokens.rev()
    
    // 文件数量解析
    println("解析文件数量...")
    let file_count = match tokens.head() {
        Some(token) => match parse_int(token) {
            Some(count) => {
                println("文件数量: " + count.to_string())
                count
            }
            None => {
                println("错误：无法解析文件数量: " + token)
                return Err("Failed to parse file count")
            }
        }
        None => {
            println("错误：缺少文件数量")
            return Err("Missing file count")
        }
    }
    let mut tokens = tokens.tail()
    
    let files: Map[String, FileCoverage] = Map::new()
    let mut total_points = 0
    let mut covered_points = 0
    
    println("开始处理 " + file_count.to_string() + " 个文件...")
    
    // 修复1: 使用 0..file_count 而不是 0..=file_count
    for file_index in 0..=file_count {
        println("\n处理文件 #" + (file_index + 1).to_string() + "/" + file_count.to_string())
        
        // 文件名长度解析
        println("解析文件名长度...")
        let name_length = match tokens.head() {
            Some(token) => match parse_int(token) {
                Some(len) => {
                    println("文件名长度: " + len.to_string())
                    len
                }
                None => {
                    println("错误：无法解析文件名长度: " + token)
                    return Err("Failed to parse name length")
                }
            }
            None => {
                println("错误：缺少文件名长度")
                return Err("Missing name length")
            }
        }
        tokens = tokens.tail()
        
        // 文件名解析
        println("解析文件名...")
        let filename = match tokens.head() {
            Some(name) => {
                println("文件名: " + name)
                name
            }
            None => {
                println("错误：缺少文件名")
                return Err("Missing filename")
            }
        }
        tokens = tokens.tail()
        
        // 点位数组长度解析
        println("解析点位数组长度...")
        let points_length = match tokens.head() {
            Some(token) => match parse_int(token) {
                Some(len) => {
                    println("点位数组长度: " + len.to_string())
                    len
                }
                None => {
                    println("错误：无法解析点位数组长度: " + token)
                    return Err("Failed to parse points length")
                }
            }
            None => {
                println("错误：缺少点位数组长度")
                return Err("Missing points length")
            }
        }
        tokens = tokens.tail()
        
        // 检查 points_length 是否为偶数
        if points_length % 2 != 0 {
            println("错误：点位数组长度必须是偶数，但得到 " + points_length.to_string())
            return Err("Points length must be even, but got " + points_length.to_string())
        }
        
        let point_count = points_length / 2
        println("点位数量: " + point_count.to_string())
        
        // 读取点位数组
        println("读取点位数组...")
        let mut points_arr = @list.empty()
        // 修复2: 使用 0..points_length 而不是 0..=points_length
        for i in 0..<points_length {
            let value = match tokens.head() {
                Some(token) => match parse_int(token) {
                    Some(v) => {
                        println("点位值[" + i.to_string() + "]: " + v.to_string())
                        v
                    }
                    None => {
                        println("错误：无法解析点位值: " + token)
                        return Err("Failed to parse point value")
                    }
                }
                None => {
                    println("错误：缺少点位值")
                    return Err("Missing point value")
                }
            }
            points_arr = @list.add(points_arr, value)
            tokens = tokens.tail()
        }
        // 反转点位数组（因为 add 在头部添加）
        points_arr = points_arr.rev()
        println("点位数组长度: " + points_arr.length().to_string())
        
        // 不再读取计数数组长度（直接使用 point_count）
        
        // 读取计数数组
        println("读取计数数组...")
        let mut counts_arr = @list.empty()
        // 修复3: 使用 0..point_count 而不是 0..=point_count
        for i in 0..=point_count {
            let value = match tokens.head() {
                Some(token) => match parse_int(token) {
                    Some(v) => {
                        println("计数值[" + i.to_string() + "]: " + v.to_string())
                        v
                    }
                    None => {
                        println("错误：无法解析计数值: " + token)
                        return Err("Failed to parse count value")
                    }
                }
                None => {
                    println("错误：缺少计数值")
                    return Err("Missing count value")
                }
            }
            counts_arr = @list.add(counts_arr, value)
            tokens = tokens.tail()
        }
        // 反转计数数组（因为 add 在头部添加）
        counts_arr = counts_arr.rev()
        println("计数数组长度: " + counts_arr.length().to_string())
        
        // 构建覆盖点列表
        println("构建覆盖点列表...")
        let mut file_points = @list.empty()
        let mut file_covered = 0
        
        // 修复4: 使用 0..point_count 而不是 0..=point_count
        for i in 0..<point_count {
            let start_index = i * 2
            let end_index = i * 2 + 1
            
            println("\n处理覆盖点 #" + i.to_string())
            println("起始索引: " + start_index.to_string() + ", 结束索引: " + end_index.to_string())
            
            // 获取起始位置
            println("获取起始位置...")
            let start = match points_arr.nth(start_index) {
                Some(value) => {
                    println("起始位置: " + value.to_string())
                    value
                }
                None => {
                    println("错误：缺少起始位置，索引: " + start_index.to_string() + ", 数组长度: " + points_arr.length().to_string())
                    return Err("Missing start offset at index " + start_index.to_string())
                }
            }
            
            // 获取结束位置
            println("获取结束位置...")
            let end = match points_arr.nth(end_index) {
                Some(value) => {
                    println("结束位置: " + value.to_string())
                    value
                }
                None => {
                    println("错误：缺少结束位置，索引: " + end_index.to_string() + ", 数组长度: " + points_arr.length().to_string())
                    return Err("Missing end offset at index " + end_index.to_string())
                }
            }
            
            // 获取计数
            println("获取计数...")
            let count = match counts_arr.nth(i) {
                Some(value) => {
                    println("计数: " + value.to_string())
                    value
                }
                None => {
                    println("错误：缺少计数，索引: " + i.to_string() + ", 数组长度: " + counts_arr.length().to_string())
                    return Err("Missing count at index " + i.to_string())
                }
            }
            
            if count > 0 {
                file_covered += 1
                println("计数 > 0，增加覆盖点")
            }
            
            file_points = @list.add(file_points, CoveragePoint::{
                start_offset: start, 
                end_offset: end, 
                count: count
            })
        }
        
        // 反转覆盖点列表（因为 add 在头部添加）
        file_points = file_points.rev()
        println("覆盖点列表长度: " + file_points.length().to_string())
        
        // 修复5: 正确更新 Map
        println("添加到文件集...")
        let files = files.set(filename, FileCoverage::{
            filename: filename, 
            points: file_points,
            total_points: point_count,
            covered_points: file_covered
        })
        
        total_points += point_count
        covered_points += file_covered
        
        println("文件处理完成，总点数: " + total_points.to_string() + ", 覆盖点数: " + covered_points.to_string())
    }
    
    println("\n所有文件处理完成")
    println("总点数: " + total_points.to_string())
    println("覆盖点数: " + covered_points.to_string())
    
    // 返回完整覆盖数据
    Ok(CoverageData::{
        files: files,
        total_points: total_points,
        covered_points: covered_points
    })
}