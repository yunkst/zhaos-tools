import 'package:teacher_tools/utils/constants.dart';

/// 备份数据模型
///
/// 用于数据备份和恢复的数据结构定义

/// 备份元数据
class BackupMetadata {
  /// APP版本 (如 "1.0.0")
  final String appVersion;

  /// 数据库版本 (如 5)
  final int databaseVersion;

  /// 备份时间
  final DateTime backupDate;

  /// 数据统计
  final DataStats dataStats;

  /// SHA256校验和
  String checksum;

  BackupMetadata({
    required this.appVersion,
    required this.databaseVersion,
    required this.backupDate,
    required this.dataStats,
    required this.checksum,
  });

  /// 从JSON创建
  factory BackupMetadata.fromJson(Map<String, dynamic> json) {
    return BackupMetadata(
      appVersion: json['appVersion'] as String,
      databaseVersion: json['databaseVersion'] as int,
      backupDate: DateTime.parse(json['backupDate'] as String),
      dataStats: DataStats.fromJson(json['dataStats'] as Map<String, dynamic>),
      checksum: json['checksum'] as String,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'appVersion': appVersion,
      'databaseVersion': databaseVersion,
      'backupDate': backupDate.toIso8601String(),
      'dataStats': dataStats.toJson(),
      'checksum': checksum,
    };
  }

  /// 复制并替换部分字段
  BackupMetadata copyWith({
    String? appVersion,
    int? databaseVersion,
    DateTime? backupDate,
    DataStats? dataStats,
    String? checksum,
  }) {
    return BackupMetadata(
      appVersion: appVersion ?? this.appVersion,
      databaseVersion: databaseVersion ?? this.databaseVersion,
      backupDate: backupDate ?? this.backupDate,
      dataStats: dataStats ?? this.dataStats,
      checksum: checksum ?? this.checksum,
    );
  }

  @override
  String toString() {
    return 'BackupMetadata(appVersion: $appVersion, databaseVersion: $databaseVersion, '
        'backupDate: $backupDate, dataStats: $dataStats, checksum: $checksum)';
  }
}

/// 数据统计
class DataStats {
  /// 班级数量
  final int classesCount;

  /// 学生数量
  final int studentsCount;

  /// 笔记数量
  final int notesCount;

  /// 考试数量
  final int examsCount;

  /// 成绩数量
  final int scoresCount;

  DataStats({
    required this.classesCount,
    required this.studentsCount,
    required this.notesCount,
    required this.examsCount,
    required this.scoresCount,
  });

  /// 从JSON创建
  factory DataStats.fromJson(Map<String, dynamic> json) {
    return DataStats(
      classesCount: json['classesCount'] as int,
      studentsCount: json['studentsCount'] as int,
      notesCount: json['notesCount'] as int,
      examsCount: json['examsCount'] as int,
      scoresCount: json['scoresCount'] as int,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'classesCount': classesCount,
      'studentsCount': studentsCount,
      'notesCount': notesCount,
      'examsCount': examsCount,
      'scoresCount': scoresCount,
    };
  }

  /// 总记录数
  int get totalRecords =>
      classesCount + studentsCount + notesCount + examsCount + scoresCount;

  @override
  String toString() {
    return 'DataStats(classes: $classesCount, students: $studentsCount, '
        'notes: $notesCount, exams: $examsCount, scores: $scoresCount)';
  }
}

/// 备份内容
class BackupContent {
  /// 班级数据
  final List<Map<String, dynamic>> classes;

  /// 学生数据
  final List<Map<String, dynamic>> students;

  /// 笔记数据
  final List<Map<String, dynamic>> notes;

  /// 考试数据
  final List<Map<String, dynamic>> exams;

  /// 成绩数据
  final List<Map<String, dynamic>> scores;

  BackupContent({
    required this.classes,
    required this.students,
    required this.notes,
    required this.exams,
    required this.scores,
  });

  /// 从JSON创建
  factory BackupContent.fromJson(Map<String, dynamic> json) {
    return BackupContent(
      classes: (json['classes'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      students: (json['students'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      notes: (json['notes'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      exams: (json['exams'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
      scores: (json['scores'] as List)
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'classes': classes,
      'students': students,
      'notes': notes,
      'exams': exams,
      'scores': scores,
    };
  }

  @override
  String toString() {
    return 'BackupContent(classes: ${classes.length}, students: ${students.length}, '
        'notes: ${notes.length}, exams: ${exams.length}, scores: ${scores.length})';
  }
}

/// 完整备份数据
class BackupData {
  /// 元数据
  final BackupMetadata meta;

  /// 数据内容
  final BackupContent data;

  BackupData({
    required this.meta,
    required this.data,
  });

  /// 从JSON创建
  factory BackupData.fromJson(Map<String, dynamic> json) {
    return BackupData(
      meta: BackupMetadata.fromJson(json['meta'] as Map<String, dynamic>),
      data: BackupContent.fromJson(json['data'] as Map<String, dynamic>),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'meta': meta.toJson(),
      'data': data.toJson(),
    };
  }

  /// 验证备份数据完整性
  bool get isValid {
    // 检查元数据
    if (meta.databaseVersion < 1 || meta.databaseVersion > AppConstants.databaseVersion) {
      return false;
    }

    // 检查数据统计
    if (meta.dataStats.classesCount != data.classes.length) return false;
    if (meta.dataStats.studentsCount != data.students.length) return false;
    if (meta.dataStats.notesCount != data.notes.length) return false;
    if (meta.dataStats.examsCount != data.exams.length) return false;
    if (meta.dataStats.scoresCount != data.scores.length) return false;

    return true;
  }

  /// 是否需要数据迁移
  bool get needsMigration {
    return meta.databaseVersion < AppConstants.databaseVersion;
  }

  @override
  String toString() {
    return 'BackupData(meta: $meta, data: $data)';
  }
}

/// 备份异常
class BackupException implements Exception {
  /// 错误消息
  final String message;

  /// 原始错误
  final dynamic error;

  BackupException(this.message, [this.error]);

  @override
  String toString() {
    if (error != null) {
      return 'BackupException: $message\nCaused by: $error';
    }
    return 'BackupException: $message';
  }
}
