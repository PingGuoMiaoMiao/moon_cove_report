# 📊 moon_cove_report: MoonBit 覆盖率报告生成工具

[English](https://github.com/PingGuoMiaoMiao/moon_cove_report/blob/main/README.md) |[简体中文](https://github.com/PingGuoMiaoMiao/moon_cove_report/blob/main/README_zh_CN.md)

[![Build Status](https://img.shields.io/github/actions/workflow/status/moonbit-community/sw-socket/check.yaml)](https://github.com/moonbit-community/sw-socket/actions)
[![License](https://img.shields.io/github/license/moonbit-community/sw-socket)](LICENSE)



🚀 **主要特性**

- 📊 ​​覆盖率可视化​​ - 生成详细的 HTML 覆盖率报告

- 📁 ​​多文件支持​​ - 处理大型项目的覆盖率数据

- 🔍 ​​智能路径解析​​ - 自动匹配源文件路径

- 📝 ​​详细报告​​ - 提供文件级和行级覆盖率详情


## 📥 安装
# 克隆项目

```bash
git clone https://github.com/yourusername/coverage-reporter.git
cd coverage-reporter
```

# 安装依赖
```bash
moon install
```

## 🏃 快速开始
# 生成覆盖率报告
```bash
moon run main coverage.lcov src/ reports/
```

## ⚙️ 参数说明
| 参数          | 说明                 | 示例值        |
|---------------|----------------------|--------------|
| coverage_path | Bisect 覆盖率文件路径 | coverage.lcov |
| source_dir    | 源代码目录           | src/         |
| output_dir    | 报告输出目录         | reports/     |

## 🔍 查看报告
# 报告生成后，打开输出目录中的 index.html文件：

# macOS
```
open reports/index.html
```

# Windows
```
start reports/index.html
```

# Linux
```
xdg-open reports/index.html
```

## 🛠️ 高级用法
# 合并多个覆盖率文件
```bash
moon run merge file1.lcov file2.lcov merged.lcov
```

# 导出为CSV格式
```
moon run export coverage.lcov coverage.csv
```

# 查看帮助
```
moon run main --help
```

## ⚠️ 常见问题
# 问题：源文件找不到
​​解决：​​ 尝试以下方法：

# 1. 使用相对路径
```bash
moon run main coverage.lcov . reports/
```

# 2. 确保源文件存在
```bash
ls -la src/
```

# 3. 检查覆盖率文件中的路径
```
cat coverage.lcov | grep "SF:"
```
问题：权限错误
​​解决：​​

# 确保有输出目录的写入权限
```bash
sudo chmod -R 777 reports/
```
问题：覆盖率数据解析失败
​​解决：​​ 检查覆盖率文件格式是否为 Bisect v4 格式

## 📊 报告示例

# 主报告页面显示总体覆盖率和文件列表


# 文件详情页面显示代码行覆盖情况

📞 技术支持
遇到问题请联系：

•
GitHub Issues: https://github.com/PingGuoMiaoMiao/coverage-reporter/issues

•
邮箱: 3226742838@qq.com

💡 提示：使用 --verbose参数查看详细日志：
```bash
moon run main coverage.lcov src/ reports/ --verbose
```
📜 许可证
本项目采用 Apache-2.0 许可证。详情请参阅 LICENSE。

👋 如果您喜欢这个项目，请给它一个 ⭐！祝编码愉快！🚀