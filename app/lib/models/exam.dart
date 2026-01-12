import 'package:teacher_tools/utils/constants.dart';

/// 考试模型
class Exam {
  final int? id;
  final int classId;
  final String name;
  final Subject subject;
  final ExamType type;
  final DateTime examDate;
  final int? examGroupId;  // 考试批次ID，同一次考试的所有科目共享此ID
  final double? averageScore;
  final double? maxScore;
  final double? minScore;
  final int? passCount;
  final int studentCount;
  final double fullScore;  // 考试满分，道德100分，其他120分
  final DateTime createdAt;
  final DateTime updatedAt;

  Exam({
    this.id,
    required this.classId,
    required this.name,
    required this.subject,
    required this.type,
    required this.examDate,
    this.examGroupId,
    this.averageScore,
    this.maxScore,
    this.minScore,
    this.passCount,
    this.studentCount = 0,
    this.fullScore = 100.0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从数据库创建实例
  factory Exam.fromMap(Map<String, dynamic> map) {
    return Exam(
      id: map['id'] as int?,
      classId: map['class_id'] as int,
      name: map['name'] as String,
      subject: Subject.fromValue(map['subject'] as String? ?? 'math'),
      type: ExamType.fromValue(map['type'] as String? ?? 'other'),
      examDate: DateTime.parse(map['exam_date'] as String),
      examGroupId: map['exam_group_id'] as int?,
      averageScore: map['average_score'] as double?,
      maxScore: map['max_score'] as double?,
      minScore: map['min_score'] as double?,
      passCount: map['pass_count'] as int?,
      studentCount: map['student_count'] as int? ?? 0,
      fullScore: map['full_score'] as double? ?? 100.0,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'class_id': classId,
      'name': name,
      'subject': subject.value,
      'type': type.value,
      'exam_date': examDate.toIso8601String(),
      if (examGroupId != null) 'exam_group_id': examGroupId,
      'average_score': averageScore,
      'max_score': maxScore,
      'min_score': minScore,
      'pass_count': passCount,
      'student_count': studentCount,
      'full_score': fullScore,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并更新部分字段
  Exam copyWith({
    int? id,
    int? classId,
    String? name,
    Subject? subject,
    ExamType? type,
    DateTime? examDate,
    int? examGroupId,
    double? averageScore,
    double? maxScore,
    double? minScore,
    int? passCount,
    int? studentCount,
    double? fullScore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Exam(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      examDate: examDate ?? this.examDate,
      examGroupId: examGroupId ?? this.examGroupId,
      averageScore: averageScore ?? this.averageScore,
      maxScore: maxScore ?? this.maxScore,
      minScore: minScore ?? this.minScore,
      passCount: passCount ?? this.passCount,
      studentCount: studentCount ?? this.studentCount,
      fullScore: fullScore ?? this.fullScore,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取科目文本
  String get subjectText => subject.label;

  /// 获取类型文本
  String get typeText => type.label;

  /// 获取显示名称
  String get displayName => '$name - $subjectText';

  /// 是否有统计数据
  bool get hasStatistics =>
      averageScore != null &&
      maxScore != null &&
      minScore != null &&
      passCount != null;

  /// 根据科目获取默认满分
  /// 道德/社会科目满分100分，其他科目满分120分
  static double getDefaultFullScore(Subject subject) {
    return subject == Subject.morality ? 100.0 : 120.0;
  }

  @override
  String toString() {
    return 'Exam{id: $id, name: $name, subject: $subject, type: $type, examDate: $examDate}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Exam && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
