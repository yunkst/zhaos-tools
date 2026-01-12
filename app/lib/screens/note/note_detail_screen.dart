import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/models/note.dart';
import 'package:teacher_tools/providers/note_provider.dart';
import 'package:teacher_tools/providers/student_provider.dart';

/// 笔记详情页
class NoteDetailScreen extends StatefulWidget {
  final String noteId;

  const NoteDetailScreen({
    super.key,
    required this.noteId,
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  Note? _note;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNote();
  }

  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final noteId = int.parse(widget.noteId);
      final note = await context.read<NoteProvider>().getNoteById(noteId);

      if (mounted) {
        setState(() {
          _note = note;
          _isLoading = false;
          _error = note == null ? '记录不存在' : null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = '加载失败: $e';
        });
      }
    }
  }

  Future<void> _deleteNote() async {
    // 确认对话框
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这条记录吗？删除后无法恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('删除'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success = await context.read<NoteProvider>().deleteNote(_note!.id!);

      if (mounted) {
        if (success) {
          // 删除成功，返回列表页
          Navigator.of(context)
            ..pop() // 关闭详情页
            ..pop(); // 返回列表页

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已删除记录')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('删除失败，请重试')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 加载中
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('记录详情'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 错误状态
    if (_error != null || _note == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('记录详情'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                _error ?? '记录不存在',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('返回'),
              ),
            ],
          ),
        ),
      );
    }

    // 详情内容
    return Scaffold(
      appBar: AppBar(
        title: const Text('记录详情'),
        actions: [
          // 编辑按钮
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: '编辑',
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/notes/edit',
                arguments: {'noteId': widget.noteId},
              ).then((_) {
                // 编辑后刷新详情
                _loadNote();
              });
            },
          ),
          // 删除按钮
          IconButton(
            icon: const Icon(Icons.delete_outlined),
            tooltip: '删除',
            onPressed: _deleteNote,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 标题（如果有）
            if (_note!.title != null && _note!.title!.isNotEmpty) ...[
              Text(
                _note!.title!,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
            ],

            // 学生信息
            _InfoSection(
              icon: Icons.person_outline,
              title: '学生',
              child: Consumer<StudentProvider>(
                builder: (context, studentProvider, child) {
                  final student = studentProvider.students
                      .where((s) => s.id == _note!.studentId)
                      .firstOrNull;

                  if (student == null) {
                    return const Text('未知学生');
                  }

                  return Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.primaryContainer,
                        child: Text(
                          student.name.substring(0, 1),
                          style: TextStyle(
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style:
                                Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                          ),
                          Text(
                            '学号: ${student.studentNumber}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // 时间信息
            _InfoSection(
              icon: Icons.access_time,
              title: '时间',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(
                    label: '发生时间',
                    value: _formatDateTime(_note!.occurredAt),
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(
                    label: '创建时间',
                    value: _formatDateTime(_note!.createdAt),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 标签（如果有）
            if (_note!.tags.isNotEmpty) ...[
              _InfoSection(
                icon: Icons.local_offer_outlined,
                title: '标签',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _note!.tags.map((tag) {
                    return Chip(
                      label: Text(tag),
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // 记录内容
            _InfoSection(
              icon: Icons.note_outlined,
              title: '记录内容',
              child: Text(
                _note!.content,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeStr =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    if (date == today) {
      return '今天 $timeStr';
    } else {
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} $timeStr';
    }
  }
}

/// 信息区块组件
class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.grey[600],
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// 信息行组件
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            '$label:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
