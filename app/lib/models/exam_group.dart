import 'package:teacher_tools/models/exam.dart';
import 'package:teacher_tools/utils/constants.dart';

/// 考试组模型
///
/// 用于管理同一次考试的多个科目
/// 例如：期中考试包含语文、数学、英语、科学、道德5个科目
class ExamGroup {
  final int examGroupId;
  final String name;
  final DateTime examDate;
  final ExamType type;
  final List<Exam> subjects;  // 该组包含的所有科目考试
  final int classId;
  final int totalStudents;   // 参考总人数

  ExamGroup({
    required this.examGroupId,
    required this.name,
    required this.examDate,
    required this.type,
    required this.subjects,
    required this.classId,
    required this.totalStudents,
  });

  /// 获取科目数量
  int get subjectCount => subjects.length;

  /// 是否有统计数据
  bool get hasStatistics => subjects.any((e) => e.hasStatistics);

  /// 计算整体平均分（所有科目平均分的平均值）
  double? get overallAverage {
    if (subjects.isEmpty) return null;

    final validAverages = subjects
        .map((e) => e.averageScore)
        .where((score) => score != null)
        .toList();

    if (validAverages.isEmpty) return null;

    return validAverages.reduce((a, b) => a! + b!)! / validAverages.length;
  }

  /// 获取最高平均分的科目
  Exam? get bestSubject {
    if (subjects.isEmpty) return null;
    return subjects.reduce((a, b) =>
      (a.averageScore ?? 0) > (b.averageScore ?? 0) ? a : b
    );
  }

  /// 获取最低平均分的科目
  Exam? get worstSubject {
    if (subjects.isEmpty) return null;
    return subjects.reduce((a, b) =>
      (a.averageScore ?? double.infinity) < (b.averageScore ?? double.infinity) ? a : b
    );
  }

  /// 获取所有科目及格率
  double? get overallPassRate {
    if (subjects.isEmpty) return null;

    final totalPass = subjects.fold<int>(0, (sum, e) => sum + (e.passCount ?? 0));
    final totalCount = subjects.fold<int>(0, (sum, e) => sum + e.studentCount);

    if (totalCount == 0) return null;
    return (totalPass / totalCount * 100);
  }

  /// 获取显示名称
  String get displayName => name;

  /// 获取类型文本
  String get typeText => type.label;

  /// 获取格式化的日期
  String get formattedDate {
    return '${examDate.year}-${examDate.month.toString().padLeft(2, '0')}-${examDate.day.toString().padLeft(2, '0')}';
  }

  @override
  String toString() {
    return 'ExamGroup{id: $examGroupId, name: $name, subjects: $subjectCount, date: $formattedDate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ExamGroup && other.examGroupId == examGroupId;
  }

  @override
  int get hashCode => examGroupId.hashCode;
}
