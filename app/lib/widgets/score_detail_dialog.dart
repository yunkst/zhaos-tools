import 'package:flutter/material.dart';
import 'package:teacher_tools/models/score_statistics.dart';
import 'package:teacher_tools/utils/constants.dart';
import 'package:intl/intl.dart';

/// 成绩详情弹窗
class ScoreDetailDialog extends StatelessWidget {
  final ScoreWithExam scoreWithExam;

  const ScoreDetailDialog({super.key, required this.scoreWithExam});

  @override
  Widget build(BuildContext context) {
    final score = scoreWithExam.score;
    final exam = scoreWithExam.exam;
    final classAverage = exam.averageScore;

    final percentage = score.percentage;
    final scoreColor = _getScoreColor(percentage);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    exam.name,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const Divider(height: 24),

            // 考试信息
            _buildInfoRow(
              context,
              icon: Icons.school,
              label: '科目',
              value: exam.subjectText,
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.calendar_today,
              label: '日期',
              value: DateFormat('yyyy年MM月dd日').format(exam.examDate),
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              icon: Icons.category,
              label: '类型',
              value: exam.typeText,
            ),

            const Divider(height: 24),

            // 成绩对比
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildScoreCard(
                  context,
                  label: '个人成绩',
                  score: score.score.toString(),
                  color: scoreColor,
                  icon: Icons.person,
                ),
                _buildScoreCard(
                  context,
                  label: '满分',
                  score: score.fullScore.toString(),
                  color: Colors.grey,
                  icon: Icons.flag,
                ),
                if (classAverage != null)
                  _buildScoreCard(
                    context,
                    label: '班级平均',
                    score: classAverage.toStringAsFixed(1),
                    color: Colors.blue,
                    icon: Icons.people,
                  ),
              ],
            ),

            // 排名
            if (score.ranking != null && exam.studentCount > 0) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange, width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Colors.orange),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '班级排名: 第${score.ranking}名 / 共${exam.studentCount}人',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // 对比条
            if (classAverage != null) ...[
              const SizedBox(height: 16),
              _buildComparisonBar(context, score.score, classAverage, scoreColor),
            ],

            // 状态标签
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: [
                Chip(
                  label: Text(
                    score.isPass ? '及格' : '不及格',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: score.isPass ? Colors.green : Colors.red,
                ),
                if (score.isExcellent)
                  const Chip(
                    label: Text(
                      '优秀',
                      style: TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.amber,
                  ),
                if (exam.type == ExamType.midTerm || exam.type == ExamType.finalTerm)
                  Chip(
                    label: Text(
                      exam.type == ExamType.midTerm ? '期中考试' : '期末考试',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: Colors.purple,
                  ),
              ],
            ),

            // 备注
            if (score.remarks != null && score.remarks!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.note, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '备注',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(score.remarks!),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // 关闭按钮
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 信息行
  Widget _buildInfoRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Text(
          '$label:',
          style: TextStyle(
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// 成绩卡片
  Widget _buildScoreCard(
    BuildContext context, {
    required String label,
    required String score,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 2),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 8),
          Text(
            score,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// 对比条
  Widget _buildComparisonBar(
    BuildContext context,
    double personalScore,
    double classAverage,
    Color scoreColor,
  ) {
    final maxScore = personalScore > classAverage ? personalScore : classAverage;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: (personalScore / maxScore * 100).toInt(),
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: scoreColor,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  personalScore.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              flex: (classAverage / maxScore * 100).toInt(),
              child: Container(
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.grey[400],
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(4),
                    bottomRight: Radius.circular(4),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  classAverage.toStringAsFixed(1),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Center(
                child: Text(
                  '个人成绩',
                  style: TextStyle(
                    color: scoreColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Center(
                child: Text(
                  '班级平均',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 获取分数颜色
  Color _getScoreColor(double percentage) {
    if (percentage >= 90) return const Color(0xFF4CAF50); // green
    if (percentage >= 80) return const Color(0xFF2196F3); // blue
    if (percentage >= 60) return const Color(0xFFFF9800); // orange
    return const Color(0xFFF44336); // red
  }
}
