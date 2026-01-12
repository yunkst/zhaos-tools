import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/models/exam_group.dart';
import 'package:teacher_tools/providers/exam_provider.dart';
import 'package:teacher_tools/providers/app_provider.dart';
import 'package:teacher_tools/screens/exam/exam_group_detail_screen.dart';

/// 成绩管理页（按考试组展示）
class ExamListScreen extends StatefulWidget {
  const ExamListScreen({super.key});

  @override
  State<ExamListScreen> createState() => _ExamListScreenState();
}

class _ExamListScreenState extends State<ExamListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadExamGroups();
    });
  }

  Future<void> _loadExamGroups() async {
    final appProvider = context.read<AppProvider>();
    if (appProvider.currentClass != null) {
      await context.read<ExamProvider>().loadExamGroups(appProvider.currentClass!.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('成绩管理'),
      ),
      body: Consumer<ExamProvider>(
        builder: (context, examProvider, child) {
          if (examProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          final examGroups = examProvider.examGroups;

          if (examGroups.isEmpty) {
            return _buildEmptyState();
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: examGroups.length,
            itemBuilder: (context, index) {
              return _buildExamGroupCard(examGroups[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToImport,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.quiz_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有考试记录',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮导入考试',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildExamGroupCard(ExamGroup examGroup) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => _navigateToDetail(examGroup),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                children: [
                  Icon(
                    Icons.assessment_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      examGroup.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _confirmDelete(examGroup),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 信息行
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    examGroup.formattedDate,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.label, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    examGroup.typeText,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.people, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${examGroup.totalStudents}人',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 科目统计行
              if (examGroup.hasStatistics) ...[
                _buildSubjectsRow(examGroup),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '暂无统计数据',
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // 查看详情按钮
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _navigateToDetail(examGroup),
                  icon: const Icon(Icons.visibility),
                  label: const Text('查看详情'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubjectsRow(ExamGroup examGroup) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: examGroup.subjects.map((subject) {
        final color = _getSubjectColor(subject.subject.value);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Text(
                subject.subjectText,
                style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (subject.averageScore != null)
                Text(
                  subject.averageScore!.toStringAsFixed(1),
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                )
              else
                Text(
                  '-',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getSubjectColor(String value) {
    switch (value) {
      case 'math':
        return Colors.blue;
      case 'chinese':
        return Colors.red;
      case 'english':
        return Colors.green;
      case 'science':
        return Colors.purple;
      case 'morality':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Future<void> _navigateToDetail(ExamGroup examGroup) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamGroupDetailScreen(examGroup: examGroup),
      ),
    );
    _loadExamGroups();
  }

  Future<void> _navigateToImport() async {
    // 触发首页的导入功能
    Navigator.pop(context);
  }

  void _confirmDelete(ExamGroup examGroup) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${examGroup.name}"吗？\n删除后将同时删除所有相关成绩数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteExamGroup(examGroup);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteExamGroup(ExamGroup examGroup) async {
    final success = await context.read<ExamProvider>().deleteExamGroup(examGroup.examGroupId);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('考试已删除')),
      );
    }
  }
}
