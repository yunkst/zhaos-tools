import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/models/exam.dart';
import 'package:teacher_tools/models/score.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/providers/exam_provider.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:intl/intl.dart';

/// 成绩查看页
class ExamDetailScreen extends StatefulWidget {
  final int examId;

  const ExamDetailScreen({super.key, required this.examId});

  @override
  State<ExamDetailScreen> createState() => _ExamDetailScreenState();
}

class _ExamDetailScreenState extends State<ExamDetailScreen> {
  Exam? _exam;
  List<Score> _scores = [];
  bool _isLoading = true;
  ScoreSortType _sortType = ScoreSortType.schoolRanking;
  final Map<int, Student> _studentsCache = {}; // studentId -> Student

  @override
  void initState() {
    super.initState();
    // 延迟加载数据,避免在 build 期间触发 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    final examProvider = context.read<ExamProvider>();
    final data = await examProvider.getExamDetail(widget.examId);

    if (data != null && mounted) {
      _exam = data['exam'] as Exam;
      _scores = data['scores'] as List<Score>;

      // 加载学生信息
      await _loadStudents();

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } else if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadStudents() async {
    final studentProvider = context.read<StudentProvider>();
    await studentProvider.loadStudents(_exam!.classId);

    // 缓存学生信息
    for (var student in studentProvider.students) {
      _studentsCache[student.id!] = student;
    }

    debugPrint('✅ 加载了 ${_studentsCache.length} 个学生信息');
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('成绩详情'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_exam == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('成绩详情'),
        ),
        body: const Center(
          child: Text('考试不存在'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('成绩详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editExam,
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportToExcel,
          ),
          PopupMenuButton<ScoreSortType>(
            icon: const Icon(Icons.sort),
            onSelected: (type) {
              setState(() {
                _sortType = type;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: ScoreSortType.schoolRanking,
                child: Text('按总分校排名排序'),
              ),
              const PopupMenuItem(
                value: ScoreSortType.scoreDesc,
                child: Text('按成绩降序'),
              ),
              const PopupMenuItem(
                value: ScoreSortType.scoreAsc,
                child: Text('按成绩升序'),
              ),
              const PopupMenuItem(
                value: ScoreSortType.studentNumber,
                child: Text('按学号排序'),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildExamInfoCard(),
            const SizedBox(height: 16),
            if (_exam!.hasStatistics)
              _buildStatisticsCard()
            else
              _buildNoDataCard(),
            const SizedBox(height: 16),
            _buildScoresSection(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addScore,
        icon: const Icon(Icons.add),
        label: const Text('添加成绩'),
      ),
    );
  }

  Widget _buildExamInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getSubjectColor(_exam!.subject.value),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _exam!.subjectText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _exam!.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18),
                const SizedBox(width: 8),
                Text(
                  DateFormat('yyyy年MM月dd日').format(_exam!.examDate),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
                const SizedBox(width: 24),
                const Icon(Icons.label, size: 18),
                const SizedBox(width: 8),
                Text(
                  _exam!.typeText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    final passRate = _exam!.studentCount > 0
        ? (_exam!.passCount! / _exam!.studentCount * 100).toStringAsFixed(1)
        : '0.0';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '考试统计',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 2.5,
              children: [
                _buildStatItem('平均分', _exam!.averageScore?.toStringAsFixed(2) ?? '-', Icons.show_chart, Colors.blue),
                _buildStatItem('最高分', _exam!.maxScore?.toStringAsFixed(1) ?? '-', Icons.arrow_upward, Colors.green),
                _buildStatItem('最低分', _exam!.minScore?.toStringAsFixed(1) ?? '-', Icons.arrow_downward, Colors.orange),
                _buildStatItem('及格率', '$passRate%', Icons.pie_chart, Colors.purple),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, color: Colors.blue[700]),
                  const SizedBox(width: 8),
                  Text(
                    '参加考试：${_exam!.studentCount} 人',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoDataCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.warning_amber,
              size: 48,
              color: Colors.orange[400],
            ),
            const SizedBox(height: 12),
            Text(
              '暂无成绩数据',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.orange[700],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '点击下方按钮添加学生成绩',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoresSection() {
    final sortedScores = _getSortedScores();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Text(
                  '成绩列表 (${_scores.length}条)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '排序: ${_getSortTypeLabel()}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ],
            ),
          ),
          if (_scores.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Text('暂无成绩记录'),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sortedScores.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                return _buildScoreItem(sortedScores[index], index + 1);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildScoreItem(Score score, int displayRank) {
    final student = _studentsCache[score.studentId];
    final isExcellent = score.score >= 90;
    final isPass = score.score >= 60;
    final schoolRanking = score.schoolRanking;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: isExcellent
          ? Colors.green[50]
          : !isPass
              ? Colors.red[50]
              : null,
      child: Row(
        children: [
          // 总分校排名
          SizedBox(
            width: 60,
            child: schoolRanking != null
                ? Text(
                    '$schoolRanking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: schoolRanking <= 3
                          ? (schoolRanking == 1
                              ? Colors.amber
                              : schoolRanking == 2
                                  ? Colors.grey[600]
                                  : Colors.brown[400])
                          : Colors.grey[800],
                    ),
                  )
                : Text(
                    '-',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[400],
                    ),
                  ),
          ),
          // 学号
          Expanded(
            flex: 2,
            child: Text(
              student?.studentNumber ?? '-',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          // 姓名
          Expanded(
            flex: 3,
            child: Text(
              student?.name ?? '未知学生',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          // 成绩
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isExcellent
                    ? Colors.green
                    : isPass
                        ? Colors.blue[100]
                        : Colors.red[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                score.score.toStringAsFixed(1),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isPass ? Colors.blue[900] : Colors.red[900],
                ),
              ),
            ),
          ),
          // 操作
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () => _showScoreOptions(score),
          ),
        ],
      ),
    );
  }

  List<Score> _getSortedScores() {
    switch (_sortType) {
      case ScoreSortType.schoolRanking:
        return List.from(_scores)..sort((a, b) {
          final aRank = a.schoolRanking ?? 9999;
          final bRank = b.schoolRanking ?? 9999;
          return aRank.compareTo(bRank);
        });
      case ScoreSortType.ranking:
        return List.from(_scores)..sort((a, b) => (a.ranking ?? 999).compareTo(b.ranking ?? 999));
      case ScoreSortType.scoreDesc:
        return List.from(_scores)..sort((a, b) => b.score.compareTo(a.score));
      case ScoreSortType.scoreAsc:
        return List.from(_scores)..sort((a, b) => a.score.compareTo(b.score));
      case ScoreSortType.studentNumber:
        return _scores; // 需要学生信息后才能实现
    }
  }

  String _getSortTypeLabel() {
    switch (_sortType) {
      case ScoreSortType.schoolRanking:
        return '总分校排名';
      case ScoreSortType.ranking:
        return '排名';
      case ScoreSortType.scoreDesc:
        return '成绩降序';
      case ScoreSortType.scoreAsc:
        return '成绩升序';
      case ScoreSortType.studentNumber:
        return '学号';
    }
  }

  void _editExam() {
    // TODO: 编辑考试信息
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能开发中...')),
    );
  }

  void _exportToExcel() {
    // TODO: 导出Excel
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能开发中...')),
    );
  }

  void _addScore() {
    // TODO: 添加成绩
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('添加成绩功能开发中...')),
    );
  }

  void _showScoreOptions(Score score) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑成绩'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 编辑成绩
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('删除成绩'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 删除成绩
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _getSubjectColor(String value) {
    switch (value) {
      case 'math':
        return Colors.blue;
      case 'chinese':
        return Colors.red;
      case 'english':
        return Colors.green;
      case 'science':
        return Colors.purple;
      case 'morality':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

enum ScoreSortType {
  schoolRanking,
  ranking,
  scoreDesc,
  scoreAsc,
  studentNumber,
}
