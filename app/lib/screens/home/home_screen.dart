import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teacher_tools/providers/app_provider.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:teacher_tools/providers/note_provider.dart';
import 'package:teacher_tools/providers/exam_provider.dart';
import 'package:teacher_tools/screens/student/student_list_screen.dart';
import 'package:teacher_tools/screens/student/student_form_screen.dart';
import 'package:teacher_tools/screens/note/note_create_screen.dart';
import 'package:teacher_tools/screens/exam/exam_list_screen.dart';
import 'package:teacher_tools/screens/exam/exam_group_detail_screen.dart';
import 'package:teacher_tools/screens/exam/score_import_dialog.dart';
import 'package:teacher_tools/screens/class/class_list_screen.dart';
import 'package:teacher_tools/screens/settings/settings_screen.dart';

/// 首页（仪表板）
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // 延迟加载数据,避免在 build 期间触发 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final appProvider = context.read<AppProvider>();
    final classId = appProvider.currentClass?.id;

    if (classId != null) {
      await Future.wait([
        context.read<StudentProvider>().loadStudents(classId),
        context.read<NoteProvider>().loadNotes(classId),
        context.read<NoteProvider>().loadRecentNotes(classId),
        context.read<ExamProvider>().loadExamGroups(classId),  // 改为加载考试组
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildClassOverview(),
              const SizedBox(height: 24),
              _buildQuickActions(),
              const SizedBox(height: 24),
              _buildRecentNotes(),
              const SizedBox(height: 24),
              _buildRecentExams(),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final className = appProvider.currentClass?.name ?? '未知班级';
          return Text(className);
        },
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.swap_horiz),
          onPressed: _showClassMenu,
          tooltip: '切换班级',
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () => _navigateToSettings(),
          tooltip: '设置',
        ),
      ],
    );
  }

  Widget _buildClassOverview() {
    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        final classId = appProvider.currentClass?.id;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.analytics_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '班级概况',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (classId != null)
                  Consumer3<StudentProvider, NoteProvider, ExamProvider>(
                    builder: (context, studentProvider, noteProvider, examProvider, child) {
                      final studentCount = studentProvider.students.length;
                      final noteCount = noteProvider.notes.length;
                      final examCount = examProvider.examGroups.length;

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            context,
                            Icons.people_outline,
                            '学生数',
                            '$studentCount人',
                          ),
                          _buildStatItem(
                            context,
                            Icons.edit_note_outlined,
                            '记录',
                            '$noteCount条',
                          ),
                          _buildStatItem(
                            context,
                            Icons.quiz_outlined,
                            '考试',
                            '$examCount场',
                            onTap: () => _navigateToExamList(),
                          ),
                        ],
                      );
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.bolt_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              '快速操作',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          children: [
            _buildQuickActionCard(
              context,
              Icons.edit_note_outlined,
              '记录随笔',
              Colors.blue,
              () => _handleQuickAction('note'),
            ),
            _buildQuickActionCard(
              context,
              Icons.quiz_outlined,
              '录入成绩',
              Colors.green,
              () => _handleQuickAction('score'),
            ),
            _buildQuickActionCard(
              context,
              Icons.people_outline,
              '查看学生',
              Colors.orange,
              () => _handleQuickAction('student'),
            ),
            _buildQuickActionCard(
              context,
              Icons.person_add_outlined,
              '添加学生',
              Colors.purple,
              () => _handleQuickAction('add_student'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentNotes() {
    return Consumer<NoteProvider>(
      builder: (context, noteProvider, child) {
        final notes = noteProvider.recentNotes;

        if (notes.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '最近记录',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _navigateToNoteList(),
                  child: const Text('查看更多'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...notes.take(3).map((note) => _buildNoteItem(context, note)),
          ],
        );
      },
    );
  }

  Widget _buildNoteItem(BuildContext context, note) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(
            context,
            '/notes/detail',
            arguments: {'noteId': note.id.toString()},
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: CircleAvatar(
            child: Text(
              note.content.substring(0, 1),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            note.content,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(_formatTime(note.occurredAt)),
        ),
      ),
    );
  }

  Widget _buildRecentExams() {
    return Consumer<ExamProvider>(
      builder: (context, examProvider, child) {
        final examGroups = examProvider.examGroups;

        if (examGroups.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '最近考试',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _navigateToExamList(),
                  child: const Text('查看更多'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...examGroups.take(2).map((examGroup) => _buildExamGroupItem(context, examGroup)),
          ],
        );
      },
    );
  }

  Widget _buildExamGroupItem(BuildContext context, examGroup) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => _navigateToExamGroupDetail(examGroup),
        borderRadius: BorderRadius.circular(8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.assessment,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          title: Text(examGroup.name),
          subtitle: Text('${_formatDate(examGroup.examDate)} · ${examGroup.subjectCount}科'),
          trailing: examGroup.hasStatistics
              ? Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${examGroup.overallAverage?.toStringAsFixed(1) ?? '-'}分',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${examGroup.totalStudents}人',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                )
              : null,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}分钟前';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}小时前';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}天前';
    } else {
      return '${dateTime.month}-${dateTime.day}';
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  void _handleQuickAction(String action) {
    switch (action) {
      case 'note':
        _navigateToNoteCreate();
        break;
      case 'score':
        _navigateToExamCreate();
        break;
      case 'student':
        _navigateToStudentList();
        break;
      case 'add_student':
        _navigateToAddStudent();
        break;
    }
  }

  Future<void> _showClassMenu() async {
    final appProvider = context.read<AppProvider>();

    if (appProvider.classes.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无其他班级可切换')),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      builder: (context) => Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          final classes = appProvider.classes;
          final currentClassId = appProvider.currentClass?.id;

          return SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(title: const Text('选择班级')),
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: classes.length,
                    itemBuilder: (context, index) {
                      final classModel = classes[index];
                      final isCurrent = classModel.id == currentClassId;

                      return ListTile(
                        leading: Icon(
                          isCurrent ? Icons.check_circle : Icons.circle_outlined,
                          color: isCurrent ? Colors.green : Colors.grey,
                        ),
                        title: Text(
                          classModel.name,
                          style: TextStyle(
                            fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: isCurrent
                            ? Chip(
                                label: const Text('当前', style: TextStyle(fontSize: 12)),
                                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              )
                            : null,
                        onTap: () async {
                          Navigator.pop(context);
                          if (!isCurrent) {
                            await appProvider.switchClass(classModel);
                            if (!context.mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('已切换到 ${classModel.name}')),
                            );
                            _loadData();
                          }
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(context);
                      _navigateToClassList();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('管理班级'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _navigateToStudentList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const StudentListScreen()),
    );
    _loadData();
  }

  Future<void> _navigateToAddStudent() async {
    final appProvider = context.read<AppProvider>();
    if (appProvider.currentClass == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择班级')),
        );
      }
      return;
    }

    // 显示选择对话框
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('添加学生'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload, color: Colors.blue),
              title: const Text('Excel批量导入'),
              subtitle: const Text('从Excel文件导入学生数据（推荐）'),
              onTap: () => Navigator.pop(context, 'excel'),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.green),
              title: const Text('手动添加'),
              subtitle: const Text('手动填写学生信息'),
              onTap: () => Navigator.pop(context, 'manual'),
            ),
          ],
        ),
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == 'excel') {
      await _importStudentsFromExcel();
    } else if (choice == 'manual') {
      await _openStudentForm();
    }
  }

  Future<void> _importStudentsFromExcel() async {
    // 显示加载对话框
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('正在导入...'),
              ],
            ),
          ),
        ),
      ),
    );

    final appProvider = context.read<AppProvider>();
    final result = await context.read<StudentProvider>().importStudentsFromExcel(
      appProvider.currentClass!.id!,
    );

    if (mounted) {
      Navigator.pop(context); // 关闭加载对话框

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] as String),
          backgroundColor: (result['success'] as bool) ? Colors.green : Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );

      // 刷新数据
      if (result['success'] as bool) {
        _loadData();
      }
    }
  }

  Future<void> _openStudentForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentFormScreen(),
      ),
    );

    if (result == true) {
      _loadData();
    }
  }

  Future<void> _navigateToNoteCreate() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NoteCreateScreen()),
    );
    _loadData();
  }

  Future<void> _navigateToNoteList() async {
    await Navigator.pushNamed(context, '/notes');
    _loadData();
  }

  Future<void> _navigateToExamList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExamListScreen()),
    );
    _loadData();
  }

  Future<void> _navigateToExamCreate() async {
    // 直接打开Excel文件选择
    await _importScoresFromExcel();
  }

  /// 从Excel导入成绩
  Future<void> _importScoresFromExcel() async {
    try {
      // 使用 file_picker 选择 Excel 文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls'],
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        // 用户取消选择
        return;
      }

      final filePath = result.files.single.path;
      if (filePath == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('无法获取文件路径')),
          );
        }
        return;
      }

      // 验证文件扩展名
      if (!filePath.endsWith('.xlsx') && !filePath.endsWith('.xls')) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('请选择Excel文件(.xlsx或.xls)')),
          );
        }
        return;
      }

      // 打开导入对话框
      if (mounted) {
        final file = File(filePath);
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ScoreImportDialog(excelFile: file),
            fullscreenDialog: true,
          ),
        );

        // 刷新数据
        _loadData();
      }
    } catch (e) {
      debugPrint('❌ 选择Excel文件失败: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('选择文件失败: $e')),
        );
      }
    }
  }

  Future<void> _navigateToExamGroupDetail(examGroup) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExamGroupDetailScreen(examGroup: examGroup),
      ),
    );
    _loadData();
  }

  Future<void> _navigateToClassList() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ClassListScreen()),
    );
    _loadData();
  }

  Future<void> _navigateToSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SettingsScreen()),
    );
    _loadData();
  }
}
