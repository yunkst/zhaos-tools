import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/providers/score_provider.dart';
import 'package:teacher_tools/models/score_statistics.dart';
import 'package:teacher_tools/widgets/charts/grade_distribution_pie_chart.dart';
import 'package:teacher_tools/widgets/charts/ranking_distribution_bar_chart.dart';

/// 统计分析Tab
class StatisticsTab extends StatelessWidget {
  final int studentId;

  const StatisticsTab({super.key, required this.studentId});

  @override
  Widget build(BuildContext context) {
    return Consumer<ScoreProvider>(
      builder: (context, provider, child) {
        if (provider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.statistics == null) {
          return const Center(child: Text('暂无统计数据'));
        }

        final stats = provider.statistics!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 统计概览卡片
              _buildStatisticsOverview(context, stats),

              const SizedBox(height: 24),

              // 科目统计
              if (provider.subjectStatistics != null &&
                  provider.subjectStatistics!.isNotEmpty)
                _buildSubjectStatistics(context, provider.subjectStatistics!),

              const SizedBox(height: 24),

              // 等级分布饼图
              if (provider.gradeDistribution != null &&
                  provider.gradeDistribution!.isNotEmpty)
                _buildGradeDistribution(context, provider.gradeDistribution!),

              const SizedBox(height: 24),

              // 排名分布柱状图
              if (provider.rankingDistribution != null &&
                  provider.rankingDistribution!.isNotEmpty)
                _buildRankingDistribution(context, provider.rankingDistribution!),
            ],
          ),
        );
      },
    );
  }

  /// 统计概览卡片
  Widget _buildStatisticsOverview(BuildContext context, StudentStatistics stats) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '统计概览',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                // 添加说明图标
                Tooltip(
                  message: '所有科目成绩已转换为百分比进行统计，确保跨科目可比性',
                  child: Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 统计数据网格
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildStatItem(
                  context,
                  label: '平均分',
                  value: stats.averageScore.toStringAsFixed(1),
                  icon: Icons.calculate_outlined,
                  color: Colors.blue,
                ),
                _buildStatItem(
                  context,
                  label: '最高分',
                  value: stats.maxScore.toStringAsFixed(0),
                  icon: Icons.arrow_upward,
                  color: Colors.green,
                ),
                _buildStatItem(
                  context,
                  label: '最低分',
                  value: stats.minScore.toStringAsFixed(0),
                  icon: Icons.arrow_downward,
                  color: Colors.red,
                ),
                _buildStatItem(
                  context,
                  label: '考试次数',
                  value: '${stats.totalExams}次',
                  icon: Icons.quiz,
                  color: Colors.orange,
                ),
                _buildStatItem(
                  context,
                  label: '及格率',
                  value: '${stats.passRate.toStringAsFixed(0)}%',
                  icon: Icons.check_circle_outline,
                  color: Colors.teal,
                ),
                _buildStatItem(
                  context,
                  label: '优秀率',
                  value: '${stats.excellentRate.toStringAsFixed(0)}%',
                  icon: Icons.star_border,
                  color: Colors.amber,
                ),
              ],
            ),

            // 平均排名
            if (stats.averageRanking != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF9C27B0).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF9C27B0), width: 1),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.emoji_events, color: Color(0xFF9C27B0)),
                    const SizedBox(width: 12),
                    Text(
                      '平均排名: 第${stats.averageRanking}名',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF9C27B0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 统计项组件
  Widget _buildStatItem(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ],
      ),
    );
  }

  /// 科目统计
  Widget _buildSubjectStatistics(
    BuildContext context,
    List<SubjectStatistics> subjectStats,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
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
                  '科目统计',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: subjectStats.length,
              separatorBuilder: (context, index) => const Divider(height: 24),
              itemBuilder: (context, index) {
                final stat = subjectStats[index];
                return _buildSubjectStatItem(context, stat);
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 科目统计项
  Widget _buildSubjectStatItem(
    BuildContext context,
    SubjectStatistics stat,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              stat.subject.label,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            Text(
              '平均 ${stat.averageScore.toStringAsFixed(1)}分',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMiniStat(
                '最高',
                stat.maxScore.toStringAsFixed(0),
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStat(
                '最低',
                stat.minScore.toStringAsFixed(0),
                Colors.red,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMiniStat(
                '及格率',
                '${stat.passRate.toStringAsFixed(0)}%',
                Colors.teal,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 迷你统计组件
  Widget _buildMiniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
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

  /// 等级分布
  Widget _buildGradeDistribution(
    BuildContext context,
    List<GradeDistribution> distribution,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pie_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '等级分布',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: GradeDistributionPieChart(distribution: distribution),
            ),
          ],
        ),
      ),
    );
  }

  /// 排名分布
  Widget _buildRankingDistribution(
    BuildContext context,
    List<RankingDistribution> distribution,
  ) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.stacked_bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '排名分布',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 250,
              child: RankingDistributionBarChart(distribution: distribution),
            ),
          ],
        ),
      ),
    );
  }
}
