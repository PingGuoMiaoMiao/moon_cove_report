# 📊 moon_cove_report: MoonBit Coverage report generation tool

[English](https://github.com/PingGuoMiaoMiao/moon_cove_report/blob/main/README.md) |[简体中文](https://github.com/PingGuoMiaoMiao/moon_cove_report/blob/main/README_zh_CN.md)

[![Build Status](https://img.shields.io/github/actions/workflow/status//PingGuoMiaoMiao/moon_cove_report/check.yaml)](https://github.com//PingGuoMiaoMiao/moon_cove_report/actions)
[![License](https://img.shields.io/github/license//PingGuoMiaoMiao/moon_cove_report)](LICENSE)



🚀 **Main features**

- 📊 ​​Coverage Visualization​​ - Generates detailed HTML coverage reports

- 📁 ​​Multi-file support​​ - handle coverage data for large projects

- 🔍 ​​Smart path resolution​​ - automatically matching source file paths

- 📝 ​​Detailed Reporting​​ - Provides file-level and line-level coverage details


## 📥 Install
# Clone project

```bash
git clone https://github.com/yourusername/coverage-reporter.git
cd coverage-reporter
```

# Install dependencies
```bash
moon install
```

## 🏃quick start
# Generate coverage report
```bash
moon run main coverage.lcov src/ reports/
```

## ⚙️ Parameter description
| parameter          | illustrate                 | Example value        |
|---------------|----------------------|--------------|
| coverage_path | Bisect Coverage file path | coverage.lcov |
| source_dir    | Source code directory           | src/         |
| output_dir    | Report output directory         | reports/     |

reports/

## 🔍 View report
# After the report is generated, open the index.html file in the output directory：

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

## 🛠️ Advanced usage
# Merge multiple coverage files
```bash
moon run merge file1.lcov file2.lcov merged.lcov
```

# Export to CSV format
```
moon run export coverage.lcov coverage.csv
```

# View help
```
moon run main --help
```

## ⚠️ FAQ
# Problem: Source file not found
Solution: Try the following:

# 1. Use relative paths
```bash
moon run main coverage.lcov . reports/
```

# 2. Make sure the source file exists
```bash
ls -la src/
```

# 3. Check the paths in the coverage file
```
cat coverage.lcov | grep "SF:"
```
Problem: Permission Error
Solved：​​

# Make sure you have write permissions to the output directory
```bash
sudo chmod -R 777 reports/
```
Problem: Coverage data parsing failed
Solution: Check if the coverage file format is Bisect v4

## 📊 Report Example

# The main report page shows the overall coverage and file list


# File details page displays code line coverage

📞 Technical support
If you have any questions, please contact:

•
GitHub Issues: https://github.com/PingGuoMiaoMiao/coverage-reporter/issues

•
Mail: 3226742838@qq.com

💡 Tip: Use the --verbose parameter to view detailed logs:
```bash
moon run main coverage.lcov src/ reports/ --verbose
```
📜 license
This project is licensed under the Apache 2.0 License. See LICENSE for details.

👋 If you like this project, please give it a ⭐! Happy coding! 🚀