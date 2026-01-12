import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:intl/intl.dart';

/// PK表导出服务
/// 根据学生排名生成两两PK的Excel排班表
class PKTableExporter {
  /// 导出到Excel
  ///
  /// [examName] - 考试名称（用于文件名）
  /// [rankedStudents] - 按排名排序的学生列表
  ///
  /// 返回文件路径
  static Future<String> exportToExcel(
    String examName,
    List<Student> rankedStudents,
  ) async {
    debugPrint('📊 [PKTableExporter] 开始导出PK表...');
    debugPrint('📊 [PKTableExporter] 学生数量: ${rankedStudents.length}');

    // 1. 创建Excel对象
    final excel = Excel.createExcel();

    // 2. 删除默认Sheet
    excel.delete('Sheet1');

    // 3. 创建Sheet
    final sheet = excel['PK排班表'];

    // 4. 添加表头和数据
    _addTableStructure(sheet, rankedStudents);

    // 5. 应用样式
    _applyStyles(sheet);

    // 6. 保存到文件
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Excel保存失败: bytes为null');
    }

    debugPrint('✅ [PKTableExporter] Excel生成完成，大小: ${bytes.length} bytes');

    // 7. 获取保存路径
    final directory = await _getSaveDirectory();
    final fileName = _generateFileName(examName);
    final filePath = '${directory.path}/$fileName';

    debugPrint('📁 [PKTableExporter] 保存路径: $filePath');

    // 8. 写入文件
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    debugPrint('✅ [PKTableExporter] 文件保存成功!');

    return filePath;
  }

  /// 添加表格结构
  static void _addTableStructure(Sheet sheet, List<Student> rankedStudents) {
    const subjects = ['语', '数', '英', '科', '社'];
    const days = ['周一', '周二', '周三', '周四', '周五'];

    // ===== 第1行：分组和周标题（带合并单元格） =====
    int colIndex = 0;

    // A1-B1: 分组（合并2列）
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 0)).value =
        TextCellValue('分组');
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex + 1, rowIndex: 0)).value =
        TextCellValue('');
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 0),
      CellIndex.indexByColumnRow(columnIndex: colIndex + 1, rowIndex: 0),
    );
    colIndex += 2;

    // C1-G1, H1-L1, ...: 周一至周五（每天5列）
    for (final day in days) {
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 0)).value =
          TextCellValue(day);
      for (int i = 1; i < 5; i++) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex + i, rowIndex: 0)).value =
            TextCellValue('');
      }
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 0),
        CellIndex.indexByColumnRow(columnIndex: colIndex + 4, rowIndex: 0),
      );
      colIndex += 5;
    }

    // AC1: 合计（1列）
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 0)).value =
        TextCellValue('合计');

    // ===== 第2行：A组、B组和科目 =====
    colIndex = 0;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 1)).value =
        TextCellValue('A组');
    colIndex++;
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 1)).value =
        TextCellValue('B组');
    colIndex++;

    // 每天5个科目
    for (int day = 0; day < 5; day++) {
      for (final subject in subjects) {
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 1)).value =
            TextCellValue(subject);
        colIndex++;
      }
    }

    // 合计列
    sheet.cell(CellIndex.indexByColumnRow(columnIndex: colIndex, rowIndex: 1)).value = TextCellValue('');

    // ===== 第3行起：学生配对数据 =====
    int rowIndex = 2;
    for (int i = 0; i < rankedStudents.length; i += 2) {
      final studentA = rankedStudents[i];
      final studentB = (i + 1 < rankedStudents.length)
          ? rankedStudents[i + 1]
          : null; // 处理奇数人数

      // A组学生
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(studentA.name);

      // B组学生
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          studentB != null ? TextCellValue(studentB.name) : TextCellValue('');

      // 其余列留空（手动填写成绩）
      // 不需要显式设置，默认为空

      rowIndex++;
    }

    debugPrint('✅ [PKTableExporter] 表格结构添加完成，共 $rowIndex 行');
  }

  /// 应用样式
  static void _applyStyles(Sheet sheet) {
    // 表头样式
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 14,
    );

    // 第1行标题样式（带背景色）
    for (int col = 0; col < 28; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 0));
      cell.cellStyle = headerStyle;
    }

    // 第2行科目样式
    final subjectStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
      fontSize: 12,
    );

    for (int col = 0; col < 28; col++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: col, rowIndex: 1));
      cell.cellStyle = subjectStyle;
    }

    debugPrint('✅ [PKTableExporter] 样式应用完成');
  }

  /// 生成文件名
  static String _generateFileName(String examName) {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final timestamp = dateFormat.format(now);
    return '${examName}_PK排班表_$timestamp.xlsx';
  }

  /// 获取保存目录
  static Future<Directory> _getSaveDirectory() async {
    // 优先使用Download目录
    try {
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        debugPrint('✅ [PKTableExporter] 使用Download目录: ${directory.path}');
        return directory;
      }
    } catch (e) {
      debugPrint('⚠️ [PKTableExporter] 无法获取Download目录: $e');
    }

    // 退而求其次使用应用文档目录
    try {
      final directory = await getApplicationDocumentsDirectory();
      debugPrint('✅ [PKTableExporter] 使用应用文档目录: ${directory.path}');
      return directory;
    } catch (e) {
      debugPrint('❌ [PKTableExporter] 无法获取应用目录: $e');
      // 最后尝试使用临时目录
      return Directory.systemTemp;
    }
  }
}
