import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';

/// 测试excel包能否创建Excel文件
void main() async {
  debugPrint('🧪 开始测试 excel 包...\n');

  // 创建Excel文件对象
  final Excel excel = Excel.createExcel();

  // 删除默认的Sheet
  excel.delete('Sheet1');

  // 创建一个Sheet
  final Sheet sheetObject = excel['学生数据'];

  // 添加表头
  sheetObject.cell(CellIndex.indexByString('A1')).value = TextCellValue('姓名');
  sheetObject.cell(CellIndex.indexByString('B1')).value = TextCellValue('学号');
  sheetObject.cell(CellIndex.indexByString('C1')).value = TextCellValue('性别');
  sheetObject.cell(CellIndex.indexByString('D1')).value = TextCellValue('成绩');

  // 添加数据
  sheetObject.cell(CellIndex.indexByString('A2')).value = TextCellValue('张三');
  sheetObject.cell(CellIndex.indexByString('B2')).value = TextCellValue('2024001');
  sheetObject.cell(CellIndex.indexByString('C2')).value = TextCellValue('男');
  sheetObject.cell(CellIndex.indexByString('D2')).value = TextCellValue('95');

  sheetObject.cell(CellIndex.indexByString('A3')).value = TextCellValue('李四');
  sheetObject.cell(CellIndex.indexByString('B3')).value = TextCellValue('2024002');
  sheetObject.cell(CellIndex.indexByString('C3')).value = TextCellValue('女');
  sheetObject.cell(CellIndex.indexByString('D3')).value = TextCellValue('88');

  sheetObject.cell(CellIndex.indexByString('A4')).value = TextCellValue('王五');
  sheetObject.cell(CellIndex.indexByString('B4')).value = TextCellValue('2024003');
  sheetObject.cell(CellIndex.indexByString('C4')).value = TextCellValue('男');
  sheetObject.cell(CellIndex.indexByString('D4')).value = TextCellValue('92');

  debugPrint('✅ Excel数据创建成功');
  debugPrint('📊 Sheet名称: ${sheetObject.sheetName}');
  debugPrint('📝 包含数据行数: 4');

  // 保存到文件
  try {
    final directory = Directory.current;
    final filePath = '${directory.path}/test_students.xlsx';

    final List<int>? bytes = excel.save();
    if (bytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(bytes);
      debugPrint('✅ Excel文件保存成功!');
      debugPrint('📁 文件路径: $filePath');
      debugPrint('📦 文件大小: ${bytes.length} bytes');

      // 读取文件验证
      if (await file.exists()) {
        debugPrint('✅ 文件存在验证通过');
        debugPrint('📄 文件大小: ${await file.length()} bytes');
      } else {
        debugPrint('❌ 文件不存在');
      }
    } else {
      debugPrint('❌ Excel保存失败: bytes为null');
    }
  } catch (e) {
    debugPrint('❌ 保存Excel失败: $e');
  }

  debugPrint('\n🎉 测试完成!');
}
