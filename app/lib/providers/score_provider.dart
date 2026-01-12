import 'package:flutter/foundation.dart';
import 'package:teacher_tools/models/score_statistics.dart';
import 'package:teacher_tools/services/score_statistics_service.dart';
import 'package:teacher_tools/utils/constants.dart';

/// 成绩Provider
class ScoreProvider extends ChangeNotifier {
  final ScoreStatisticsService _statisticsService = ScoreStatisticsService();

  // 缓存数据
  StudentStatistics? _statistics;
  List<ScoreWithExam>? _scoresWithExam;
  List<ScoreTrend>? _trends;
  List<SubjectStatistics>? _subjectStatistics;
  List<RankingDistribution>? _rankingDistribution;
  List<GradeDistribution>? _gradeDistribution;

  // 加载状态
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  StudentStatistics? get statistics => _statistics;
  List<ScoreWithExam>? get scoresWithExam => _scoresWithExam;
  List<ScoreTrend>? get trends => _trends;
  List<SubjectStatistics>? get subjectStatistics => _subjectStatistics;
  List<RankingDistribution>? get rankingDistribution => _rankingDistribution;
  List<GradeDistribution>? get gradeDistribution => _gradeDistribution;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// 获取学生统计概览
  Future<StudentStatistics> getStatistics(int studentId) async {
    _setLoading(true);
    try {
      final stats = await _statisticsService.getStudentStatistics(studentId);
      _statistics = stats;
      notifyListeners();
      return stats;
    } catch (e) {
      _setError('获取统计数据失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 获取成绩列表
  Future<List<ScoreWithExam>> getScoresWithExam(int studentId) async {
    _setLoading(true);
    try {
      final scores = await _statisticsService.getScoresWithExamInfo(studentId);
      _scoresWithExam = scores;
      notifyListeners();
      return scores;
    } catch (e) {
      _setError('获取成绩列表失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 获取趋势
  Future<List<ScoreTrend>> getTrends(int studentId, {Subject? subject}) async {
    _setLoading(true);
    try {
      final trends = await _statisticsService.getScoreTrends(studentId, subject: subject);
      _trends = trends;
      notifyListeners();
      return trends;
    } catch (e) {
      _setError('获取趋势数据失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 获取科目统计
  Future<List<SubjectStatistics>> getSubjectStatistics(int studentId) async {
    _setLoading(true);
    try {
      final stats = await _statisticsService.getSubjectStatistics(studentId);
      _subjectStatistics = stats;
      notifyListeners();
      return stats;
    } catch (e) {
      _setError('获取科目统计失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 获取排名分布
  Future<List<RankingDistribution>> getRankingDistribution(int studentId) async {
    _setLoading(true);
    try {
      final distribution = await _statisticsService.getRankingDistribution(studentId);
      _rankingDistribution = distribution;
      notifyListeners();
      return distribution;
    } catch (e) {
      _setError('获取排名分布失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 获取等级分布
  Future<List<GradeDistribution>> getGradeDistribution(int studentId) async {
    _setLoading(true);
    try {
      final distribution = await _statisticsService.getGradeDistribution(studentId);
      _gradeDistribution = distribution;
      notifyListeners();
      return distribution;
    } catch (e) {
      _setError('获取等级分布失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 加载所有数据
  Future<void> loadAllData(int studentId) async {
    _setLoading(true);
    try {
      await Future.wait([
        getStatistics(studentId),
        getScoresWithExam(studentId),
        getSubjectStatistics(studentId),
        getRankingDistribution(studentId),
        getGradeDistribution(studentId),
        getTrends(studentId),
      ]);
    } catch (e) {
      _setError('加载数据失败: $e');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  /// 筛选成绩列表
  List<ScoreWithExam> filterScores({
    List<ScoreWithExam>? scores,
    Subject? subject,
    ExamType? examType,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final sourceScores = scores ?? _scoresWithExam;
    if (sourceScores == null) return [];

    var filtered = sourceScores;

    // 按科目筛选
    if (subject != null) {
      filtered = filtered.where((s) => s.exam.subject == subject).toList();
    }

    // 按考试类型筛选
    if (examType != null) {
      filtered = filtered.where((s) => s.exam.type == examType).toList();
    }

    // 按开始日期筛选
    if (startDate != null) {
      filtered = filtered.where((s) => s.exam.examDate.isAfter(startDate) || s.exam.examDate.isAtSameMomentAs(startDate)).toList();
    }

    // 按结束日期筛选
    if (endDate != null) {
      filtered = filtered.where((s) => s.exam.examDate.isBefore(endDate) || s.exam.examDate.isAtSameMomentAs(endDate)).toList();
    }

    return filtered;
  }

  /// 清除缓存
  void clearCache() {
    _statistics = null;
    _scoresWithExam = null;
    _trends = null;
    _subjectStatistics = null;
    _rankingDistribution = null;
    _gradeDistribution = null;
    _errorMessage = null;
    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }
}
