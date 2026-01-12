import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teacher_tools/models/score_statistics.dart';

/// 排名分布柱状图
class RankingDistributionBarChart extends StatelessWidget {
  final List<RankingDistribution> distribution;

  const RankingDistributionBarChart({super.key, required this.distribution});

  @override
  Widget build(BuildContext context) {
    if (distribution.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: _calculateMaxY(),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey.withValues(alpha: 0.8),
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final range = distribution[groupIndex].range;
              final count = distribution[groupIndex].count;
              return BarTooltipItem(
                '$range\n$count次',
                const TextStyle(color: Colors.white, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 60,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= distribution.length) {
                  return const Text('');
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    distribution[index].range,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: _calculateInterval(),
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _calculateInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[300]!,
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey[300]!),
        ),
        barGroups: _buildBarGroups(),
      ),
    );
  }

  /// 构建柱状图组
  List<BarChartGroupData> _buildBarGroups() {
    return distribution.asMap().entries.map((entry) {
      final index = entry.key;
      final item = entry.value;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: item.count.toDouble(),
            color: _getBarColor(index),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
              topRight: Radius.circular(6),
            ),
            borderSide: BorderSide(
              color: _getBarColor(index).withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ],
      );
    }).toList();
  }

  /// 获取柱状颜色
  Color _getBarColor(int index) {
    final colors = [
      Colors.green,    // 前10名
      Colors.blue,     // 11-20名
      Colors.orange,   // 21-30名
      Colors.deepOrange, // 31-40名
      Colors.red,      // 40名以后
    ];

    return colors[index % colors.length];
  }

  /// 计算Y轴最大值
  double _calculateMaxY() {
    if (distribution.isEmpty) return 10;

    final maxCount = distribution.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    return (maxCount * 1.2).ceilToDouble();
  }

  /// 计算Y轴间隔
  double _calculateInterval() {
    final maxY = _calculateMaxY();
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    return (maxY / 5).ceilToDouble();
  }
}
