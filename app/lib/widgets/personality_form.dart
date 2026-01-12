import 'package:flutter/material.dart';
import 'package:teacher_tools/models/personality_trait.dart';
import 'package:teacher_tools/widgets/personality_slider.dart';

/// 性格设置表单组件
/// 展示6个性格维度的滑块设置
class PersonalityForm extends StatefulWidget {
  final List<PersonalityTrait>? initialTraits;
  final bool readonly;
  final bool showResetButton;
  final Function(List<PersonalityTrait>)? onChanged; // 新增：数据变化回调

  const PersonalityForm({
    super.key,
    this.initialTraits,
    this.readonly = false,
    this.showResetButton = true,
    this.onChanged,
  });

  @override
  State<PersonalityForm> createState() => _PersonalityFormState();
}

class _PersonalityFormState extends State<PersonalityForm> {
  late List<PersonalityTrait> _traits;

  @override
  void initState() {
    super.initState();
    // 如果提供了初始值，使用初始值；否则使用默认值（全部为0）
    if (widget.initialTraits != null && widget.initialTraits!.isNotEmpty) {
      _traits = List.from(widget.initialTraits!);
    } else {
      _traits = PersonalityDimensions.getDefaultTraits();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 标题和重置按钮
        if (!widget.readonly && widget.showResetButton)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '性格特质评估',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.purple,
                ),
              ),
              TextButton.icon(
                onPressed: _resetTraits,
                icon: const Icon(Icons.refresh),
                label: const Text('重置'),
              ),
            ],
          ),
        if (!widget.readonly && widget.showResetButton) const SizedBox(height: 16),

        // 性格维度滑块列表
        ...PersonalityDimensions.allDimensions.asMap().entries.map((entry) {
          final index = entry.key;
          final dimensionConfig = entry.value;

          // 查找当前值
          final currentTrait = _traits.indexWhere(
            (t) => t.dimension == dimensionConfig.dimension,
          );

          final currentValue = currentTrait >= 0
              ? _traits[currentTrait].value
              : 0;

          return Padding(
            padding: EdgeInsets.only(
              bottom: index < PersonalityDimensions.allDimensions.length - 1
                  ? 24.0
                  : 0,
            ),
            child: PersonalitySlider(
              dimension: dimensionConfig.dimension,
              negativeLabel: dimensionConfig.negativeLabel,
              positiveLabel: dimensionConfig.positiveLabel,
              value: currentValue,
              onChanged: (newValue) {
                _updateTrait(index, newValue);
              },
              enabled: !widget.readonly,
            ),
          );
        }),
      ],
    );
  }

  /// 更新性格特质
  void _updateTrait(int index, int newValue) {
    setState(() {
      final dimension = PersonalityDimensions.allDimensions[index].dimension;
      final traitIndex = _traits.indexWhere((t) => t.dimension == dimension);

      if (traitIndex >= 0) {
        _traits[traitIndex] = _traits[traitIndex].copyWith(value: newValue);
      }

      // 通知父组件数据变化
      widget.onChanged?.call(_traits);
    });
  }

  /// 重置所有性格特质为中性（0）
  void _resetTraits() {
    setState(() {
      _traits = PersonalityDimensions.getDefaultTraits();
      // 通知父组件数据变化
      widget.onChanged?.call(_traits);
    });
  }

  /// 获取当前的性格特质列表
  List<PersonalityTrait> getTraits() {
    return List.from(_traits);
  }

  /// 检查是否有任何非零值
  bool hasNonZeroValues() {
    return _traits.any((trait) => trait.value != 0);
  }
}
