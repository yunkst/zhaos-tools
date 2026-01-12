import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:teacher_tools/models/personality_trait.dart';

/// 性格雷达图组件
/// 使用雷达图直观展示6个性格维度
class PersonalityRadarChart extends StatelessWidget {
  final List<PersonalityTrait> traits;
  final double size;

  const PersonalityRadarChart({
    super.key,
    required this.traits,
    this.size = 200,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 如果没有数据，显示占位图
    if (traits.isEmpty || _areAllZeros()) {
      return _buildPlaceholder(context);
    }

    return SizedBox(
      width: size,
      height: size,
      child: RadarChart(
        RadarChartData(
          // 雷达图数据
          dataSets: [
            RadarDataSet(
              dataEntries: _convertTraitsToDataEntries(),
              fillColor: _getMainColor().withValues(alpha: 0.3),
              borderColor: _getMainColor(),
              borderWidth: 2,
            ),
          ],

          // 雷达图标题样式
          titleTextStyle: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            fontWeight: FontWeight.w500,
          ),

          // 刻度线样式
          radarBackgroundColor: Colors.transparent,
          radarShape: RadarShape.polygon,

          // 网格线样式
          gridBorderData: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),

          // 刻度数量（从中心向外：0, 20, 40, 60, 80, 100）
          tickCount: 6,

          // 刻度标签
          tickBorderData: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),

          // 标题（维度标签）位置
          titlePositionPercentageOffset: 0.15,
        ),
        swapAnimationDuration: const Duration(milliseconds: 400),
        swapAnimationCurve: Curves.easeInOut,
      ),
    );
  }

  /// 构建占位图（当没有数据或全部为0时）
  Widget _buildPlaceholder(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 48,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              '暂无性格数据',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 将性格特质转换为雷达图数据点
  /// 将-10到+10的范围映射为0到100
  List<RadarEntry> _convertTraitsToDataEntries() {
    return PersonalityDimensions.allDimensions.map((dimensionConfig) {
      final trait = _findTraitByDimension(dimensionConfig.dimension);
      final value = trait?.value ?? 0;

      // 将-10到+10映射为0到100
      // -10 -> 0, 0 -> 50, 10 -> 100
      final mappedValue = (value + 10) * 5.0;

      return RadarEntry(value: mappedValue);
    }).toList();
  }

  /// 根据维度名称查找对应的性格特质
  PersonalityTrait? _findTraitByDimension(String dimension) {
    try {
      return traits.firstWhere((t) => t.dimension == dimension);
    } catch (e) {
      return null;
    }
  }

  /// 判断是否全部为0
  bool _areAllZeros() {
    return traits.every((trait) => trait.value == 0);
  }

  /// 获取主要颜色（根据整体倾向）
  Color _getMainColor() {
    if (traits.isEmpty) return Colors.grey;

    // 计算正向和负向的总分
    int positiveScore = 0;
    int negativeScore = 0;

    for (var trait in traits) {
      if (trait.value > 0) {
        positiveScore += trait.value;
      } else if (trait.value < 0) {
        negativeScore += trait.value.abs();
      }
    }

    // 根据倾向返回颜色
    if (positiveScore > negativeScore) {
      return Colors.green;
    } else if (negativeScore > positiveScore) {
      return Colors.red;
    }
    return Colors.blue;
  }
}

/// 雷达图标题指示器（用于自定义维度标签）
class RadarTitleIndicator extends StatelessWidget {
  final String text;
  final Alignment alignment;

  const RadarTitleIndicator({
    super.key,
    required this.text,
    required this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Text(
          text,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
