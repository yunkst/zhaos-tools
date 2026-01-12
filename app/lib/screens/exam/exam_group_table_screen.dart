import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:teacher_tools/models/exam_group.dart';
import 'package:teacher_tools/models/score.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:teacher_tools/database/score_dao.dart';
import 'package:teacher_tools/services/pk_table_exporter.dart';

/// 考试组表格展示页面（类似Excel）
/// 学生为行，科目为列，按总分排序
class ExamGroupTableScreen extends StatefulWidget {
  final ExamGroup examGroup;

  const ExamGroupTableScreen({
    super.key,
    required this.examGroup,
  });

  @override
  State<ExamGroupTableScreen> createState() => _ExamGroupTableScreenState();
}

class _ExamGroupTableScreenState extends State<ExamGroupTableScreen> {
  final ScoreDAO _scoreDAO = ScoreDAO();
  bool _isLoading = true;
  bool _isExporting = false;
  List<_StudentScoreRow> _rows = [];
  final Map<int, Map<int, Score>> _scoresCache = {}; // examId -> studentId -> Score

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;

    setState(() => _isLoading = true);

    try {
      // 1. 获取所有学生
      final studentProvider = context.read<StudentProvider>();

      // 延迟执行，避免在build期间触发notifyListeners
      await Future.microtask(() => studentProvider.loadStudents(widget.examGroup.classId));

      if (!mounted) return;

      final students = studentProvider.students;

      // 2. 获取所有科目的成绩
      for (var exam in widget.examGroup.subjects) {
        final scores = await _scoreDAO.getByExamId(exam.id!);
        for (var score in scores) {
          _scoresCache.putIfAbsent(exam.id!, () => {});
          _scoresCache[exam.id!]![score.studentId] = score;
        }
      }

      // 3. 构建表格行数据
      final List<_StudentScoreRow> rows = [];
      for (var student in students) {
        final Map<int, double> subjectScores = {};
        double totalScore = 0;
        int? schoolRanking;

        for (var exam in widget.examGroup.subjects) {
          final score = _scoresCache[exam.id!]?[student.id];
          final subjectScore = score?.score ?? 0;
          subjectScores[exam.id!] = subjectScore;
          totalScore += subjectScore;

          // 提取总分校排名（从第一个有成绩的科目中获取）
          if (score != null && schoolRanking == null) {
            schoolRanking = score.schoolRanking;
          }
        }

        rows.add(_StudentScoreRow(
          student: student,
          subjectScores: subjectScores,
          totalScore: totalScore,
          schoolRanking: schoolRanking,
        ));
      }

      // 4. 按总分降序排序
      rows.sort((a, b) => b.totalScore.compareTo(a.totalScore));

      if (!mounted) return;

      setState(() {
        _rows = rows;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('❌ 加载数据失败: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.examGroup.name} - 详细表格'),
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
            onPressed: _isExporting ? null : _exportPKTable,
            tooltip: '导出PK表',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildTable(),
    );
  }

  Widget _buildTable() {
    if (_rows.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          border: TableBorder.all(color: Colors.grey[300]!),
          columns: _buildColumns(),
          rows: _buildRows(),
          columnSpacing: 0,
          horizontalMargin: 8,
          headingRowColor: WidgetStateProperty.all(Colors.grey[200]),
        ),
      ),
    );
  }

  List<DataColumn> _buildColumns() {
    final List<DataColumn> columns = [];

    // 排名列
    columns.add(const DataColumn(
      label: Center(child: Text('排名')),
      numeric: true,
    ));

    // 校排名列（总分校排名）
    columns.add(const DataColumn(
      label: Center(child: Text('校排名')),
      numeric: true,
    ));

    // 学号列
    columns.add(const DataColumn(
      label: Center(child: Text('学号')),
    ));

    // 姓名列
    columns.add(const DataColumn(
      label: Center(child: Text('姓名')),
    ));

    // 各科列
    for (var exam in widget.examGroup.subjects) {
      final color = _getSubjectColor(exam.subject.value);
      columns.add(DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Center(
            child: Text(
              exam.subjectText,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        numeric: true,
      ));
    }

    // 总分列
    columns.add(DataColumn(
      label: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Center(
          child: Text(
            '总分',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
      numeric: true,
    ));

    return columns;
  }

  List<DataRow> _buildRows() {
    return _rows.asMap().entries.map((entry) {
      final index = entry.key;
      final row = entry.value;
      return DataRow(
        color: WidgetStateProperty.resolveWith((states) {
          // 前三名特殊颜色
          if (index < 3) {
            switch (index) {
              case 0:
                return Colors.amber[100];
              case 1:
                return Colors.grey[300];
              case 2:
                return Colors.orange[100];
            }
          }
          return index % 2 == 0 ? Colors.white : Colors.grey[50];
        }),
        cells: _buildCells(row, index + 1),
      );
    }).toList();
  }

  List<DataCell> _buildCells(_StudentScoreRow row, int rank) {
    final List<DataCell> cells = [];

    // 排名（班级排名）
    cells.add(DataCell(
      Center(
        child: Text(
          rank.toString(),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: rank <= 3 ? Colors.red : null,
          ),
        ),
      ),
    ));

    // 校排名（总分校排名）
    cells.add(DataCell(
      Center(
        child: row.schoolRanking != null
            ? Text(
                row.schoolRanking.toString(),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: row.schoolRanking! <= 3
                      ? (row.schoolRanking! == 1
                          ? Colors.amber
                          : row.schoolRanking! == 2
                              ? Colors.grey[600]
                              : Colors.brown[400])
                      : Colors.blue,
                ),
              )
            : const Text(
                '-',
                style: TextStyle(color: Colors.grey),
              ),
      ),
    ));

    // 学号
    cells.add(DataCell(
      Center(child: Text(row.student.studentNumber)),
    ));

    // 姓名
    cells.add(DataCell(
      Center(child: Text(row.student.name)),
    ));

    // 各科成绩
    for (var exam in widget.examGroup.subjects) {
      final score = row.subjectScores[exam.id] ?? 0;
      final color = _getSubjectColor(exam.subject.value);

      cells.add(DataCell(
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              score.toStringAsFixed(0),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ));
    }

    // 总分
    cells.add(DataCell(
      Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            row.totalScore.toStringAsFixed(0),
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ),
    ));

    return cells;
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

  /// 导出PK表
  Future<void> _exportPKTable() async {
    if (_rows.isEmpty) {
      _showSnackBar('暂无数据可导出', Colors.orange);
      return;
    }

    setState(() => _isExporting = true);

    try {
      // 提取按排名排序的学生列表
      final rankedStudents = _rows.map((row) => row.student).toList();

      debugPrint('📊 开始导出PK表，学生数量: ${rankedStudents.length}');

      // 生成Excel文件
      final filePath = await PKTableExporter.exportToExcel(
        widget.examGroup.name,
        rankedStudents,
      );

      if (mounted) {
        setState(() => _isExporting = false);

        // 自动弹出分享菜单
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: 'PK排班表',
          text: '${widget.examGroup.name} - PK排班表（${rankedStudents.length}人）',
        );

        // 分享后提示
        _showSnackBar('导出并分享成功！', Colors.green);
      }
    } catch (e) {
      debugPrint('❌ 导出失败: $e');
      if (mounted) {
        setState(() => _isExporting = false);
        _showSnackBar('导出失败: $e', Colors.red);
      }
    }
  }

  /// 显示提示消息
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
      ),
    );
  }
}

class _StudentScoreRow {
  final Student student;
  final Map<int, double> subjectScores; // examId -> score
  final double totalScore;
  final int? schoolRanking; // 总分校排名

  _StudentScoreRow({
    required this.student,
    required this.subjectScores,
    required this.totalScore,
    this.schoolRanking,
  });
}
