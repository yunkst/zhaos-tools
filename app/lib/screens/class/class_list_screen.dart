import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/models/class_model.dart';
import 'package:teacher_tools/providers/app_provider.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:intl/intl.dart';

/// 班级管理页
class ClassListScreen extends StatefulWidget {
  const ClassListScreen({super.key});

  @override
  State<ClassListScreen> createState() => _ClassListScreenState();
}

class _ClassListScreenState extends State<ClassListScreen> {
  final Map<int, int> _studentCounts = {};

  @override
  void initState() {
    super.initState();
    _loadStudentCounts();
  }

  Future<void> _loadStudentCounts() async {
    final appProvider = context.read<AppProvider>();

    for (var classModel in appProvider.classes) {
      if (classModel.id != null) {
        final studentProvider = context.read<StudentProvider>();
        await studentProvider.loadStudents(classModel.id!);
        final count = studentProvider.students.length;

        if (mounted) {
          setState(() {
            _studentCounts[classModel.id!] = count;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('班级管理'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final classes = appProvider.classes;

          if (classes.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              await appProvider.refreshClasses();
              await _loadStudentCounts();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: classes.length,
              itemBuilder: (context, index) {
                return _buildClassCard(classes[index], appProvider.currentClass);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateClass,
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
            Icons.class_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有班级',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮创建班级',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(ClassModel classModel, ClassModel? currentClass) {
    final isCurrentClass = currentClass?.id == classModel.id;
    final studentCount = _studentCounts[classModel.id] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isCurrentClass ? 4 : 1,
      child: InkWell(
        onTap: () => _navigateToDetail(classModel),
        onLongPress: () => _showQuickActions(classModel),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: isCurrentClass
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary,
                    width: 2,
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.class_,
                            color: isCurrentClass
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey[600],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              classModel.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentClass
                                        ? Theme.of(context).colorScheme.primary
                                        : null,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentClass)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          '当前班级',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                if (classModel.description != null &&
                    classModel.description!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    classModel.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatChip(
                      Icons.people,
                      '学生',
                      '$studentCount',
                      Colors.blue,
                    ),
                    const SizedBox(width: 12),
                    _buildStatChip(
                      Icons.calendar_today,
                      '创建',
                      DateFormat('yyyy-MM-dd').format(classModel.createdAt),
                      Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (!isCurrentClass)
                      FilledButton.tonalIcon(
                        onPressed: () => _switchToClass(classModel),
                        icon: const Icon(Icons.swap_horiz, size: 18),
                        label: const Text('切换班级'),
                      ),
                    OutlinedButton.icon(
                      onPressed: () => _navigateToDetail(classModel),
                      icon: const Icon(Icons.visibility, size: 18),
                      label: const Text('查看详情'),
                    ),
                    IconButton(
                      onPressed: () => _showMoreOptions(classModel),
                      icon: const Icon(Icons.more_vert),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatChip(IconData iconData, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(iconData, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $value',
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchToClass(ClassModel classModel) async {
    final appProvider = context.read<AppProvider>();
    final success = await appProvider.switchClass(classModel);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已切换到 ${classModel.name}')),
      );
      // 刷新学生数量
      await _loadStudentCounts();
    }
  }

  void _navigateToDetail(ClassModel classModel) {
    // TODO: 打开班级详情页
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('查看 ${classModel.name} 详情')),
    );
  }

  void _navigateToCreateClass() {
    // TODO: 打开创建班级页
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('创建班级功能开发中...')),
    );
  }

  void _showQuickActions(ClassModel classModel) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('查看详情'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(classModel);
              },
            ),
            if (_isNotCurrentClass(classModel))
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('切换到此班级'),
                onTap: () {
                  Navigator.pop(context);
                  _switchToClass(classModel);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑班级'),
              onTap: () {
                Navigator.pop(context);
                _editClass(classModel);
              },
            ),
            if (_isNotCurrentClass(classModel))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除班级', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(classModel);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showMoreOptions(ClassModel classModel) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('查看详情'),
              onTap: () {
                Navigator.pop(context);
                _navigateToDetail(classModel);
              },
            ),
            if (_isNotCurrentClass(classModel))
              ListTile(
                leading: const Icon(Icons.swap_horiz),
                title: const Text('切换到此班级'),
                onTap: () {
                  Navigator.pop(context);
                  _switchToClass(classModel);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('编辑班级'),
              onTap: () {
                Navigator.pop(context);
                _editClass(classModel);
              },
            ),
            if (_isNotCurrentClass(classModel))
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('删除班级', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(classModel);
                },
              ),
          ],
        ),
      ),
    );
  }

  bool _isNotCurrentClass(ClassModel classModel) {
    final currentClass = context.read<AppProvider>().currentClass;
    return currentClass?.id != classModel.id;
  }

  void _editClass(ClassModel classModel) {
    // TODO: 打开编辑班级页
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能开发中...')),
    );
  }

  void _confirmDelete(ClassModel classModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('确定要删除"${classModel.name}"吗？\n\n删除后将同时删除该班级的所有学生、笔记和成绩数据。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteClass(classModel);
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass(ClassModel classModel) async {
    final success = await context.read<AppProvider>().deleteClass(classModel.id!);

    if (success && mounted) {
      setState(() {
        _studentCounts.remove(classModel.id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('班级已删除')),
      );
    }
  }
}
