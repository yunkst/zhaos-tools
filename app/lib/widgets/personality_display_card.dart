import 'package:flutter/material.dart';
import 'package:teacher_tools/models/personality_trait.dart';
import 'package:teacher_tools/widgets/personality_form.dart';

/// 性格展示卡片组件
/// 展示性格特质列表，支持查看和编辑模式
class PersonalityDisplayCard extends StatefulWidget {
  final List<PersonalityTrait>? traits;
  final bool readonly;
  final Function(List<PersonalityTrait>)? onUpdate;
  final bool showChart;

  const PersonalityDisplayCard({
    super.key,
    this.traits,
    this.readonly = false,
    this.onUpdate,
    this.showChart = true,
  });

  @override
  State<PersonalityDisplayCard> createState() => _PersonalityDisplayCardState();
}

class _PersonalityDisplayCardState extends State<PersonalityDisplayCard> {
  bool _isEditing = false;
  late List<PersonalityTrait> _traits;

  @override
  void initState() {
    super.initState();
    // 如果没有提供性格特质，使用默认值（全部为0）
    _traits = widget.traits ?? PersonalityDimensions.getDefaultTraits();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题栏
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.psychology, color: Colors.purple),
                    const SizedBox(width: 8),
                    Text(
                      '性格特质画像',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                if (!widget.readonly && widget.onUpdate != null)
                  _buildActionButton(context),
              ],
            ),

            const SizedBox(height: 16),

            // 内容区域
            if (_isEditing)
              _buildEditMode()
            else
              _buildViewMode(theme),
          ],
        ),
      ),
    );
  }

  /// 构建操作按钮（编辑/保存/取消）
  Widget _buildActionButton(BuildContext context) {
    if (_isEditing) {
      // 编辑模式不在标题栏显示按钮
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: _startEdit,
      icon: const Icon(Icons.edit, size: 18),
      label: const Text('编辑'),
      style: TextButton.styleFrom(
        foregroundColor: Colors.blue,
      ),
    );
  }

  /// 构建编辑模式的底部按钮（取消/保存）
  Widget _buildEditButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        TextButton.icon(
          onPressed: _cancelEdit,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('取消'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: _saveChanges,
          icon: const Icon(Icons.save, size: 18),
          label: const Text('保存'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.green,
            backgroundColor: Colors.green.shade50,
          ),
        ),
      ],
    );
  }

  /// 查看模式：特质列表
  Widget _buildViewMode(ThemeData theme) {
    final hasData = _hasNonZeroTraits();

    if (!hasData) {
      return _buildEmptyState(context);
    }

    return Column(
      children: [
        // 特质列表（只读）
        ..._buildTraitListTiles(theme),
      ],
    );
  }

  /// 编辑模式：性格表单
  Widget _buildEditMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PersonalityForm(
          initialTraits: _traits,
          readonly: false,
          showResetButton: true,
          onChanged: (updatedTraits) {
            // 实时更新本地数据
            _traits = updatedTraits;
          },
        ),
        const SizedBox(height: 24),
        _buildEditButtons(),
      ],
    );
  }

  /// 构建特质列表（只读）
  List<Widget> _buildTraitListTiles(ThemeData theme) {
    return _traits.map((trait) {
      if (trait.value == 0) return const SizedBox.shrink();

      final isPositive = trait.value > 0;
      final color = isPositive ? Colors.green : Colors.red;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            // 维度名称
            Expanded(
              flex: 2,
              child: Text(
                trait.dimension,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            // 分隔符
            const Text(':', style: TextStyle(fontSize: 16)),

            const SizedBox(width: 8),

            // 数值徽章
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 14,
                    color: color,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    trait.value.toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // 当前标签
            Expanded(
              flex: 3,
              child: Text(
                trait.currentLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }).toList();
  }

  /// 构建空状态
  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.psychology_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              '暂无性格数据',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.readonly
                  ? '该学生的性格特质尚未评估'
                  : '点击下方按钮开始评估学生性格特质',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            if (!widget.readonly && widget.onUpdate != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _startEdit,
                icon: const Icon(Icons.edit),
                label: const Text('开始评估'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 开始编辑
  void _startEdit() {
    setState(() {
      _isEditing = true;
    });
  }

  /// 取消编辑
  void _cancelEdit() {
    setState(() {
      _isEditing = false;
      // 恢复原始数据
      _traits = widget.traits ?? PersonalityDimensions.getDefaultTraits();
    });
  }

  /// 保存更改
  void _saveChanges() {
    // 从表单获取数据（这里简化处理，实际需要从PersonalityForm获取）
    // 由于PersonalityForm是StatefulWidget，需要通过GlobalKey访问
    if (widget.onUpdate != null) {
      widget.onUpdate!(_traits);
    }

    setState(() {
      _isEditing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('性格特质已更新'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  /// 检查是否有非零的特质值
  bool _hasNonZeroTraits() {
    return _traits.any((trait) => trait.value != 0);
  }
}
