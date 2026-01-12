import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teacher_tools/models/score_statistics.dart';

/// 等级分布饼图
class GradeDistributionPieChart extends StatelessWidget {
  final List<GradeDistribution> distribution;

  const GradeDistributionPieChart({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 40,
        borderData: FlBorderData(show: false),
        sections: _buildSections(),
        pieTouchData: PieTouchData(
          enabled: true,
          touchCallback: (FlTouchEvent event, pieTouchResponse) {},
        ),
      ),
    );
  }

  /// 构建饼图区块
  List<PieChartSectionData> _buildSections() {
    final total = distribution.fold<int>(0, (sum, item) => sum + item.count);

    return distribution.asMap().entries.map((entry) {
      final item = entry.value;
      final percentage = (item.count / total) * 100;
      final value = item.count.toDouble();

      return PieChartSectionData(
        value: value,
        title: '${percentage.toStringAsFixed(1)}%\n${item.count}次',
        radius: 80,
        titleStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: const [
            Shadow(
              color: Colors.black26,
              blurRadius: 2,
            ),
          ],
        ),
        color: _getColor(item.grade),
        badgeWidget: _buildBadge(item.grade),
        badgePositionPercentageOffset: .98,
      );
    }).toList();
  }

  /// 获取颜色
  Color _getColor(String grade) {
    if (grade.contains('优秀')) return const Color(0xFF4CAF50);
    if (grade.contains('良好')) return const Color(0xFF2196F3);
    if (grade.contains('及格')) return const Color(0xFFFF9800);
    return const Color(0xFFF44336);
  }

  /// 构建徽章
  Widget _buildBadge(String grade) {
    String emoji = '';
    if (grade.contains('优秀')) {
      emoji = '⭐';
    } else if (grade.contains('良好')) {
      emoji = '👍';
    } else if (grade.contains('及格')) {
      emoji = '✅';
    } else {
      emoji = '⚠️';
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 14),
        ),
      ),
    );
  }
}
