import 'package:teacher_tools/utils/pinyin_helper.dart';

/// 数据库迁移工具
///
/// 用于将旧版本数据库迁移到新版本
/// 支持自动填充缺失字段
import 'package:teacher_tools/utils/backup_data.dart';

/// 数据库迁移工具
class SchemaMigration {
  /// 迁移学生数据 (从旧版本到新版本)
  ///
  /// [students] 原始学生数据列表
  /// [fromVersion] 源数据库版本
  /// [toVersion] 目标数据库版本
  ///
  /// 返回迁移后的学生数据列表
  static List<Map<String, dynamic>> migrateStudents(
    List<Map<String, dynamic>> students,
    int fromVersion,
    int toVersion,
  ) {
    if (fromVersion == toVersion) {
      return students;
    }

    if (fromVersion > toVersion) {
      throw BackupException('不支持降级迁移: v$fromVersion -> v$toVersion');
    }

    // 逐个版本升级
    var currentVersion = fromVersion;
    var migratedStudents = students;

    while (currentVersion < toVersion) {
      migratedStudents = _upgradeToNextVersion(migratedStudents, currentVersion);
      currentVersion++;
    }

    return migratedStudents;
  }

  /// 升级到下一个版本
  static List<Map<String, dynamic>> _upgradeToNextVersion(
    List<Map<String, dynamic>> students,
    int currentVersion,
  ) {
    switch (currentVersion) {
      case 3:
        // DB v3 → v4: 添加 personality_traits 字段
        return students.map((student) {
          if (!student.containsKey('personality_traits') ||
              student['personality_traits'] == null) {
            student = Map<String, dynamic>.from(student);
            student['personality_traits'] = null;
          }
          return student;
        }).toList();

      case 4:
        // DB v4 → v5: 添加 pinyin, pinyin_abbr 字段
        return students.map((student) {
          return _fillPinyinFields(student);
        }).toList();

      default:
        return students;
    }
  }

  /// 为单个学生填充缺失字段
  ///
  /// [student] 原始学生数据
  /// [fromVersion] 源数据库版本
  ///
  /// 返回填充后的学生数据
  static Map<String, dynamic> fillMissingFields(
    Map<String, dynamic> student,
    int fromVersion,
  ) {
    final result = Map<String, dynamic>.from(student);

    // DB v3-4 → v5: 需要添加 personality_traits
    if (fromVersion < 4) {
      if (!result.containsKey('personality_traits') ||
          result['personality_traits'] == null) {
        result['personality_traits'] = null;
      }
    }

    // DB v3-4 → v5: 需要添加拼音字段
    if (fromVersion < 5) {
      if (!result.containsKey('pinyin') ||
          result['pinyin'] == null ||
          (result['pinyin'] as String).isEmpty) {
        final name = result['name'] as String? ?? '';
        result['pinyin'] = generatePinyin(name);
      }

      if (!result.containsKey('pinyin_abbr') ||
          result['pinyin_abbr'] == null ||
          (result['pinyin_abbr'] as String).isEmpty) {
        final name = result['name'] as String? ?? '';
        result['pinyin_abbr'] = generatePinyinAbbr(name);
      }
    }

    return result;
  }

  /// 为学生数据填充拼音字段 (v4 → v5)
  static Map<String, dynamic> _fillPinyinFields(
    Map<String, dynamic> student,
  ) {
    final result = Map<String, dynamic>.from(student);
    final name = result['name'] as String? ?? '';

    // 如果拼音字段不存在或为空,则生成
    if (!result.containsKey('pinyin') ||
        result['pinyin'] == null ||
        (result['pinyin'] as String).isEmpty) {
      result['pinyin'] = generatePinyin(name);
    }

    if (!result.containsKey('pinyin_abbr') ||
        result['pinyin_abbr'] == null ||
        (result['pinyin_abbr'] as String).isEmpty) {
      result['pinyin_abbr'] = generatePinyinAbbr(name);
    }

    return result;
  }

  /// 生成全拼
  ///
  /// [name] 学生姓名
  ///
  /// 返回全拼字符串 (如: "zhangsan")
  static String generatePinyin(String name) {
    if (name.isEmpty) return '';
    return PinyinHelperUtils.getPinyin(name);
  }

  /// 生成拼音首字母
  ///
  /// [name] 学生姓名
  ///
  /// 返回拼音首字母 (如: "zs")
  static String generatePinyinAbbr(String name) {
    if (name.isEmpty) return '';
    return PinyinHelperUtils.getPinyinAbbr(name);
  }

  /// 批量生成拼音字段
  ///
  /// [students] 学生数据列表
  ///
  /// 返回填充了拼音字段的学生数据列表
  static List<Map<String, dynamic>> generatePinyinForAll(
    List<Map<String, dynamic>> students,
  ) {
    return students.map((student) => _fillPinyinFields(student)).toList();
  }

  /// 验证数据完整性
  ///
  /// [students] 学生数据列表
  /// [version] 目标数据库版本
  ///
  /// 返回验证结果和错误信息
  static (bool, List<String>) validateStudents(
    List<Map<String, dynamic>> students,
    int version,
  ) {
    final errors = <String>[];

    for (var i = 0; i < students.length; i++) {
      final student = students[i];

      // 检查必需字段
      if (!student.containsKey('id') || student['id'] == null) {
        errors.add('学生[$i]缺少id字段');
      }

      if (!student.containsKey('name') || student['name'] == null) {
        errors.add('学生[$i]缺少name字段');
      }

      if (!student.containsKey('student_number') || student['student_number'] == null) {
        errors.add('学生[$i]缺少student_number字段');
      }

      // 检查v5版本特有的字段
      if (version >= 5) {
        if (!student.containsKey('pinyin') || student['pinyin'] == null) {
          errors.add('学生[$i]缺少pinyin字段');
        }

        if (!student.containsKey('pinyin_abbr') || student['pinyin_abbr'] == null) {
          errors.add('学生[$i]缺少pinyin_abbr字段');
        }
      }
    }

    return (errors.isEmpty, errors);
  }
}
