import 'package:flutter/material.dart';

/// AI功能列表页面
/// 展示所有可用的AI功能
class AiFunctionListScreen extends StatelessWidget {
  final int studentId;
  final String studentName;

  const AiFunctionListScreen({
    super.key,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('AI 助手 - $studentName'),
      ),
      body: ListView(
        children: [
          _buildFunctionCard(
            context,
            icon: Icons.edit_note,
            title: '生成期末评语',
            subtitle: '根据学生信息和随笔记录生成个性化评语',
            color: Colors.blue,
            onTap: () {
              Navigator.pushNamed(
                context,
                '/ai/comment-generation',
                arguments: {'studentId': studentId},
              );
            },
          ),
          // 预留：未来可以添加更多AI功能
          // _buildFunctionCard(
          //   context,
          //   icon: Icons.psychology,
          //   title: '学习建议',
          //   subtitle: '基于学生表现生成个性化学习建议',
          //   color: Colors.green,
          //   onTap: () {},
          // ),
        ],
      ),
    );
  }

  Widget _buildFunctionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.all(16),
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
