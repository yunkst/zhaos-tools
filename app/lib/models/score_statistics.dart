import 'package:teacher_tools/models/score.dart';
import 'package:teacher_tools/models/exam.dart';
import 'package:teacher_tools/utils/constants.dart';

/// 学生统计概览
class StudentStatistics {
  final double averageScore; // 平均分
  final double maxScore; // 最高分
  final double minScore; // 最低分
  final double passRate; // 及格率 (60分以上)
  final double excellentRate; // 优秀率 (90分以上)
  final int totalExams; // 总考试次数
  final int? averageRanking; // 平均排名

  StudentStatistics({
    required this.averageScore,
    required this.maxScore,
    required this.minScore,
    required this.passRate,
    required this.excellentRate,
    required this.totalExams,
    this.averageRanking,
  });

  @override
  String toString() {
    return 'StudentStatistics{average: $averageScore, max: $maxScore, min: $minScore, passRate: $passRate}';
  }
}

/// 科目统计
class SubjectStatistics {
  final Subject subject;
  final double averageScore;
  final double maxScore;
  final double minScore;
  final List<Score> scores;
  final int passCount;
  final int excellentCount;

  SubjectStatistics({
    required this.subject,
    required this.averageScore,
    required this.maxScore,
    required this.minScore,
    required this.scores,
    required this.passCount,
    required this.excellentCount,
  });

  /// 及格率
  double get passRate => scores.isEmpty ? 0.0 : (passCount / scores.length) * 100;

  /// 优秀率
  double get excellentRate => scores.isEmpty ? 0.0 : (excellentCount / scores.length) * 100;
}

/// 成绩趋势
class ScoreTrend {
  final DateTime examDate;
  final String examName;
  final Subject subject;
  final double score;
  final double fullScore;
  final int? ranking;
  final double? classAverage; // 班级平均分

  ScoreTrend({
    required this.examDate,
    required this.examName,
    required this.subject,
    required this.score,
    required this.fullScore,
    this.ranking,
    this.classAverage,
  });

  /// 获取百分比
  double get percentage {
    if (fullScore == 0) return 0.0;
    return (score / fullScore) * 100;
  }

  /// 是否及格
  bool get isPass => percentage >= 60;

  @override
  String toString() {
    return 'ScoreTrend{exam: $examName, score: $score, ranking: $ranking}';
  }
}

/// 排名分布
class RankingDistribution {
  final String range; // "前10名", "前20名", etc.
  final int count;

  RankingDistribution({
    required this.range,
    required this.count,
  });

  @override
  String toString() => 'RankingDistribution{range: $range, count: $count}';
}

/// 等级分布
class GradeDistribution {
  final String grade; // "优秀(90-100)", "良好(80-89)", etc.
  final int count;
  final int colorValue; // 使用ARGB整数值存储颜色

  GradeDistribution({
    required this.grade,
    required this.count,
    required this.colorValue,
  });
}

/// 辅助模型: 成绩 + 考试信息
class ScoreWithExam {
  final Score score;
  final Exam exam;

  ScoreWithExam({
    required this.score,
    required this.exam,
  });

  /// 从数据库Map创建(包含JOIN查询结果)
  factory ScoreWithExam.fromMap(Map<String, dynamic> map) {
    final score = Score(
      id: map['score_id'] as int?,
      examId: map['exam_id'] as int,
      studentId: map['student_id'] as int,
      classId: map['class_id'] as int,
      score: map['score'] as double,
      fullScore: map['full_score'] as double? ?? 100.0,
      ranking: map['ranking'] as int?,
      remarks: map['remarks'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );

    final exam = Exam(
      id: map['exam_id'] as int?,
      classId: map['exam_class_id'] as int? ?? score.classId,
      name: map['exam_name'] as String? ?? '',
      subject: Subject.fromValue(map['subject'] as String? ?? 'math'),
      type: ExamType.fromValue(map['type'] as String? ?? 'other'),
      examDate: map['exam_date'] != null
          ? DateTime.parse(map['exam_date'] as String)
          : DateTime.now(),
      examGroupId: map['exam_group_id'] as int?,
      averageScore: map['exam_average_score'] as double?,
      maxScore: map['exam_max_score'] as double?,
      minScore: map['exam_min_score'] as double?,
      passCount: map['exam_pass_count'] as int?,
      studentCount: map['exam_student_count'] as int? ?? 0,
    );

    return ScoreWithExam(score: score, exam: exam);
  }

  /// 从独立的Score和Exam创建
  factory ScoreWithExam.fromScoreAndExam(Score score, Exam exam) {
    return ScoreWithExam(score: score, exam: exam);
  }

  @override
  String toString() {
    return 'ScoreWithExam{exam: ${exam.name}, score: ${score.score}}';
  }
}
