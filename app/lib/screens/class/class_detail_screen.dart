import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/models/class_model.dart';
import 'package:teacher_tools/providers/app_provider.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:teacher_tools/providers/note_provider.dart';
import 'package:teacher_tools/providers/exam_provider.dart';
import 'package:intl/intl.dart';

/// 班级详情页
class ClassDetailScreen extends StatefulWidget {
  final int classId;

  const ClassDetailScreen({super.key, required this.classId});

  @override
  State<ClassDetailScreen> createState() => _ClassDetailScreenState();
}

class _ClassDetailScreenState extends State<ClassDetailScreen> {
  ClassModel? _classModel;
  int _studentCount = 0;
  int _noteCount = 0;
  int _examCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // 延迟加载数据,避免在 build 期间触发 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    if (!mounted) return;

    final appProvider = context.read<AppProvider>();
    final classModel = appProvider.classes.firstWhere(
      (c) => c.id == widget.classId,
      orElse: () => appProvider.currentClass!,
    );

    // 加载统计数据
    final studentProvider = context.read<StudentProvider>();
    await studentProvider.loadStudents(widget.classId);
    if (!mounted) return;
    final studentCount = studentProvider.students.length;

    final noteProvider = context.read<NoteProvider>();
    await noteProvider.loadNotes(widget.classId);
    if (!mounted) return;
    final noteCount = noteProvider.notes.length;

    final examProvider = context.read<ExamProvider>();
    await examProvider.loadExams(widget.classId);
    if (!mounted) return;
    final examCount = examProvider.exams.length;

    if (mounted) {
      setState(() {
        _classModel = classModel;
        _studentCount = studentCount;
        _noteCount = noteCount;
        _examCount = examCount;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('班级详情'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_classModel == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('班级详情'),
        ),
        body: const Center(
          child: Text('班级不存在'),
        ),
      );
    }

    final isCurrentClass = context.watch<AppProvider>().currentClass?.id == _classModel!.id;

    return Scaffold(
      appBar: AppBar(
        title: const Text('班级详情'),
        actions: [
          if (!isCurrentClass)
            IconButton(
              icon: const Icon(Icons.swap_horiz),
              onPressed: _switchToClass,
              tooltip: '切换到此班级',
            ),
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _editClass,
          ),
          if (!isCurrentClass)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: _confirmDelete,
            ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 12),
                    Text('导出数据'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'refresh',
                child: Row(
                  children: [
                    Icon(Icons.refresh),
                    SizedBox(width: 12),
                    Text('刷新数据'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isCurrentClass),
            const SizedBox(height: 16),
            _buildClassInfoCard(),
            const SizedBox(height: 16),
            _buildStatisticsCard(),
            const SizedBox(height: 16),
            _buildQuickActionsCard(),
            const SizedBox(height: 16),
            _buildDataSections(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isCurrentClass) {
    return Card(
      color: isCurrentClass
          ? Theme.of(context).colorScheme.primaryContainer
          : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isCurrentClass
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.class_,
                size: 36,
                color: isCurrentClass
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _classModel!.name,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isCurrentClass) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
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
                        const SizedBox(width: 8),
                      ],
                      Text(
                        '创建于 ${DateFormat('yyyy年MM月dd日').format(_classModel!.createdAt)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClassInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '班级信息',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _buildInfoRow('班级名称', _classModel!.name),
            if (_classModel!.description != null &&
                _classModel!.description!.isNotEmpty) ...[
              _buildInfoRow('班级描述', _classModel!.description!),
            ],
            _buildInfoRow(
              '创建时间',
              DateFormat('yyyy-MM-dd HH:mm').format(_classModel!.createdAt),
            ),
            _buildInfoRow(
              '更新时间',
              DateFormat('yyyy-MM-dd HH:mm').format(_classModel!.updatedAt),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据统计',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.5,
              children: [
                _buildStatItem(
                  '学生',
                  _studentCount,
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatItem(
                  '笔记',
                  _noteCount,
                  Icons.edit_note,
                  Colors.green,
                ),
                _buildStatItem(
                  '考试',
                  _examCount,
                  Icons.quiz,
                  Colors.orange,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '快速操作',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.2,
              children: [
                _buildQuickAction(
                  '查看学生',
                  Icons.people,
                  Colors.blue,
                  () => _navigateToStudents(),
                ),
                _buildQuickAction(
                  '查看笔记',
                  Icons.edit_note,
                  Colors.green,
                  () => _navigateToNotes(),
                ),
                _buildQuickAction(
                  '查看考试',
                  Icons.quiz,
                  Colors.orange,
                  () => _navigateToExams(),
                ),
                _buildQuickAction(
                  '添加学生',
                  Icons.person_add,
                  Colors.purple,
                  () => _addStudent(),
                ),
                _buildQuickAction(
                  '快速记录',
                  Icons.note_add,
                  Colors.teal,
                  () => _addNote(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDataSections() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '数据管理',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.people, color: Colors.blue),
                title: const Text('学生列表'),
                subtitle: Text('共 $_studentCount 名学生'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _navigateToStudents,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_note, color: Colors.green),
                title: const Text('笔记记录'),
                subtitle: Text('共 $_noteCount 条记录'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _navigateToNotes,
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.quiz, color: Colors.orange),
                title: const Text('考试成绩'),
                subtitle: Text('共 $_examCount 场考试'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _navigateToExams,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchToClass() async {
    final success = await context.read<AppProvider>().switchClass(_classModel!);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已切换到 ${_classModel!.name}')),
      );
      setState(() {}); // 刷新UI
    }
  }

  void _editClass() {
    // TODO: 打开编辑班级页面
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('编辑功能开发中...')),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text(
          '确定要删除"${_classModel!.name}"吗？\n\n'
          '删除后将同时删除该班级的所有学生、笔记和成绩数据，此操作不可恢复。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteClass();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass() async {
    final success = await context.read<AppProvider>().deleteClass(_classModel!.id!);
    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('班级已删除')),
      );
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportData();
        break;
      case 'refresh':
        _loadData();
        break;
    }
  }

  void _exportData() {
    // TODO: 导出班级数据
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('导出功能开发中...')),
    );
  }

  void _navigateToStudents() {
    // TODO: 跳转到学生列表
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('跳转到学生列表')),
    );
  }

  void _navigateToNotes() {
    // TODO: 跳转到笔记列表
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('跳转到笔记列表')),
    );
  }

  void _navigateToExams() {
    // TODO: 跳转到考试列表
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('跳转到考试列表')),
    );
  }

  void _addStudent() {
    // TODO: 添加学生
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('添加学生功能开发中...')),
    );
  }

  void _addNote() {
    // TODO: 快速记录
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('快速记录功能开发中...')),
    );
  }
}
