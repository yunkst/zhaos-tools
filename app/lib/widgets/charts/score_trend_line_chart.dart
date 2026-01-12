import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:teacher_tools/models/score_statistics.dart';
import 'package:intl/intl.dart';

/// 成绩趋势折线图
class ScoreTrendLineChart extends StatelessWidget {
  final List<ScoreTrend> trends;

  const ScoreTrendLineChart({super.key, required this.trends});

  @override
  Widget build(BuildContext context) {
    if (trends.isEmpty) {
      return const Center(child: Text('暂无数据'));
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 图例
            _buildLegend(context),

            const SizedBox(height: 16),

            // 折线图
            Expanded(
              child: LineChart(
                mainData(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 图例
  Widget _buildLegend(BuildContext context) {
    return Wrap(
      spacing: 16,
      children: [
        _buildLegendItem('成绩', Colors.blue),
        if (trends.any((t) => t.classAverage != null))
          _buildLegendItem('班级平均', Colors.grey),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  /// 图表数据
  LineChartData mainData(BuildContext context) {
    // 数据点
    final spots = _convertToSpots();

    // 班级平均数据点
    final avgSpots = _convertAvgToSpots();

    // 动态计算Y轴最大值
    final maxY = _calculateMaxY();

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Colors.grey[300]!,
            strokeWidth: 1,
          );
        },
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
            reservedSize: 30,
            interval: _calculateInterval(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= trends.length) {
                return const Text('');
              }
              final date = trends[index].examDate;
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('MM/dd').format(date),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: _calculateYInterval(maxY),
            reservedSize: 50,
            getTitlesWidget: (value, meta) {
              return Text(
                value.toInt().toString(),
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: Colors.grey[300]!),
      ),
      minX: 0,
      maxX: (trends.length - 1).toDouble(),
      minY: 0,
      maxY: maxY,  // 使用动态最大值
      lineBarsData: [
        // 学生成绩折线
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: Colors.blue,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.blue,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.blue.withValues(alpha: 0.1),
          ),
        ),

        // 班级平均折线
        if (avgSpots.isNotEmpty)
          LineChartBarData(
            spots: avgSpots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: Colors.grey,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 3,
                  color: Colors.grey,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                );
              },
            ),
            dashArray: [5, 5],
          ),
      ],
      lineTouchData: LineTouchData(
        enabled: true,
        touchTooltipData: LineTouchTooltipData(
          tooltipBgColor: Colors.blueGrey.withValues(alpha: 0.8),
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              final index = spot.spotIndex;
              if (index < 0 || index >= trends.length) {
                return null;
              }

              final trend = trends[index];
              final isAvg = spot.barIndex == 1;

              return LineTooltipItem(
                isAvg
                    ? '${trend.examName}\n班级平均: ${trend.classAverage?.toStringAsFixed(1) ?? '-'}分 / ${trend.fullScore.toInt()}分'
                        '\n(${((trend.classAverage! / trend.fullScore * 100)).toStringAsFixed(1)}%)'
                    : '${trend.examName}\n${trend.subject.label}: ${trend.score.toStringAsFixed(1)}分 / ${trend.fullScore.toInt()}分'
                        '\n(${trend.percentage.toStringAsFixed(1)}%)'
                        '${trend.ranking != null ? '\n排名: 第${trend.ranking}名' : ''}',
                const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
              );
            }).toList();
          },
        ),
      ),
    );
  }

  /// 转换数据点
  List<FlSpot> _convertToSpots() {
    return trends.asMap().entries.map((entry) {
      return FlSpot(
        entry.key.toDouble(),
        entry.value.score,
      );
    }).toList();
  }

  /// 转换班级平均数据点
  List<FlSpot> _convertAvgToSpots() {
    final spots = <FlSpot>[];

    for (int i = 0; i < trends.length; i++) {
      final avg = trends[i].classAverage;
      if (avg != null) {
        spots.add(FlSpot(i.toDouble(), avg));
      }
    }

    return spots;
  }

  /// 计算Y轴最大值
  double _calculateMaxY() {
    if (trends.isEmpty) return 100;

    // 找到所有成绩中的最大满分
    final maxFullScore = trends
        .map((t) => t.fullScore)
        .reduce((a, b) => a > b ? a : b);

    // 找到所有成绩中的最大分数
    final maxScore = trends
        .map((t) => t.score)
        .reduce((a, b) => a > b ? a : b);

    // 如果班级平均分存在，也要考虑
    double maxAvg = 0;
    if (trends.any((t) => t.classAverage != null)) {
      maxAvg = trends
          .where((t) => t.classAverage != null)
          .map((t) => t.classAverage!)
          .reduce((a, b) => a > b ? a : b);
    }

    // 取最大值，并向上取整到10的倍数
    final maxValue = [maxFullScore, maxScore, maxAvg].reduce((a, b) => a > b ? a : b);
    return (maxValue / 10).ceil() * 10.0;
  }

  /// 计算Y轴间隔
  double _calculateYInterval(double maxY) {
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    if (maxY <= 100) return 20;
    return (maxY / 5).ceilToDouble();
  }

  /// 计算X轴标签间隔
  double _calculateInterval() {
    if (trends.length <= 5) return 1;
    if (trends.length <= 10) return 2;
    return (trends.length / 5).ceilToDouble();
  }
}
