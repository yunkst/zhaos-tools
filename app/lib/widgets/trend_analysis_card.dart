import 'package:flutter/material.dart';
import 'package:teacher_tools/models/score_statistics.dart';
import 'dart:math';

/// 趋势分析卡片
class TrendAnalysisCard extends StatelessWidget {
  final List<ScoreTrend> trends;

  const TrendAnalysisCard({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    final analysis = _analyzeTrends();

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb,
                  color: Colors.amber,
                ),
                const SizedBox(width: 8),
                Text(
                  '趋势分析',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 趋势总结
            _buildAnalysisItem(
              context,
              content: analysis['overallTrend'],
              icon: analysis['overallIcon'],
              color: _getTrendColor(analysis['trendType']),
            ),

            // 警告信息
            if (analysis['warnings'].isNotEmpty) ...[
              const SizedBox(height: 12),
              ...analysis['warnings'].map((warning) => _buildAnalysisItem(
                    context,
                    content: warning,
                    icon: Icons.warning,
                    color: Colors.orange,
                  )),
            ],

            // 建议
            if (analysis['suggestions'].isNotEmpty) ...[
              const SizedBox(height: 12),
              ...analysis['suggestions'].map((suggestion) => _buildAnalysisItem(
                    context,
                    content: suggestion,
                    icon: Icons.thumb_up,
                    color: Colors.green,
                  )),
            ],
          ],
        ),
      ),
    );
  }

  /// 分析趋势逻辑
  Map<String, dynamic> _analyzeTrends() {
    if (trends.length < 2) {
      return {
        'overallTrend': '数据不足,无法分析趋势',
        'overallIcon': '📊',
        'trendType': 'unknown',
        'warnings': <String>[],
        'suggestions': <String>[],
      };
    }

    // 计算整体趋势
    final firstScore = trends.first.score;
    final lastScore = trends.last.score;
    final diff = lastScore - firstScore;

    String trend;
    String icon;
    String trendType;

    if (diff > 5) {
      trend = '整体呈上升趋势 📈 +${diff.toStringAsFixed(1)}分';
      icon = '✅';
      trendType = 'up';
    } else if (diff < -5) {
      trend = '整体呈下降趋势 📉 ${diff.toStringAsFixed(1)}分';
      icon = '⚠️';
      trendType = 'down';
    } else {
      trend = '整体稳定 ➡️ 波动${diff.abs().toStringAsFixed(1)}分';
      icon = '➡️';
      trendType = 'stable';
    }

    // 检查波动大的科目
    final warnings = <String>[];
    final suggestions = <String>[];

    // 计算标准差
    final scores = trends.map((t) => t.score).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    final variance = scores.map((s) => pow(s - mean, 2)).reduce((a, b) => a + b) / scores.length;
    final stdDev = sqrt(variance);

    if (stdDev > 10) {
      warnings.add('成绩波动较大(标准差${stdDev.toStringAsFixed(1)}分),需要稳定发挥');
      suggestions.add('建议保持稳定的学习节奏,避免成绩大幅波动');
    }

    // 检查是否有不及格
    final failingScores = trends.where((t) => !t.isPass).toList();
    if (failingScores.isNotEmpty) {
      warnings.add('有${failingScores.length}次考试不及格,需要重点关注');
      suggestions.add('建议加强基础知识复习,必要时寻求老师帮助');
    }

    // 检查连续进步
    int consecutiveImprovements = 0;
    for (int i = trends.length - 1; i > 0; i--) {
      if (trends[i].score >= trends[i - 1].score) {
        consecutiveImprovements++;
      } else {
        break;
      }
    }

    if (consecutiveImprovements >= 3) {
      suggestions.add('连续$consecutiveImprovements次考试进步,保持当前学习状态! 💪');
    }

    // 检查连续退步
    int consecutiveDeclines = 0;
    for (int i = trends.length - 1; i > 0; i--) {
      if (trends[i].score < trends[i - 1].score) {
        consecutiveDeclines++;
      } else {
        break;
      }
    }

    if (consecutiveDeclines >= 3) {
      warnings.add('连续$consecutiveDeclines次考试成绩下降,需要调整学习方法');
      suggestions.add('建议分析薄弱知识点,制定针对性复习计划');
    }

    // 检查最高分和最低分差距
    final maxScore = scores.reduce((a, b) => a > b ? a : b);
    final minScore = scores.reduce((a, b) => a < b ? a : b);
    final range = maxScore - minScore;

    if (range > 30) {
      warnings.add('成绩差距较大(${range.toStringAsFixed(1)}分),发挥不稳定');
      suggestions.add('建议总结高分经验,稳定发挥水平');
    }

    return {
      'overallTrend': trend,
      'overallIcon': icon,
      'trendType': trendType,
      'warnings': warnings,
      'suggestions': suggestions,
    };
  }

  /// 分析项组件
  Widget _buildAnalysisItem(
    BuildContext context, {
    required String content,
    required dynamic icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon is String)
            Text(
              icon,
              style: const TextStyle(fontSize: 20),
            )
          else
            Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 获取趋势颜色
  Color _getTrendColor(String trendType) {
    switch (trendType) {
      case 'up':
        return Colors.green;
      case 'down':
        return Colors.red;
      case 'stable':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }
}
