import 'package:flutter/material.dart';
import 'package:teacher_tools/models/personality_trait.dart';

/// 性格滑块组件
/// 用于设置单个性格维度的值（-10到+10）
class PersonalitySlider extends StatelessWidget {
  final String dimension;
  final String negativeLabel;
  final String positiveLabel;
  final int value;
  final Function(int) onChanged;
  final bool enabled;

  const PersonalitySlider({
    super.key,
    required this.dimension,
    required this.negativeLabel,
    required this.positiveLabel,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 维度标题 + 描述标签 + 数值徽章（同一行）
        Row(
          children: [
            Expanded(
              child: Text(
                dimension,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // 描述标签（仅在非0时显示）
            if (value != 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Text(
                  _getCurrentLabel(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: _getTrackColor(),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            // 数值徽章
            _buildValueBadge(context),
          ],
        ),
        const SizedBox(height: 8),

        // 滑块
        Row(
          children: [
            // 滑块（已删除左右提示性文案，进度条自动填满容器）
            Expanded(
              child: SliderTheme(
                data: SliderThemeData(
                  activeTrackColor: _getTrackColor(),
                  inactiveTrackColor: _getInactiveTrackColor(),
                  thumbColor: _getThumbColor(),
                  overlayColor: _getOverlayColor(),
                  trackHeight: 4.0,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10.0,
                  ),
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: -10,
                  max: 10,
                  divisions: 20,
                  label: value.toString(),
                  onChanged: enabled
                      ? (newValue) {
                          onChanged(newValue.round());
                        }
                      : null,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 构建数值徽章
  Widget _buildValueBadge(BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;

    if (value < 0) {
      backgroundColor = Colors.red.shade50;
      textColor = Colors.red.shade700;
    } else if (value > 0) {
      backgroundColor = Colors.green.shade50;
      textColor = Colors.green.shade700;
    } else {
      backgroundColor = Colors.grey.shade200;
      textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        value.toString(),
        style: theme.textTheme.titleSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 获取当前值的标签（方案A：生动形容词风格）
  String _getCurrentLabel() {
    return PersonalityTrait.getLabelWithLevel(
      value: value,
      negativeLabel: negativeLabel,
      positiveLabel: positiveLabel,
    );
  }

  /// 获取轨道颜色
  Color _getTrackColor() {
    if (value < 0) return Colors.red;
    if (value > 0) return Colors.green;
    return Colors.grey;
  }

  /// 获取非活动轨道颜色
  Color _getInactiveTrackColor() {
    if (value < 0) return Colors.red.shade100;
    if (value > 0) return Colors.green.shade100;
    return Colors.grey.shade300;
  }

  /// 获取滑块颜色
  Color _getThumbColor() {
    if (value < 0) return Colors.red;
    if (value > 0) return Colors.green;
    return Colors.grey;
  }

  /// 获取叠加层颜色
  Color _getOverlayColor() {
    if (value < 0) {
      return Colors.red.withValues(alpha: 0.2);
    }
    if (value > 0) {
      return Colors.green.withValues(alpha: 0.2);
    }
    return Colors.grey.withValues(alpha: 0.2);
  }
}
