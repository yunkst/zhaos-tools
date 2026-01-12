import 'dart:io';
import 'package:csv/csv.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

/// Excel 导入工具类
class ExcelImporter {
  /// 选择 CSV/Excel 文件
  static Future<File?> pickExcelFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv', 'xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        return File(result.files.single.path!);
      }
      return null;
    } catch (e, stackTrace) {
      debugPrint('❌ 选择文件失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return null;
    }
  }

  /// 解析 CSV/Excel 文件
  static Future<List<Map<String, dynamic>>?> parseExcelFile(File file) async {
    try {
      debugPrint('📂 开始读取文件: ${file.path}');
      final extension = file.path.split('.').last.toLowerCase();
      debugPrint('📋 文件类型: $extension');

      if (extension == 'csv') {
        return await _parseCsvFile(file);
      } else if (extension == 'xlsx' || extension == 'xls') {
        // 使用 Isolate 在后台线程解析 Excel，避免主线程崩溃
        return await _parseExcelInIsolate(file);
      } else {
        debugPrint('❌ 不支持的文件格式: $extension');
        return null;
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 解析文件失败: $e');
      debugPrint('错误类型: ${e.runtimeType}');
      debugPrint('堆栈跟踪:\n$stackTrace');
      return null;
    }
  }

  /// 使用 Isolate 在后台线程解析 Excel（解决主线程崩溃问题）
  static Future<List<Map<String, dynamic>>?> _parseExcelInIsolate(File file) async {
    try {
      debugPrint('🔄 在后台线程解析 Excel...');
      final bytes = await file.readAsBytes();
      debugPrint('📊 文件大小: ${bytes.length} bytes');

      // 在 Isolate 中解析
      final result = await compute(_parseExcelBytes, bytes);

      if (result == null) {
        debugPrint('❌ Excel 解析失败');
        return null;
      }

      debugPrint('✅ Excel 解析成功!');
      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ Excel 解析异常: $e');
      debugPrint('错误类型: ${e.runtimeType}');
      debugPrint('堆栈跟踪:\n$stackTrace');
      return null;
    }
  }

  /// 在 Isolate 中执行的解析函数
  static List<Map<String, dynamic>>? _parseExcelBytes(List<int> bytes) {
    try {
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);

      if (decoder.tables.isEmpty) {
        return null;
      }

      final table = decoder.tables.values.first;
      final rows = table.rows;

      if (rows.isEmpty) {
        return null;
      }

      // 获取表头
      final headerRow = rows.first;
      final headers = <String>[];

      for (final cell in headerRow) {
        headers.add(cell?.toString() ?? '');
      }

      // 解析数据行
      final data = <Map<String, dynamic>>[];

      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final rowData = <String, dynamic>{};

        for (var j = 0; j < headers.length && j < row.length; j++) {
          final header = headers[j];
          if (header.isNotEmpty) {
            final value = row[j]?.toString() ?? '';
            rowData[header] = value;
          }
        }

        if (rowData.isNotEmpty) {
          data.add(rowData);
        }
      }

      return data;
    } catch (e) {
      // 在 Isolate 中使用 print（不能用 debugPrint）
      debugPrint('❌ Isolate 解析失败: $e');
      return null;
    }
  }

  /// 解析 CSV 文件
  static Future<List<Map<String, dynamic>>?> _parseCsvFile(File file) async {
    try {
      final input = await file.readAsString();
      debugPrint('📊 CSV文件大小: ${input.length} bytes');

      // 解析 CSV - 使用 CsvToListConverter
      final List<List<dynamic>> rows = const CsvToListConverter().convert(input);
      debugPrint('✅ CSV 解析成功，总行数: ${rows.length}');

      if (rows.isEmpty) {
        debugPrint('❌ CSV 文件为空');
        return null;
      }

      // 第一行是表头
      final headers = rows.first;
      debugPrint('🏷️ 表头列数: ${headers.length}');
      debugPrint('表头: $headers');

      // 解析数据行
      final List<Map<String, dynamic>> data = [];
      for (var i = 1; i < rows.length; i++) {
        final row = rows[i];
        final rowData = <String, dynamic>{};

        for (var j = 0; j < headers.length && j < row.length; j++) {
          final header = headers[j]?.toString() ?? '';
          final value = row[j]?.toString() ?? '';
          if (header.isNotEmpty) {
            rowData[header] = value;
          }
        }

        if (rowData.isNotEmpty) {
          data.add(rowData);
        }
      }

      debugPrint('✅ 成功解析 ${data.length} 行数据');
      return data;
    } catch (e, stackTrace) {
      debugPrint('❌ 解析 CSV 失败: $e');
      debugPrint('堆栈跟踪:\n$stackTrace');
      return null;
    }
  }

  /// 解析性别字符串
  static String _parseGender(dynamic genderValue) {
    if (genderValue == null) return 'unknown';
    final gender = genderValue.toString().trim();
    if (gender == '男') return 'male';
    if (gender == '女') return 'female';
    return 'unknown';
  }

  /// 安全解析为double
  static double? _parseDouble(dynamic value) {
    if (value == null || value.toString().isEmpty) return null;
    try {
      return double.parse(value.toString());
    } catch (e) {
      return null;
    }
  }

  /// 从身份证号计算出生日期
  static DateTime? _parseBirthDateFromIdCard(String? idCardNumber) {
    if (idCardNumber == null || idCardNumber.length < 18) return null;
    try {
      final year = int.parse(idCardNumber.substring(6, 10));
      final month = int.parse(idCardNumber.substring(10, 12));
      final day = int.parse(idCardNumber.substring(12, 14));
      return DateTime(year, month, day);
    } catch (e) {
      return null;
    }
  }

  /// 从 Excel 导入学生数据（完整版）
  /// 预期格式: 25列完整学生信息
  static Future<List<Map<String, dynamic>>> importStudentsFromExcel() async {
    final file = await pickExcelFile();
    if (file == null) return [];

    final data = await parseExcelFile(file);
    if (data == null || data.isEmpty) return [];

    // 转换为学生数据格式
    final List<Map<String, dynamic>> students = [];
    for (var row in data) {
      // 从身份证号解析出生日期
      final idCardNumber = row['身份证号']?.toString().trim() ?? '';
      final birthDate = _parseBirthDateFromIdCard(idCardNumber);

      final student = {
        'studentNumber': (row['学号'] ?? '').toString().trim(),
        'name': (row['姓名'] ?? '').toString().trim(),
        'gender': _parseGender(row['性别']),
        'idCardNumber': idCardNumber,
        'birthDate': birthDate?.toIso8601String(),
        'height': _parseDouble(row['身高']),
        'vision': (row['视力'] ?? '').toString().trim(),
        'primarySchool': (row['毕业小学'] ?? '').toString().trim(),
        'address': (row['家庭住址'] ?? '').toString().trim(),
        'phone': (row['联系方式'] ?? '').toString().trim(),
        'transportMethod': (row['交通方式'] ?? '').toString().trim(),
        'licensePlate': (row['车牌号'] ?? '').toString().trim(),
        'parentName': (row['家长1姓名'] ?? '').toString().trim(),
        'parentPhone': (row['家长1电话'] ?? '').toString().trim(),
        'parentTitle': (row['家长1称谓'] ?? '').toString().trim(),
        'parentCompany': (row['家长1工作单位'] ?? '').toString().trim(),
        'parentPosition': (row['家长1职务'] ?? '').toString().trim(),
        'parentName2': (row['家长2姓名'] ?? '').toString().trim(),
        'parentPhone2': (row['家长2电话'] ?? '').toString().trim(),
        'parentTitle2': (row['家长2称谓'] ?? '').toString().trim(),
        'parentCompany2': (row['家长2工作单位'] ?? '').toString().trim(),
        'parentPosition2': (row['家长2职务'] ?? '').toString().trim(),
        'currentSchool': (row['就读小学'] ?? '').toString().trim(),
        'classPosition': (row['担任职务'] ?? '').toString().trim(),
        'awards': (row['获奖情况'] ?? '').toString().trim(),
        'talents': (row['其他特长'] ?? '').toString().trim(),
      };

      // 验证必填字段（学号、姓名、性别、家长1姓名、家长1电话）
      if (student['studentNumber'].toString().isNotEmpty &&
          student['name'].toString().isNotEmpty &&
          student['parentName'].toString().isNotEmpty &&
          student['parentPhone'].toString().isNotEmpty) {
        students.add(student);
      } else {
        debugPrint('⚠️ 跳过无效行: 学号=${student['studentNumber']}, 姓名=${student['name']}');
      }
    }

    debugPrint('✅ 成功解析 ${students.length} 条有效学生数据');
    return students;
  }

  /// 解析成绩Excel文件
  /// 预期格式: 6个sheet（总、语、数、英、科、社）
  /// 每个sheet包含: 学号、姓名、总分、名次、系数
  static Future<Map<String, List<Map<String, dynamic>>>?> parseScoreExcel(File file) async {
    try {
      debugPrint('📂 开始解析成绩Excel: ${file.path}');
      final extension = file.path.split('.').last.toLowerCase();

      if (extension != 'xlsx' && extension != 'xls') {
        debugPrint('❌ 成绩文件格式不正确，需要 .xlsx 或 .xls');
        return null;
      }

      // 使用 Isolate 在后台线程解析
      final bytes = await file.readAsBytes();
      final result = await compute(_parseScoreExcelBytes, bytes);

      if (result == null) {
        debugPrint('❌ 成绩Excel解析失败');
        return null;
      }

      debugPrint('✅ 成绩Excel解析成功!');
      result.forEach((sheetName, data) {
        debugPrint('  📊 $sheetName: ${data.length} 条记录');
      });

      return result;
    } catch (e, stackTrace) {
      debugPrint('❌ 解析成绩Excel失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return null;
    }
  }

  /// 在 Isolate 中解析成绩Excel
  static Map<String, List<Map<String, dynamic>>>? _parseScoreExcelBytes(List<int> bytes) {
    try {
      final decoder = SpreadsheetDecoder.decodeBytes(bytes);

      if (decoder.tables.isEmpty) {
        debugPrint('❌ Excel文件为空');
        return null;
      }

      // Sheet名称映射：中文名称 → 英文键名
      final sheetMapping = {
        '总': 'total',
        '语': 'chinese',
        '数': 'math',
        '英': 'english',
        '科': 'science',
        '社': 'morality', // 社会对应道德科目
      };

      final result = <String, List<Map<String, dynamic>>>{};

      // 遍历所有sheet
      decoder.tables.forEach((sheetName, table) {
        final rows = table.rows;
        if (rows.isEmpty) return;

        // 获取表头
        final headerRow = rows.first;
        final headers = <String>[];
        for (final cell in headerRow) {
          headers.add(cell?.toString() ?? '');
        }

        // 解析数据行
        final data = <Map<String, dynamic>>[];
        for (var i = 1; i < rows.length; i++) {
          final row = rows[i];
          final rowData = <String, dynamic>{};

          for (var j = 0; j < headers.length && j < row.length; j++) {
            final header = headers[j];
            if (header.isNotEmpty) {
              final value = row[j];
              // 特殊处理数值类型
              if (header == '学号' || header == '名次') {
                rowData[header] = value is int ? value : int.tryParse(value?.toString() ?? '');
              } else if (header == '总分' || header == '系数') {
                rowData[header] = value is double ? value : double.tryParse(value?.toString() ?? '');
              } else {
                rowData[header] = value?.toString() ?? '';
              }
            }
          }

          if (rowData.isNotEmpty && rowData['学号'] != null) {
            data.add(rowData);
          }
        }

        // 映射sheet名称
        final englishName = sheetMapping[sheetName];
        if (englishName != null) {
          result[englishName] = data;
        }
      });

      return result;
    } catch (e) {
      debugPrint('❌ Isolate解析成绩Excel失败: $e');
      return null;
    }
  }
}
