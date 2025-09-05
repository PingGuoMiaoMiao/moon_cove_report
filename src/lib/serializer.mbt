// serializer.mbt

///|
pub fn serialize_bisect(data : CoverageData) -> String {
  let buffer = StringBuilder::new()

  // 文件头
  buffer.write_object("BISECT-COVERAGE-4")

  // 文件数量
  buffer.write_object(" ")
  buffer.write_object(data.files.size().to_string())

  // 遍历每个文件
  data.files.each(fn(filename : String, coverage : FileCoverage) {
    // 文件名长度
    buffer.write_object(" ")
    buffer.write_object(filename.length().to_string())

    // 文件名
    buffer.write_object(" ")
    buffer.write_object(filename)

    // 点位数据（每两个元素表示一个点位）
    let mut points_arr = @list.empty()
    coverage.points.each(fn(point : CoveragePoint) {
      points_arr = @list.add(points_arr, point.start_offset)
      points_arr = @list.add(points_arr, point.end_offset)
    })

    // 点位数组长度
    buffer.write_object(" ")
    buffer.write_object(points_arr.length().to_string())

    // 点位数组内容
    points_arr.each(fn(point : Int) {
      buffer.write_object(" ")
      buffer.write_object(point.to_string())
    })

    // 执行次数数组
    let mut counts_arr = @list.empty()
    coverage.points.each(fn(point : CoveragePoint) {
      counts_arr = @list.add(counts_arr, point.count)
    })

    // 执行次数数组长度
    buffer.write_object(" ")
    buffer.write_object(counts_arr.length().to_string())

    // 执行次数内容
    counts_arr.each(fn(count : Int) {
      buffer.write_object(" ")
      buffer.write_object(count.to_string())
    })
  })

  // 返回生成的字符串
  buffer.to_string()
}
