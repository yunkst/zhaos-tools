import 'package:flutter/material.dart';
import 'package:teacher_tools/screens/ai/batch_comment_generation_screen.dart';

/// 批量AI功能列表页面
/// 展示所有可用的批量AI功能
class BatchAiFunctionListScreen extends StatelessWidget {
  final List<int> selectedStudentIds;
  final List<String> selectedStudentNames;

  const BatchAiFunctionListScreen({
    super.key,
    required this.selectedStudentIds,
    required this.selectedStudentNames,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('批量AI助手 (已选${selectedStudentIds.length}人)'),
      ),
      body: ListView(
        children: [
          // 已选学生预览
          _buildSelectedStudentsCard(),
          const SizedBox(height: 8),

          // AI功能列表
          _buildFunctionCard(
            context,
            icon: Icons.edit_note,
            title: '生成期末评语',
            subtitle: '根据学生信息和随笔记录批量生成个性化评语',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BatchCommentGenerationScreen(
                    studentIds: selectedStudentIds,
                    studentNames: selectedStudentNames,
                  ),
                ),
              );
            },
          ),
          // 预留：未来可以添加更多批量AI功能
          // _buildFunctionCard(
          //   context,
          //   icon: Icons.psychology,
          //   title: '批量学习建议',
          //   subtitle: '基于学生表现批量生成个性化学习建议',
          //   color: Colors.green,
          //   onTap: () {},
          // ),
        ],
      ),
    );
  }

  /// 构建已选学生预览卡片
  Widget _buildSelectedStudentsCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.people, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '已选择 ${selectedStudentIds.length} 名学生',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // 显示学生姓名列表（最多显示5个）
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: selectedStudentNames.take(5).map((name) {
                return Chip(
                  label: Text(name),
                  labelStyle: const TextStyle(fontSize: 12),
                );
              }).toList(),
            ),
            if (selectedStudentNames.length > 5) ...[
              const SizedBox(height: 4),
              Text(
                '...等 ${selectedStudentNames.length} 人',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建功能卡片
  Widget _buildFunctionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
