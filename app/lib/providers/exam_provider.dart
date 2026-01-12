import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:teacher_tools/models/exam.dart';
import 'package:teacher_tools/models/exam_group.dart';
import 'package:teacher_tools/models/score.dart';
import 'package:teacher_tools/database/exam_dao.dart';
import 'package:teacher_tools/database/score_dao.dart';
import 'package:teacher_tools/database/student_dao.dart';
import 'package:teacher_tools/utils/excel_importer.dart';
import 'package:teacher_tools/utils/constants.dart';

/// 考试状态管理Provider
class ExamProvider with ChangeNotifier {
  final ExamDAO _examDAO = ExamDAO();
  final ScoreDAO _scoreDAO = ScoreDAO();
  final StudentDAO _studentDAO = StudentDAO();

  // 考试列表
  List<Exam> _exams = [];
  List<Exam> get exams => _exams;

  // 考试组列表
  List<ExamGroup> _examGroups = [];
  List<ExamGroup> get examGroups => _examGroups;

  // 科目筛选
  String? _subjectFilter;
  String? get subjectFilter => _subjectFilter;

  // 加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 加载班级考试
  Future<void> loadExams(int classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _exams = await _examDAO.getByClassId(classId);
    } catch (e) {
      debugPrint('Error loading exams: $e');
      _exams = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 加载最近考试
  Future<List<Exam>> loadRecentExams(int classId) async {
    try {
      return await _examDAO.getRecentExams(classId, limit: 5);
    } catch (e) {
      debugPrint('Error loading recent exams: $e');
      return [];
    }
  }

  /// 设置科目筛选
  void setSubjectFilter(String? subject) {
    _subjectFilter = subject;
    notifyListeners();
  }

  /// 获取筛选后的考试
  List<Exam> get filteredExams {
    if (_subjectFilter == null) {
      return _exams;
    }
    return _exams.where((e) => e.subject.value == _subjectFilter).toList();
  }

  /// 删除考试
  Future<bool> deleteExam(int id) async {
    try {
      await _examDAO.delete(id);
      _exams.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting exam: $e');
      return false;
    }
  }

  /// 加载班级的考试组
  Future<void> loadExamGroups(int classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      final groupMaps = await _examDAO.getExamGroups(classId);
      final List<ExamGroup> groups = [];

      for (var groupMap in groupMaps) {
        final examGroupId = groupMap['exam_group_id'] as int;
        final subjects = await _examDAO.getByExamGroupId(examGroupId);

        final group = ExamGroup(
          examGroupId: examGroupId,
          name: groupMap['name'] as String,
          examDate: DateTime.parse(groupMap['exam_date'] as String),
          type: ExamType.fromValue(groupMap['type'] as String? ?? 'other'),
          subjects: subjects,
          classId: groupMap['class_id'] as int,
          totalStudents: groupMap['total_students'] as int? ?? 0,
        );

        groups.add(group);
      }

      _examGroups = groups;
    } catch (e) {
      debugPrint('Error loading exam groups: $e');
      _examGroups = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 获取考试组详情
  Future<ExamGroup?> getExamGroupDetail(int examGroupId) async {
    try {
      final subjects = await _examDAO.getByExamGroupId(examGroupId);

      if (subjects.isEmpty) return null;

      final firstExam = subjects.first;

      return ExamGroup(
        examGroupId: examGroupId,
        name: firstExam.name,
        examDate: firstExam.examDate,
        type: firstExam.type,
        subjects: subjects,
        classId: firstExam.classId,
        totalStudents: firstExam.studentCount,
      );
    } catch (e) {
      debugPrint('Error getting exam group detail: $e');
      return null;
    }
  }

  /// 删除考试组
  Future<bool> deleteExamGroup(int examGroupId) async {
    try {
      await _examDAO.deleteByExamGroupId(examGroupId);
      _examGroups.removeWhere((g) => g.examGroupId == examGroupId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting exam group: $e');
      return false;
    }
  }

  /// 获取考试详情（包含成绩列表）
  Future<Map<String, dynamic>?> getExamDetail(int examId) async {
    try {
      final exam = await _examDAO.getById(examId);
      if (exam == null) return null;

      final scores = await _scoreDAO.getByExamId(examId);

      return {
        'exam': exam,
        'scores': scores,
      };
    } catch (e) {
      debugPrint('Error getting exam detail: $e');
      return null;
    }
  }

  /// 批量导入成绩
  Future<Map<String, int>> importScores(int examId, List<Score> scores) async {
    int successCount = 0;
    int failCount = 0;

    try {
      for (var score in scores) {
        // 检查成绩是否已存在
        final exists = await _scoreDAO.isScoreExists(
          score.examId,
          score.studentId,
        );

        if (!exists) {
          await _scoreDAO.insert(score);
          successCount++;
        } else {
          failCount++;
        }
      }

      // 更新排名
      await _scoreDAO.updateRanking(examId);

      // 更新考试统计信息
      await _updateExamStatistics(examId);

      return {
        'success': successCount,
        'fail': failCount,
      };
    } catch (e) {
      debugPrint('Error importing scores: $e');
      return {
        'success': successCount,
        'fail': failCount,
      };
    }
  }

  /// 更新考试统计信息
  Future<void> _updateExamStatistics(int examId) async {
    try {
      final scores = await _scoreDAO.getByExamId(examId);

      if (scores.isEmpty) return;

      double totalScore = 0;
      double maxScore = scores.first.score;
      double minScore = scores.first.score;
      int passCount = 0;

      for (var score in scores) {
        totalScore += score.score;
        if (score.score > maxScore) maxScore = score.score;
        if (score.score < minScore) minScore = score.score;
        if (score.isPass) passCount++;
      }

      final exam = await _examDAO.getById(examId);
      if (exam != null) {
        await _examDAO.update(
          exam.copyWith(
            averageScore: totalScore / scores.length,
            maxScore: maxScore,
            minScore: minScore,
            passCount: passCount,
            studentCount: scores.length,
          ),
        );
      }
    } catch (e) {
      debugPrint('Error updating exam statistics: $e');
    }
  }

  /// 从Excel批量导入成绩（新增模式）
  /// 返回导入结果：{success: 成功数, failed: 失败数, errors: 错误列表}
  Future<Map<String, dynamic>> importScoresFromExcel({
    required File excelFile,
    required int classId,
    required String examName,
    ExamType examType = ExamType.other,
    DateTime? examDate,
  }) async {
    int successCount = 0;
    int failedCount = 0;
    final List<String> errors = [];

    try {
      debugPrint('📊 开始从Excel导入成绩...');

      // 1. 生成统一的考试批次ID（所有科目共享）
      final examGroupId = DateTime.now().millisecondsSinceEpoch;
      debugPrint('🆔 生成考试批次ID: $examGroupId');

      // 2. 统一考试日期（避免跨天问题）
      final finalExamDate = examDate ?? DateTime.now();
      debugPrint('📅 考试日期: ${finalExamDate.toIso8601String()}');

      // 3. 解析Excel文件
      final excelData = await ExcelImporter.parseScoreExcel(excelFile);
      if (excelData == null || excelData.isEmpty) {
        return {
          'success': 0,
          'failed': 0,
          'errors': ['Excel文件解析失败或为空'],
        };
      }

      // 4. 从"总"sheet中提取总分校排名，建立学号->排名的映射
      final Map<String, int> schoolRankingMap = {};
      final totalScores = excelData['total'];
      if (totalScores != null && totalScores.isNotEmpty) {
        for (var scoreData in totalScores) {
          final studentNumber = scoreData['学号'];
          final ranking = scoreData['名次'];
          if (studentNumber != null && ranking != null) {
            schoolRankingMap[studentNumber.toString()] = ranking is int
                ? ranking
                : int.tryParse(ranking.toString()) ?? 0;
          }
        }
        debugPrint('✅ 从总分表提取了 ${schoolRankingMap.length} 个学生的总分校排名');
      } else {
        debugPrint('⚠️ 未找到总分表数据，总分校排名将为空');
      }

      // 5. 科目映射
      final subjectMapping = {
        'chinese': Subject.chinese,
        'math': Subject.math,
        'english': Subject.english,
        'science': Subject.science,
        'morality': Subject.morality, // Excel中的"社"映射到道德
      };

      // 6. 为每个科目创建考试并导入成绩
      for (var entry in subjectMapping.entries) {
        final sheetKey = entry.key;
        final subject = entry.value;
        final scores = excelData[sheetKey];

        if (scores == null || scores.isEmpty) {
          debugPrint('⚠️ 科目 $sheetKey 没有数据，跳过');
          continue;
        }

        debugPrint('📝 开始处理科目: ${subject.label}');

        // 创建考试记录（使用统一的 exam_group_id）
        final exam = Exam(
          classId: classId,
          name: examName,
          subject: subject,
          type: examType,
          examDate: finalExamDate,
          examGroupId: examGroupId,  // 关键：使用统一的批次ID
          fullScore: Exam.getDefaultFullScore(subject),  // 根据科目设置满分
        );

        final examId = await _examDAO.insert(exam);
        debugPrint('✅ 创建考试记录: ID=$examId, 科目=${subject.label}, 批次ID=$examGroupId');

        // 导入该科目的成绩
        for (var scoreData in scores) {
          try {
            final studentNumber = scoreData['学号'];
            if (studentNumber == null) {
              errors.add('${subject.label}: 学号缺失');
              failedCount++;
              continue;
            }

            // 按学号查找学生
            final student = await _studentDAO.getByStudentNumber(
              classId,
              studentNumber.toString(),
            );

            if (student == null) {
              final errorMsg = '${subject.label}: 学号 $studentNumber 不存在';
              errors.add(errorMsg);
              failedCount++;
              debugPrint('❌ $errorMsg');
              continue;
            }

            final scoreValue = scoreData['总分'] ?? 0.0;
            final ranking = scoreData['名次'];
            final schoolRanking = schoolRankingMap[studentNumber.toString()];

            // 创建成绩记录
            final score = Score(
              examId: examId,
              studentId: student.id!,
              classId: classId,
              score: double.tryParse(scoreValue.toString()) ?? 0.0,
              fullScore: exam.fullScore,  // 使用考试的满分
              ranking: ranking is int ? ranking : int.tryParse(ranking?.toString() ?? ''),
              schoolRanking: schoolRanking,
            );

            await _scoreDAO.insert(score);
            successCount++;
            debugPrint('✅ 导入成功: ${student.name} - $scoreValue 分 (总排名:$schoolRanking)');

          } catch (e) {
            final errorMsg = '${subject.label}: ${scoreData['姓名']} 导入失败 - $e';
            errors.add(errorMsg);
            failedCount++;
            debugPrint('❌ $errorMsg');
          }
        }

        // 更新考试统计信息
        await _updateExamStatistics(examId);
      }

      // 刷新考试列表
      await loadExams(classId);

      debugPrint('🎉 成绩导入完成! 成功: $successCount, 失败: $failedCount');

      return {
        'success': successCount,
        'failed': failedCount,
        'errors': errors,
      };

    } catch (e, stackTrace) {
      debugPrint('❌ 导入成绩时发生错误: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return {
        'success': successCount,
        'failed': failedCount,
        'errors': ['导入过程发生异常: $e'],
      };
    }
  }

  /// 从Excel更新已有考试的成绩
  /// 返回导入结果：{success: 成功数, failed: 失败数, errors: 错误列表}
  Future<Map<String, dynamic>> updateScoresFromExcel({
    required File excelFile,
    required int classId,
    required int examId,
  }) async {
    int successCount = 0;
    int failedCount = 0;
    final List<String> errors = [];

    try {
      debugPrint('📊 开始从Excel更新成绩, 考试ID: $examId');

      // 获取考试信息
      final exam = await _examDAO.getById(examId);
      if (exam == null) {
        return {
          'success': 0,
          'failed': 0,
          'errors': ['考试不存在，ID: $examId'],
        };
      }

      // 解析Excel文件
      final excelData = await ExcelImporter.parseScoreExcel(excelFile);
      if (excelData == null || excelData.isEmpty) {
        return {
          'success': 0,
          'failed': 0,
          'errors': ['Excel文件解析失败或为空'],
        };
      }

      // 科目映射
      final subjectMapping = {
        'chinese': Subject.chinese,
        'math': Subject.math,
        'english': Subject.english,
        'science': Subject.science,
        'morality': Subject.morality, // Excel中的"社"映射到道德
      };

      // 从"总"sheet中提取总分校排名，建立学号->排名的映射
      final Map<String, int> schoolRankingMap = {};
      final totalScores = excelData['total'];
      if (totalScores != null && totalScores.isNotEmpty) {
        for (var scoreData in totalScores) {
          final studentNumber = scoreData['学号'];
          final ranking = scoreData['名次'];
          if (studentNumber != null && ranking != null) {
            schoolRankingMap[studentNumber.toString()] = ranking is int
                ? ranking
                : int.tryParse(ranking.toString()) ?? 0;
          }
        }
        debugPrint('✅ 从总分表提取了 ${schoolRankingMap.length} 个学生的总分校排名');
      }

      // 找到对应的科目数据
      final sheetKey = subjectMapping.entries
          .firstWhere(
            (e) => e.value == exam.subject,
            orElse: () => subjectMapping.entries.first,
          )
          .key;

      final scores = excelData[sheetKey];
      if (scores == null || scores.isEmpty) {
        return {
          'success': 0,
          'failed': 0,
          'errors': ['Excel中没有找到科目 ${exam.subject.label} 的数据'],
        };
      }

      debugPrint('📝 开始更新科目: ${exam.subject.label}');

      // 先删除该考试的所有成绩
      await _scoreDAO.deleteByExamId(examId);
      debugPrint('🗑️ 已清除该考试的原有成绩');

      // 导入新成绩
      for (var scoreData in scores) {
        try {
          final studentNumber = scoreData['学号'];
          if (studentNumber == null) {
            errors.add('学号缺失');
            failedCount++;
            continue;
          }

          // 按学号查找学生
          final student = await _studentDAO.getByStudentNumber(
            classId,
            studentNumber.toString(),
          );

          if (student == null) {
            final errorMsg = '学号 $studentNumber 不存在';
            errors.add(errorMsg);
            failedCount++;
            debugPrint('❌ $errorMsg');
            continue;
          }

          final scoreValue = scoreData['总分'] ?? 0.0;
          final ranking = scoreData['名次'];
          final schoolRanking = schoolRankingMap[studentNumber.toString()];

          // 创建成绩记录
          final score = Score(
            examId: examId,
            studentId: student.id!,
            classId: classId,
            score: double.tryParse(scoreValue.toString()) ?? 0.0,
            fullScore: exam.fullScore,  // 使用考试的满分
            ranking: ranking is int ? ranking : int.tryParse(ranking?.toString() ?? ''),
            schoolRanking: schoolRanking,
          );

          await _scoreDAO.insert(score);
          successCount++;
          debugPrint('✅ 更新成功: ${student.name} - $scoreValue 分 (总排名:$schoolRanking)');

        } catch (e) {
          final errorMsg = '${scoreData['姓名']} 更新失败 - $e';
          errors.add(errorMsg);
          failedCount++;
          debugPrint('❌ $errorMsg');
        }
      }

      // 更新考试统计信息
      await _updateExamStatistics(examId);

      // 刷新考试列表
      await loadExams(classId);

      debugPrint('🎉 成绩更新完成! 成功: $successCount, 失败: $failedCount');

      return {
        'success': successCount,
        'failed': failedCount,
        'errors': errors,
      };

    } catch (e, stackTrace) {
      debugPrint('❌ 更新成绩时发生错误: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return {
        'success': successCount,
        'failed': failedCount,
        'errors': ['更新过程发生异常: $e'],
      };
    }
  }
}
