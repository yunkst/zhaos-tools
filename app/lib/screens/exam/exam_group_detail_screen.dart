import 'package:flutter/material.dart';
import 'package:teacher_tools/models/exam_group.dart';
import 'package:teacher_tools/screens/exam/exam_group_table_screen.dart';

/// 考试组综合统计页面
class ExamGroupDetailScreen extends StatelessWidget {
  final ExamGroup examGroup;

  const ExamGroupDetailScreen({
    super.key,
    required this.examGroup,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(examGroup.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.table_chart),
            onPressed: () => _navigateToTable(context),
            tooltip: '详细表格',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 基本信息
          _buildBasicInfoCard(context),
          const SizedBox(height: 16),

          // 整体统计
          if (examGroup.hasStatistics) _buildOverallStatsCard(context),
          const SizedBox(height: 16),

          // 各科详情
          _buildSubjectsCard(context),
        ],
      ),
    );
  }

  Widget _buildBasicInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '考试信息',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, '考试日期', examGroup.formattedDate),
            _buildInfoRow(context, '考试类型', examGroup.typeText),
            _buildInfoRow(context, '科目数量', '${examGroup.subjectCount}科'),
            _buildInfoRow(context, '参考人数', '${examGroup.totalStudents}人'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverallStatsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '整体统计',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatItem(
                  context,
                  Icons.trending_up,
                  '整体平均分',
                  examGroup.overallAverage?.toStringAsFixed(1) ?? '-',
                  Colors.blue,
                ),
                _buildStatItem(
                  context,
                  Icons.check_circle,
                  '整体及格率',
                  '${examGroup.overallPassRate?.toStringAsFixed(0) ?? '-'}%',
                  Colors.green,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubjectsCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.school,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '各科统计',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...examGroup.subjects.map((subject) => _buildSubjectItem(context, subject)),
          ],
        ),
      ),
    );
  }

  Widget _buildSubjectItem(BuildContext context, subject) {
    final color = _getSubjectColor(subject.subject.value);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      subject.subjectText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                    ),
                    if (subject.averageScore != null)
                      Text(
                        '平均分: ${subject.averageScore!.toStringAsFixed(1)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                  ],
                ),
              ),
              if (subject.hasStatistics)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _buildMiniStat('最高', subject.maxScore?.toStringAsFixed(0) ?? '-', color),
                    _buildMiniStat('最低', subject.minScore?.toStringAsFixed(0) ?? '-', color),
                    _buildMiniStat('及格率', '${((subject.passCount ?? 0) / subject.studentCount * 100).toStringAsFixed(0)}%', color),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
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

  void _navigateToTable(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamGroupTableScreen(examGroup: examGroup),
      ),
    );
  }
}
