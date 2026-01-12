# 教师工具 (Teacher Tools)

一款专为教师设计的移动应用和数据分析工具集，帮助教师高效管理学生信息、分析成绩数据。

## 功能特性

- **学生信息管理**: 记录和跟踪学生基本信息
- **成绩分析**: 自动分析学生成绩数据，生成可视化报告
- **班级PK**: 班级间成绩对比分析功能
- **数据导入**: 支持Excel格式数据导入

## 项目结构

```
teacher_tools/
├── app/          # Flutter移动应用
├── zlfx/         # 成绩分析工具(Python)
└── docs/         # 项目文档
```

## 安装说明

### 移动应用

1. 确保已安装 [Flutter SDK](https://flutter.dev/docs/get-started/install) (3.9.2或更高版本)
2. 进入app目录: `cd app`
3. 获取依赖: `flutter pub get`
4. 运行应用: `flutter run`

### 成绩分析工具

1. 确保已安装 Python 3.7+
2. 安装依赖: `pip install pandas openpyxl`
3. 运行分析脚本: `python zlfx/成绩分析.py`

## 使用方法

1. 准备Excel格式的学生数据文件
2. 使用移动应用导入数据
3. 查看自动生成的分析报告

## 技术栈

- **移动端**: Flutter (Dart)
  - 状态管理: Provider
  - 数据库: SQLite
  - Excel处理: spreadsheet_decoder

- **数据分析**: Python
  - 数据处理: pandas
  - Excel处理: openpyxl

## 贡献

欢迎提交问题和拉取请求！详见 [CONTRIBUTING.md](CONTRIBUTING.md)

## 许可证

本项目采用 MIT 许可证 - 详见 [LICENSE](LICENSE) 文件
