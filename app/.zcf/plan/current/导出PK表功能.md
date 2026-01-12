# 任务执行计划

## 任务信息
- **任务名称：** 在考试详情增加【导出PK表】功能
- **创建时间：** 2026-01-10 18:15:58
- **完成时间：** 2026-01-10 18:20:30
- **状态：** ✅ 已完成

## 执行摘要

### 已完成的修改

**新增文件：**
1. `lib/services/pk_table_exporter.dart` - PK表导出工具类

**修改文件：**
1. `lib/screens/exam/exam_group_table_screen.dart` - 添加导出按钮和逻辑

### 功能实现

**PKTableExporter 核心功能：**
1. 生成包含28列的完整PK表（A组、B组 + 5天×5科 + 合计）
2. 实现单元格合并（分组、周一至周五标题）
3. 按排名两两配对学生（1vs2, 3vs4...）
4. 自动保存到Download目录
5. 支持自定义文件名（考试名称_PK排班表_时间戳.xlsx）

**ExamGroupTableScreen 集成：**
1. AppBar添加导出图标按钮
2. 导出时显示加载状态
3. 生成后自动弹出分享菜单
4. 完整的错误处理和提示

### 验证结果
- ✅ 代码语法验证通过 (flutter analyze)
- ✅ 无警告或错误

## 需求描述
在考试详情页面增加【导出PK表】功能：
1. 点击后根据当前考试组的排名情况生成PK表
2. 第1名和第2名PK，第3名和第4名PK，以此类推
3. Excel格式参考708班级pk.xlsx（包含周一到周五，每天5科：语数英科社）
4. 需要合并单元格（如"分组"列、"周一"到"周五"标题）
5. 生成后自动弹出分享菜单

## 上下文信息
- **技术栈：** Flutter 3.9.2, excel 4.0.3, share_plus 7.2.1
- **项目路径：** D:\myspace\teacher_tools\app
- **参考文件：** 708班级pk.xlsx
- **参考实现：** lib/services/batch_comment_exporter.dart

## PK表格式结构

```
表头行（第1行）：
┌───────┬───────┬──────┬──────┬──────┬──────┬──────┬──────┬─────┐
│ 分组  │       │ 周一 │      │      │      │      │ 周二 │ ... │ 合计│
│ (合并)│ (合并)│ (5列合并为一组)      │      │      │      │      │
└───────┴───────┴──────┴──────┴──────┴──────┴──────┴──────┴─────┘

科目行（第2行）：
┌───────┬───────┬──────┬──────┬──────┬──────┬──────┬──────┬─────┐
│  A组  │  B组  │ 语  │ 数  │ 英  │ 科  │ 社  │ 语  │ ... │      │
└───────┴───────┴──────┴──────┴──────┴──────┴──────┴──────┴─────┘

数据行（第3行起）：
┌───────┬───────┬──────┬──────┬──────┬──────┬──────┬──────┬─────┐
│ 方予  │ 章安妮│      │      │      │      │      │      │ ... │      │
│ (1名) │ (2名) │  (成绩区域留空，手动填写)                     │      │
└───────┴───────┴──────┴──────┴──────┴──────┴──────┴──────┴─────┘
```

## 执行步骤

### 步骤 1：创建 PK 表导出工具类
**文件：** `lib/services/pk_table_exporter.dart`

**操作：**
- 创建 `PKTableExporter` 类
- 实现 `exportToExcel()` 方法
- 生成包含合并单元格的完整PK表
- 参考 `BatchCommentExporter` 的结构

**预期结果：** 独立的PK表生成工具

### 步骤 2：添加导出按钮
**文件：** `lib/screens/exam/exam_group_table_screen.dart`

**操作：**
- 在 AppBar actions 中添加导出图标按钮
- 绑定 `_exportPKTable()` 方法

**预期结果：** 用户可以点击按钮导出PK表

### 步骤 3：实现导出逻辑
**文件：** `lib/screens/exam/exam_group_table_screen.dart`

**操作：**
- 创建 `_exportPKTable()` 异步方法
- 从 `_rows` 获取已排序的学生列表
- 调用 `PKTableExporter.exportToExcel()`
- 使用 `Share.shareXFiles()` 分享文件
- 添加加载状态和错误处理

**预期结果：** 点击后生成并分享PK表

### 步骤 4：实现合并单元格逻辑
**文件：** `lib/services/pk_table_exporter.dart`

**关键代码：**
```dart
// 合并第1行的标题单元格
sheet.merge(CellIndex.indexByString('A1'), CellIndex.indexByString('B1'));  // 分组
sheet.merge(CellIndex.indexByString('C1'), CellIndex.indexByString('G1'));  // 周一(5列)
sheet.merge(CellIndex.indexByString('H1'), CellIndex.indexByString('L1'));  // 周二
// ... 其他天
sheet.merge(CellIndex.indexByString('AC1'), CellIndex.indexByString('AD1')); // 合计
```

**预期结果：** 正确的单元格合并效果

### 步骤 5：样式美化
**文件：** `lib/services/pk_table_exporter.dart`

**操作：**
- 设置表头样式（加粗、居中）
- 设置分组单元格样式（背景色）
- 设置边框

**预期结果：** 与708班级pk.xlsx样式一致

## 完成标准
- [x] 导出按钮显示在考试表格页面
- [x] 点击后生成包含完整结构的PK表Excel
- [x] 正确合并单元格（分组、周一至周五标题）
- [x] 按排名正确配对学生（1vs2, 3vs4...）
- [x] 自动弹出分享菜单
- [x] 代码符合现有风格和SOLID原则

## SOLID 原则应用
- **S（单一职责）：** PKTableExporter 专注于PK表生成
- **O（开闭原则）：** 可扩展样式配置，无需修改核心逻辑
- **D（依赖倒置）：** 依赖抽象（Student、ExamGroup模型）
