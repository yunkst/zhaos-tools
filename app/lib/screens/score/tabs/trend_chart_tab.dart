import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/providers/score_provider.dart';
import 'package:teacher_tools/widgets/charts/score_trend_line_chart.dart';
import 'package:teacher_tools/widgets/trend_analysis_card.dart';
import 'package:teacher_tools/utils/constants.dart';

/// 趋势图表Tab
class TrendChartTab extends StatefulWidget {
  final int studentId;

  const TrendChartTab({super.key, required this.studentId});

  @override
  State<TrendChartTab> createState() => _TrendChartTabState();
}

class _TrendChartTabState extends State<TrendChartTab> {
  Subject? _selectedSubject;

  @override
  Widget build(BuildContext context) {
    return Consumer<ScoreProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // 获取趋势数据
        final trends = _selectedSubject == null
            ? provider.trends
            : provider.trends?.where((t) => t.subject == _selectedSubject).toList();

        if (trends == null || trends.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // 科目选择器
            _buildSubjectSelector(),

            // 趋势折线图
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ScoreTrendLineChart(trends: trends),
              ),
            ),

            // 趋势分析卡片
            TrendAnalysisCard(trends: trends),
          ],
        );
      },
    );
  }

  /// 空状态
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '暂无趋势数据',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  /// 科目选择器
  Widget _buildSubjectSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '选择科目',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // 全部科目
              ChoiceChip(
                label: const Text('全部科目'),
                selected: _selectedSubject == null,
                onSelected: (selected) {
                  setState(() => _selectedSubject = null);
                },
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
              ),
              // 各个科目
              ...Subject.values.map((subject) {
                return ChoiceChip(
                  label: Text(subject.label),
                  selected: _selectedSubject == subject,
                  onSelected: (selected) {
                    setState(() => _selectedSubject = selected ? subject : null);
                  },
                  selectedColor: Theme.of(context).colorScheme.primaryContainer,
                );
              }),
            ],
          ),
        ],
      ),
    );
  }
}
