import 'dart:convert';

/// 备份管理器
///
/// 负责数据的备份和恢复操作
/// 支持分批处理,避免内存溢出
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:teacher_tools/utils/constants.dart';
import 'package:teacher_tools/utils/backup_data.dart';
import 'package:teacher_tools/utils/schema_migration.dart';
import 'package:teacher_tools/database/database_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// 进度回调函数类型
typedef ProgressCallback = void Function(int current, int total, String message);

/// 备份管理器
class BackupManager {
  /// 数据库帮助类
  final DatabaseHelper _db = DatabaseHelper();

  /// 分批大小 (每批处理100条记录)
  static const int _batchSize = 100;

  /// 数据库表名列表 (按依赖顺序)
  static const List<String> _tableNames = [
    'classes',  // 班级 (无依赖)
    'students', // 学生 (依赖班级)
    'notes',    // 笔记 (依赖学生、班级)
    'exams',    // 考试 (依赖班级)
    'scores',   // 成绩 (依赖考试、学生、班级)
  ];

  // ========== 创建备份 ==========

  /// 创建完整备份
  ///
  /// [onProgress] 进度回调函数
  ///
  /// 返回备份文件的完整路径
  Future<String> createBackup({ProgressCallback? onProgress}) async {
    try {
      onProgress?.call(0, 100, '开始备份...');

      // 1. 导出所有表数据
      final dataMap = <String, List<Map<String, dynamic>>>{};

      int progress = 0;
      final progressStep = 90 ~/ _tableNames.length;

      for (final tableName in _tableNames) {
        onProgress?.call(progress, 100, '正在导出 $tableName...');
        dataMap[tableName] = await _exportTable(tableName);
        progress += progressStep;
        onProgress?.call(progress, 100, '已导出 $tableName');
      }

      // 2. 构建备份数据
      onProgress?.call(90, 100, '正在生成备份文件...');

      final backupContent = BackupContent(
        classes: dataMap['classes']!,
        students: dataMap['students']!,
        notes: dataMap['notes']!,
        exams: dataMap['exams']!,
        scores: dataMap['scores']!,
      );

      final packageInfo = await PackageInfo.fromPlatform();

      final metadata = BackupMetadata(
        appVersion: packageInfo.version,
        databaseVersion: AppConstants.databaseVersion,
        backupDate: DateTime.now(),
        dataStats: DataStats(
          classesCount: backupContent.classes.length,
          studentsCount: backupContent.students.length,
          notesCount: backupContent.notes.length,
          examsCount: backupContent.exams.length,
          scoresCount: backupContent.scores.length,
        ),
        checksum: '', // 稍后计算
      );

      final backupData = BackupData(
        meta: metadata,
        data: backupContent,
      );

      // 3. 计算校验和
      // 计算校验和时不包含checksum字段本身
      final jsonDataForChecksum = jsonEncode(backupData.data.toJson());
      final checksum = sha256.convert(utf8.encode(jsonDataForChecksum)).toString();

      // 设置checksum后生成完整的JSON
      backupData.meta.checksum = checksum;
      final finalJsonData = jsonEncode(backupData.toJson());

      // 4. 写入文件
      final backupDir = await _getBackupDirectory();
      final fileName = _generateBackupFileName();
      final filePath = '$backupDir/$fileName';

      final file = File(filePath);
      await file.writeAsString(finalJsonData);

      onProgress?.call(100, 100, '备份完成: $fileName');
      debugPrint('✅ 备份成功: $filePath');
      debugPrint('📊 数据统计: ${metadata.dataStats}');

      return filePath;
    } catch (e, stackTrace) {
      debugPrint('❌ 备份失败: $e');
      debugPrint('堆栈信息: $stackTrace');
      throw BackupException('备份失败', e);
    }
  }

  /// 导出单个表数据 (分批读取)
  ///
  /// [tableName] 表名
  ///
  /// 返回表数据列表
  Future<List<Map<String, dynamic>>> _exportTable(String tableName) async {
    try {
      final db = await _db.database;
      final data = <Map<String, dynamic>>[];

      int offset = 0;
      bool hasMore = true;

      // 分批查询,避免内存溢出
      while (hasMore) {
        final batch = await db.query(
          tableName,
          limit: _batchSize,
          offset: offset,
        );

        if (batch.isEmpty) {
          hasMore = false;
        } else {
          data.addAll(batch);
          offset += _batchSize;
        }
      }

      debugPrint('📦 导出 $tableName: ${data.length} 条记录');
      return data;
    } catch (e) {
      throw BackupException('导出表 $tableName 失败', e);
    }
  }

  // ========== 恢复备份 ==========

  /// 恢复备份数据
  ///
  /// [filePath] 备份文件路径
  /// [onProgress] 进度回调函数
  ///
  /// 返回是否成功
  Future<bool> restoreBackup(
    String filePath, {
    ProgressCallback? onProgress,
  }) async {
    try {
      onProgress?.call(0, 100, '验证备份文件...');

      // 1. 读取并验证备份文件
      final backupData = await validateBackup(filePath);
      if (backupData == null) {
        throw BackupException('备份文件无效或损坏');
      }

      onProgress?.call(5, 100, '备份文件验证通过');

      // 2. 版本兼容性检查
      if (backupData.meta.databaseVersion > AppConstants.databaseVersion) {
        throw BackupException(
          '备份文件版本过高 (v${backupData.meta.databaseVersion}), '
          '当前数据库版本: v$AppConstants.databaseVersion\n'
          '请升级APP到最新版本',
        );
      }

      // 3. 数据迁移 (如果需要)
      List<Map<String, dynamic>> students = backupData.data.students;

      if (backupData.meta.databaseVersion < AppConstants.databaseVersion) {
        onProgress?.call(
          10,
          100,
          '正在升级数据格式 (v${backupData.meta.databaseVersion} → '
          'v$AppConstants.databaseVersion)...',
        );

        students = SchemaMigration.migrateStudents(
          students,
          backupData.meta.databaseVersion,
          AppConstants.databaseVersion,
        );

        debugPrint('✅ 数据迁移完成');
      }

      onProgress?.call(15, 100, '开始恢复数据...');

      // 4. 清空当前数据 (使用事务)
      final db = await _db.database;
      await db.transaction((txn) async {
        for (final tableName in _tableNames.reversed) {
          // 反向删除 (先删除依赖表)
          await txn.delete(tableName);
        }
      });

      onProgress?.call(20, 100, '已清空旧数据');

      // 5. 分批导入数据
      int progress = 20;
      final progressStep = 75 ~/ _tableNames.length;

      // 导入班级
      await _importTable(db, 'classes', backupData.data.classes);
      progress += progressStep;
      onProgress?.call(progress, 100, '已恢复班级数据');

      // 导入学生
      await _importTable(db, 'students', students);
      progress += progressStep;
      onProgress?.call(progress, 100, '已恢复学生数据');

      // 导入笔记
      await _importTable(db, 'notes', backupData.data.notes);
      progress += progressStep;
      onProgress?.call(progress, 100, '已恢复笔记数据');

      // 导入考试
      await _importTable(db, 'exams', backupData.data.exams);
      progress += progressStep;
      onProgress?.call(progress, 100, '已恢复考试数据');

      // 导入成绩
      await _importTable(db, 'scores', backupData.data.scores);
      progress += progressStep;
      onProgress?.call(progress, 100, '已恢复成绩数据');

      onProgress?.call(100, 100, '恢复完成');
      debugPrint('✅ 恢复成功: ${backupData.meta.dataStats}');

      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ 恢复失败: $e');
      debugPrint('堆栈信息: $stackTrace');
      throw BackupException('恢复失败', e);
    }
  }

  /// 导入单个表数据 (分批写入)
  ///
  /// [db] 数据库实例
  /// [tableName] 表名
  /// [data] 数据列表
  Future<void> _importTable(
    Database db,
    String tableName,
    List<Map<String, dynamic>> data,
  ) async {
    try {
      if (data.isEmpty) {
        debugPrint('⚠️  表 $tableName 无数据需要导入');
        return;
      }

      // 分批插入
      for (int i = 0; i < data.length; i += _batchSize) {
        final end = (i + _batchSize < data.length) ? i + _batchSize : data.length;
        final batch = data.sublist(i, end);

        final batchNum = (i ~/ _batchSize) + 1;
        final totalBatches = (data.length / _batchSize).ceil();

        for (final row in batch) {
          await db.insert(tableName, row);
        }

        debugPrint(
          '📥 导入 $tableName: batch $batchNum/$totalBatches '
          '($end/$data.length)',
        );
      }

      debugPrint('✅ 导入 $tableName 完成: ${data.length} 条记录');
    } catch (e) {
      throw BackupException('导入表 $tableName 失败', e);
    }
  }

  // ========== 验证备份文件 ==========

  /// 验证备份文件
  ///
  /// [filePath] 备份文件路径
  ///
  /// 返回解析后的备份数据,如果文件无效则返回null
  Future<BackupData?> validateBackup(String filePath) async {
    try {
      // 1. 检查文件是否存在
      final file = File(filePath);
      if (!await file.exists()) {
        debugPrint('❌ 备份文件不存在: $filePath');
        return null;
      }

      // 2. 读取文件内容
      final jsonString = await file.readAsString();

      // 3. 解析JSON
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;

      // 4. 构建备份数据对象
      final backupData = BackupData.fromJson(jsonData);

      // 5. 验证数据完整性
      if (!backupData.isValid) {
        debugPrint('❌ 备份数据完整性验证失败');
        return null;
      }

      // 6. 验证校验和
      // 只对data部分计算校验和,不包含meta中的checksum字段
      final jsonDataForChecksum = jsonEncode(backupData.data.toJson());
      final calculatedChecksum = sha256.convert(utf8.encode(jsonDataForChecksum)).toString();

      if (calculatedChecksum != backupData.meta.checksum) {
        debugPrint('❌ 校验和验证失败');
        debugPrint('预期: ${backupData.meta.checksum}');
        debugPrint('实际: $calculatedChecksum');
        return null;
      }

      debugPrint('✅ 备份文件验证通过');
      debugPrint('📊 版本: ${backupData.meta.appVersion} '
          '(DB v${backupData.meta.databaseVersion})');
      debugPrint('📅 备份时间: ${backupData.meta.backupDate}');
      debugPrint('📦 数据统计: ${backupData.meta.dataStats}');

      return backupData;
    } catch (e, stackTrace) {
      debugPrint('❌ 验证备份文件失败: $e');
      debugPrint('堆栈信息: $stackTrace');
      return null;
    }
  }

  // ========== 工具方法 ==========

  /// 获取默认备份目录
  ///
  /// 返回备份目录的完整路径
  Future<String> _getBackupDirectory() async {
    try {
      // 使用外部存储的Download目录
      final directory = await getDownloadsDirectory();

      if (directory != null) {
        final backupDir = Directory('${directory.path}/TeacherTools_Backups');
        if (!await backupDir.exists()) {
          await backupDir.create(recursive: true);
        }
        return backupDir.path;
      }

      // 降级方案: 使用应用文档目录
      final appDocDir = await getApplicationDocumentsDirectory();
      final backupDir = Directory('${appDocDir.path}/backups');
      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }
      return backupDir.path;
    } catch (e) {
      throw BackupException('获取备份目录失败', e);
    }
  }

  /// 获取备份目录 (Android专用)
  Future<Directory?> getDownloadsDirectory() async {
    try {
      // Android: /storage/emulated/0/Download
      final directory = Directory('/storage/emulated/0/Download');
      if (await directory.exists()) {
        return directory;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 生成备份文件名
  ///
  /// 格式: teacher_tools_backup_YYYYMMDD_HHMMSS.json
  ///
  /// 返回文件名
  String _generateBackupFileName() {
    final now = DateTime.now();
    final dateStr = '${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}';
    final timeStr = '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}'
        '${now.second.toString().padLeft(2, '0')}';
    return 'teacher_tools_backup_${dateStr}_$timeStr.json';
  }

  /// 获取备份文件列表
  ///
  /// 返回备份文件信息列表
  Future<List<BackupFileInfo>> getBackupFiles() async {
    try {
      final backupDir = await _getBackupDirectory();
      final dir = Directory(backupDir);

      if (!await dir.exists()) {
        return [];
      }

      final entities = await dir.list().toList();
      final files = entities.where((entity) =>
        entity.path.endsWith('.json')
      ).toList();

      final backupFiles = <BackupFileInfo>[];

      for (final file in files) {
        final backupData = await validateBackup(file.path);
        if (backupData != null) {
          final fileEntity = file as File;
          backupFiles.add(BackupFileInfo(
            path: file.path,
            fileName: file.path.split('/').last,
            size: await fileEntity.length(),
            metadata: backupData.meta,
          ));
        }
      }

      // 按备份时间倒序排列
      backupFiles.sort((a, b) =>
        b.metadata.backupDate.compareTo(a.metadata.backupDate));

      return backupFiles;
    } catch (e) {
      throw BackupException('获取备份文件列表失败', e);
    }
  }
}

/// 备份文件信息
class BackupFileInfo {
  /// 文件路径
  final String path;

  /// 文件名
  final String fileName;

  /// 文件大小 (字节)
  final int size;

  /// 备份元数据
  final BackupMetadata metadata;

  BackupFileInfo({
    required this.path,
    required this.fileName,
    required this.size,
    required this.metadata,
  });

  /// 格式化的文件大小
  String get formattedSize {
    if (size < 1024) {
      return '$size B';
    } else if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  @override
  String toString() {
    return 'BackupFileInfo(fileName: $fileName, size: $formattedSize, '
        'date: ${metadata.backupDate})';
  }
}
