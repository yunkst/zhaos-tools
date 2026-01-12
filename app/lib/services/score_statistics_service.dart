import 'package:teacher_tools/database/score_dao.dart';
import 'package:teacher_tools/database/exam_dao.dart';
import 'package:teacher_tools/models/score_statistics.dart';
// ignore: unused_import
import 'package:teacher_tools/models/exam.dart';
import 'package:teacher_tools/models/score.dart';
import 'package:teacher_tools/utils/constants.dart';

/// 成绩统计服务
class ScoreStatisticsService {
  final ScoreDAO _scoreDao = ScoreDAO();
  final ExamDAO _examDao = ExamDAO();

  /// 获取学生统计概览
  Future<StudentStatistics> getStudentStatistics(int studentId) async {
    final scores = await _scoreDao.getByStudentId(studentId);

    if (scores.isEmpty) {
      return StudentStatistics(
        averageScore: 0.0,
        maxScore: 0.0,
        minScore: 0.0,
        passRate: 0.0,
        excellentRate: 0.0,
        totalExams: 0,
      );
    }

    // 使用百分比计算基础统计（确保跨科目可比性）
    final percentages = scores.map((s) => s.percentage).toList();
    final totalPercentage = percentages.fold<double>(0.0, (sum, p) => sum + p);
    final averageScore = totalPercentage / percentages.length;
    final maxScore = percentages.reduce((a, b) => a > b ? a : b);
    final minScore = percentages.reduce((a, b) => a < b ? a : b);

    // 计算及格率和优秀率
    final passCount = scores.where((s) => s.isPass).length;
    final excellentCount = scores.where((s) => s.isExcellent).length;
    final passRate = (passCount / scores.length) * 100;
    final excellentRate = (excellentCount / scores.length) * 100;

    // 计算平均排名
    final rankings = scores.where((s) => s.ranking != null).map((s) => s.ranking!);
    final averageRanking = rankings.isNotEmpty
        ? (rankings.reduce((a, b) => a + b) / rankings.length).round()
        : null;

    return StudentStatistics(
      averageScore: averageScore,
      maxScore: maxScore,
      minScore: minScore,
      passRate: passRate,
      excellentRate: excellentRate,
      totalExams: scores.length,
      averageRanking: averageRanking,
    );
  }

  /// 获取科目统计
  Future<List<SubjectStatistics>> getSubjectStatistics(int studentId) async {
    final scores = await _scoreDao.getByStudentId(studentId);

    // 按科目分组
    final Map<int, List<Score>> scoresByExamId = {};
    for (var score in scores) {
      scoresByExamId.putIfAbsent(score.examId, () => []).add(score);
    }

    // 获取考试信息
    final Map<Subject, List<Score>> scoresBySubject = {};
    for (var entry in scoresByExamId.entries) {
      final exam = await _examDao.getById(entry.key);
      if (exam != null) {
        scoresBySubject.putIfAbsent(exam.subject, () => []).addAll(entry.value);
      }
    }

    // 构建科目统计（使用百分比计算）
    final statistics = <SubjectStatistics>[];
    for (var entry in scoresBySubject.entries) {
      final subjectScores = entry.value;

      // 使用百分比计算，确保跨满分可比性
      final percentages = subjectScores.map((s) => s.percentage).toList();
      final averageScore = percentages.reduce((a, b) => a + b) / percentages.length;
      final maxScore = percentages.reduce((a, b) => a > b ? a : b);
      final minScore = percentages.reduce((a, b) => a < b ? a : b);

      final passCount = subjectScores.where((s) => s.isPass).length;
      final excellentCount = subjectScores.where((s) => s.isExcellent).length;

      statistics.add(SubjectStatistics(
        subject: entry.key,
        averageScore: averageScore,
        maxScore: maxScore,
        minScore: minScore,
        scores: subjectScores,
        passCount: passCount,
        excellentCount: excellentCount,
      ));
    }

    // 按平均分排序
    statistics.sort((a, b) => b.averageScore.compareTo(a.averageScore));
    return statistics;
  }

  /// 获取成绩趋势(按时间排序)
  Future<List<ScoreTrend>> getScoreTrends(int studentId, {Subject? subject}) async {
    final scores = await _scoreDao.getByStudentId(studentId);

    List<ScoreTrend> trends = [];

    for (var score in scores) {
      final exam = await _examDao.getById(score.examId);
      if (exam == null) continue;

      // 如果指定了科目筛选
      if (subject != null && exam.subject != subject) continue;

      trends.add(ScoreTrend(
        examDate: exam.examDate,
        examName: exam.name,
        subject: exam.subject,
        score: score.score,
        fullScore: score.fullScore,
        ranking: score.ranking,
        classAverage: exam.averageScore,
      ));
    }

    // 按时间排序
    trends.sort((a, b) => a.examDate.compareTo(b.examDate));
    return trends;
  }

  /// 获取排名分布
  Future<List<RankingDistribution>> getRankingDistribution(int studentId) async {
    final scores = await _scoreDao.getByStudentId(studentId);
    final rankings = scores.where((s) => s.ranking != null).map((s) => s.ranking!);

    if (rankings.isEmpty) {
      return [];
    }

    // 定义排名区间
    final distributions = <RankingDistribution>[
      RankingDistribution(range: '前10名', count: 0),
      RankingDistribution(range: '11-20名', count: 0),
      RankingDistribution(range: '21-30名', count: 0),
      RankingDistribution(range: '31-40名', count: 0),
      RankingDistribution(range: '40名以后', count: 0),
    ];

    // 统计各区间数量
    for (var ranking in rankings) {
      if (ranking <= 10) {
        distributions[0] = RankingDistribution(range: '前10名', count: distributions[0].count + 1);
      } else if (ranking <= 20) {
        distributions[1] = RankingDistribution(range: '11-20名', count: distributions[1].count + 1);
      } else if (ranking <= 30) {
        distributions[2] = RankingDistribution(range: '21-30名', count: distributions[2].count + 1);
      } else if (ranking <= 40) {
        distributions[3] = RankingDistribution(range: '31-40名', count: distributions[3].count + 1);
      } else {
        distributions[4] = RankingDistribution(range: '40名以后', count: distributions[4].count + 1);
      }
    }

    // 移除空区间
    return distributions.where((d) => d.count > 0).toList();
  }

  /// 获取等级分布
  Future<List<GradeDistribution>> getGradeDistribution(int studentId) async {
    final scores = await _scoreDao.getByStudentId(studentId);

    if (scores.isEmpty) {
      return [];
    }

    int excellent = 0; // 90-100
    int good = 0; // 80-89
    int pass = 0; // 60-79
    int fail = 0; // 0-59

    for (var score in scores) {
      final percentage = score.percentage;
      if (percentage >= 90) {
        excellent++;
      } else if (percentage >= 80) {
        good++;
      } else if (percentage >= 60) {
        pass++;
      } else {
        fail++;
      }
    }

    return [
      GradeDistribution(grade: '优秀(90-100)', count: excellent, colorValue: 0xFF4CAF50),
      GradeDistribution(grade: '良好(80-89)', count: good, colorValue: 0xFF2196F3),
      GradeDistribution(grade: '及格(60-79)', count: pass, colorValue: 0xFFFF9800),
      GradeDistribution(grade: '不及格(0-59)', count: fail, colorValue: 0xFFF44336),
    ].where((g) => g.count > 0).toList();
  }

  /// 获取带考试信息的成绩列表
  Future<List<ScoreWithExam>> getScoresWithExamInfo(int studentId) async {
    final scores = await _scoreDao.getByStudentId(studentId);
    final List<ScoreWithExam> result = [];

    for (var score in scores) {
      final exam = await _examDao.getById(score.examId);
      if (exam != null) {
        result.add(ScoreWithExam.fromScoreAndExam(score, exam));
      }
    }

    // 按考试日期排序
    result.sort((a, b) => b.exam.examDate.compareTo(a.exam.examDate));
    return result;
  }

  /// 获取学生在某次考试的班级平均分对比
  Future<double?> getClassAverage(int examId) async {
    final exam = await _examDao.getById(examId);
    return exam?.averageScore;
  }
}
