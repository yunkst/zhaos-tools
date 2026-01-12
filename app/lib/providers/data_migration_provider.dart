import 'package:flutter/foundation.dart';
import 'package:teacher_tools/database/student_dao.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/utils/pinyin_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 数据迁移Provider
class DataMigrationProvider {
  final StudentDAO _studentDAO = StudentDAO();

  // 迁移版本标记
  static const String _keyPinyinMigration = 'pinyin_migration_v1';

  /// 检查并执行拼音数据迁移
  Future<bool> checkAndMigratePinyin() async {
    final prefs = await SharedPreferences.getInstance();
    final hasMigrated = prefs.getBool(_keyPinyinMigration) ?? false;

    if (hasMigrated) {
      debugPrint('✅ 拼音数据迁移已完成，跳过');
      return true;
    }

    debugPrint('🔄 开始执行拼音数据迁移...');
    try {
      final success = await _migrateStudentPinyin();

      if (success) {
        await prefs.setBool(_keyPinyinMigration, true);
        debugPrint('✅ 拼音数据迁移完成');
        return true;
      } else {
        debugPrint('❌ 拼音数据迁移失败');
        return false;
      }
    } catch (e) {
      debugPrint('❌ 拼音数据迁移出错: $e');
      return false;
    }
  }

  /// 迁移学生拼音数据
  Future<bool> _migrateStudentPinyin() async {
    try {
      // 获取所有学生
      final allStudents = await _studentDAO.getAll();

      if (allStudents.isEmpty) {
        debugPrint('📭 没有学生数据需要迁移');
        return true;
      }

      debugPrint('📊 开始迁移 ${allStudents.length} 个学生的拼音数据...');

      int successCount = 0;
      int failCount = 0;

      for (var student in allStudents) {
        try {
          // 检查是否已有拼音数据
          if (student.pinyin != null && student.pinyinAbbr != null) {
            debugPrint('⏭️  学生 ${student.name} 已有拼音数据，跳过');
            continue;
          }

          // 生成拼音
          final pinyin = PinyinHelperUtils.getPinyin(student.name);
          final pinyinAbbr = PinyinHelperUtils.getPinyinAbbr(student.name);

          // 更新学生数据
          final updatedStudent = student.copyWith(
            pinyin: Value(pinyin),
            pinyinAbbr: Value(pinyinAbbr),
          );

          final result = await _studentDAO.update(updatedStudent);

          if (result > 0) {
            successCount++;
            debugPrint('✅ ${student.name} -> $pinyin / $pinyinAbbr');
          } else {
            failCount++;
            debugPrint('❌ 更新失败: ${student.name}');
          }
        } catch (e) {
          failCount++;
          debugPrint('❌ 处理学生 ${student.name} 时出错: $e');
        }
      }

      debugPrint('📊 迁移完成: 成功 $successCount 个, 失败 $failCount 个');
      return failCount == 0;
    } catch (e) {
      debugPrint('❌ 迁移学生拼音数据失败: $e');
      return false;
    }
  }

  /// 重置迁移标记（用于测试）
  Future<void> resetMigrationFlag() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPinyinMigration);
    debugPrint('🔄 迁移标记已重置');
  }
}
