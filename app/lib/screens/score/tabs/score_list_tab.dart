import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/providers/score_provider.dart';
import 'package:teacher_tools/models/score_statistics.dart';
import 'package:teacher_tools/widgets/score_detail_dialog.dart';
import 'package:teacher_tools/utils/constants.dart';
import 'package:intl/intl.dart';

/// 成绩列表Tab
class ScoreListTab extends StatefulWidget {
  final int studentId;

  const ScoreListTab({super.key, required this.studentId});

  @override
  State<ScoreListTab> createState() => _ScoreListTabState();
}

class _ScoreListTabState extends State<ScoreListTab> {
  // 筛选状态
  Subject? _selectedSubject;
  ExamType? _selectedExamType;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 筛选栏
        _buildFilterBar(),

        // 成绩列表
        Expanded(
          child: Consumer<ScoreProvider>(
            builder: (context, provider, child) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (provider.errorMessage != null) {
                return Center(
                  child: Text(
                    provider.errorMessage!,
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                );
              }

              // 应用筛选
              final filteredScores = provider.filterScores(
                subject: _selectedSubject,
                examType: _selectedExamType,
              );

              if (filteredScores.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredScores.length,
                itemBuilder: (context, index) {
                  return _buildScoreCard(filteredScores[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  /// 筛选栏
  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          // 科目筛选
          DropdownButtonHideUnderline(
            child: DropdownButton<Subject>(
              hint: const Text('全部科目'),
              value: _selectedSubject,
              items: [
                const DropdownMenuItem(value: null, child: Text('全部科目')),
                ...Subject.values.map((subject) {
                  return DropdownMenuItem(
                    value: subject,
                    child: Text(subject.label),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedSubject = value);
              },
            ),
          ),

          // 考试类型筛选
          DropdownButtonHideUnderline(
            child: DropdownButton<ExamType>(
              hint: const Text('全部类型'),
              value: _selectedExamType,
              items: [
                const DropdownMenuItem(value: null, child: Text('全部类型')),
                ...ExamType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  );
                }),
              ],
              onChanged: (value) {
                setState(() => _selectedExamType = value);
              },
            ),
          ),

          // 重置按钮
          if (_selectedSubject != null || _selectedExamType != null)
            TextButton.icon(
              onPressed: _resetFilters,
              icon: const Icon(Icons.refresh),
              label: const Text('重置'),
            ),
        ],
      ),
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedSubject != null || _selectedExamType != null
                ? '没有符合条件的成绩'
                : '暂无成绩记录',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 成绩卡片
  Widget _buildScoreCard(ScoreWithExam item) {
    final score = item.score;
    final exam = item.exam;

    // 判断趋势(需要对比前一次成绩)
    final scoreColor = _getScoreColor(score.percentage);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showScoreDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 考试名称和日期
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          exam.name,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${exam.subjectText} • ${_formatDate(exam.examDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                  // 成绩
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: scoreColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: scoreColor, width: 2),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '${score.score}',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: scoreColor,
                          ),
                        ),
                        Text(
                          '满分 ${score.fullScore}',
                          style: TextStyle(
                            fontSize: 12,
                            color: scoreColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 排名和统计信息
              Wrap(
                spacing: 16,
                children: [
                  if (score.ranking != null)
                    _buildInfoChip(
                      icon: Icons.emoji_events,
                      label: '排名',
                      value: '第${score.ranking}名',
                      color: Colors.orange,
                    ),
                  if (exam.averageScore != null)
                    _buildInfoChip(
                      icon: Icons.people,
                      label: '班级平均',
                      value: '${exam.averageScore!.toStringAsFixed(1)}分',
                      color: Colors.blue,
                    ),
                  _buildInfoChip(
                    icon: score.isPass ? Icons.check_circle : Icons.cancel,
                    label: '状态',
                    value: score.isPass ? '及格' : '不及格',
                    color: score.isPass ? Colors.green : Colors.red,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 信息芯片
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 显示成绩详情
  void _showScoreDetail(ScoreWithExam item) {
    showDialog(
      context: context,
      builder: (context) => ScoreDetailDialog(scoreWithExam: item),
    );
  }

  /// 重置筛选
  void _resetFilters() {
    setState(() {
      _selectedSubject = null;
      _selectedExamType = null;
    });
  }

  /// 获取分数颜色
  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return const Color(0xFF4CAF50); // green
    if (percentage >= 80) return const Color(0xFF2196F3); // blue
    if (percentage >= 60) return const Color(0xFFFF9800); // orange
    return const Color(0xFFF44336); // red
  }

  /// 格式化日期
  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
