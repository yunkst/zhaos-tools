import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:intl/intl.dart';

/// 批量评语导出服务
/// 将批量生成的评语导出为Excel文件
class BatchCommentExporter {
  /// 导出到Excel
  ///
  /// [students] - 学生列表
  /// [comments] - 学生ID到评语的映射
  /// [failedStudents] - 失败的学生ID到错误信息的映射
  ///
  /// 返回文件路径
  static Future<String> exportToExcel(
    List<Student> students,
    Map<int, String> comments,
    Map<int, String> failedStudents,
  ) async {
    debugPrint('📊 [BatchCommentExporter] 开始导出Excel...');

    // 1. 创建Excel对象
    final excel = Excel.createExcel();

    // 2. 删除默认Sheet
    excel.delete('Sheet1');

    // 3. 创建Sheet
    final sheet = excel['期末评语'];

    // 4. 添加表头
    _addHeaders(sheet);

    // 5. 填充数据
    int rowIndex = 2; // 从第2行开始（第1行是表头）
    for (final student in students) {
      final studentId = student.id!;

      // 学号
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex)).value =
          TextCellValue(student.studentNumber);

      // 姓名
      sheet.cell(CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex)).value =
          TextCellValue(student.name);

      // 评语
      if (comments.containsKey(studentId)) {
        // 成功生成
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
            TextCellValue(comments[studentId]!);
      } else if (failedStudents.containsKey(studentId)) {
        // 生成失败
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
            TextCellValue('生成失败: ${failedStudents[studentId]}');
      } else {
        // 未生成
        sheet.cell(CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: rowIndex)).value =
            TextCellValue('未生成');
      }

      rowIndex++;
    }

    debugPrint('✅ [BatchCommentExporter] 数据填充完成，共 ${students.length} 行');

    // 6. 保存到文件
    final bytes = excel.save();
    if (bytes == null) {
      throw Exception('Excel保存失败: bytes为null');
    }

    // 7. 获取保存路径
    final directory = await _getSaveDirectory();
    final fileName = _generateFileName();
    final filePath = '${directory.path}/$fileName';

    debugPrint('📁 [BatchCommentExporter] 保存路径: $filePath');

    // 8. 写入文件
    final file = File(filePath);
    await file.writeAsBytes(bytes);

    debugPrint('✅ [BatchCommentExporter] 文件保存成功! 大小: ${bytes.length} bytes');

    return filePath;
  }

  /// 添加表头
  static void _addHeaders(Sheet sheet) {
    // A1: 学号
    sheet.cell(CellIndex.indexByString('A1')).value = TextCellValue('学号');
    // B1: 姓名
    sheet.cell(CellIndex.indexByString('B1')).value = TextCellValue('姓名');
    // C1: 期末评语
    sheet.cell(CellIndex.indexByString('C1')).value = TextCellValue('期末评语');

    // 设置表头样式（简化版，不使用不支持的API）
    final headerStyle = CellStyle(
      bold: true,
      horizontalAlign: HorizontalAlign.Center,
    );

    sheet.cell(CellIndex.indexByString('A1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('B1')).cellStyle = headerStyle;
    sheet.cell(CellIndex.indexByString('C1')).cellStyle = headerStyle;

    debugPrint('📋 [BatchCommentExporter] 表头添加完成');
  }

  /// 生成文件名
  static String _generateFileName() {
    final now = DateTime.now();
    final dateFormat = DateFormat('yyyy-MM-dd_HH-mm-ss');
    final timestamp = dateFormat.format(now);
    return '期末评语_$timestamp.xlsx';
  }

  /// 获取保存目录
  static Future<Directory> _getSaveDirectory() async {
    // 优先使用Download目录
    try {
      final directory = await getDownloadsDirectory();
      if (directory != null) {
        debugPrint('✅ [BatchCommentExporter] 使用Download目录: ${directory.path}');
        return directory;
      }
    } catch (e) {
      debugPrint('⚠️ [BatchCommentExporter] 无法获取Download目录: $e');
    }

    // 退而求其次使用应用文档目录
    try {
      final directory = await getApplicationDocumentsDirectory();
      debugPrint('✅ [BatchCommentExporter] 使用应用文档目录: ${directory.path}');
      return directory;
    } catch (e) {
      debugPrint('❌ [BatchCommentExporter] 无法获取应用目录: $e');
      // 最后尝试使用临时目录
      return Directory.systemTemp;
    }
  }
}
