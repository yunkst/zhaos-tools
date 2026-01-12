/// 成绩模型
class Score {
  final int? id;
  final int examId;
  final int studentId;
  final int classId;
  final double score;
  final double fullScore;
  final int? ranking;
  final int? schoolRanking;
  final String? remarks;
  final DateTime createdAt;
  final DateTime updatedAt;

  Score({
    this.id,
    required this.examId,
    required this.studentId,
    required this.classId,
    required this.score,
    double? fullScore,
    this.ranking,
    this.schoolRanking,
    this.remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : fullScore = fullScore ?? 100.0,
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从数据库创建实例
  factory Score.fromMap(Map<String, dynamic> map) {
    return Score(
      id: map['id'] as int?,
      examId: map['exam_id'] as int,
      studentId: map['student_id'] as int,
      classId: map['class_id'] as int,
      score: map['score'] as double,
      fullScore: map['full_score'] as double? ?? 100.0,
      ranking: map['ranking'] as int?,
      schoolRanking: map['school_ranking'] as int?,
      remarks: map['remarks'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'exam_id': examId,
      'student_id': studentId,
      'class_id': classId,
      'score': score,
      'full_score': fullScore,
      'ranking': ranking,
      'school_ranking': schoolRanking,
      'remarks': remarks,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// 复制并更新部分字段
  Score copyWith({
    int? id,
    int? examId,
    int? studentId,
    int? classId,
    double? score,
    double? fullScore,
    int? ranking,
    int? schoolRanking,
    String? remarks,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Score(
      id: id ?? this.id,
      examId: examId ?? this.examId,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      score: score ?? this.score,
      fullScore: fullScore ?? this.fullScore,
      ranking: ranking ?? this.ranking,
      schoolRanking: schoolRanking ?? this.schoolRanking,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// 获取百分比
  double get percentage {
    if (fullScore == 0) return 0.0;
    return (score / fullScore) * 100;
  }

  /// 是否及格（默认60分）
  bool get isPass => percentage >= 60;

  /// 是否优秀（默认90分以上）
  bool get isExcellent => percentage >= 90;

  @override
  String toString() {
    return 'Score{id: $id, examId: $examId, studentId: $studentId, score: $score}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Score && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
