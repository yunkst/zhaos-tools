import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:teacher_tools/providers/app_provider.dart';
import 'package:teacher_tools/screens/student/student_detail_screen.dart';
import 'package:teacher_tools/screens/student/student_form_screen.dart';
import 'package:teacher_tools/screens/student/student_note_list_screen.dart';
import 'package:teacher_tools/screens/ai/batch_ai_function_list_screen.dart';

/// 学生列表页
class StudentListScreen extends StatefulWidget {
  const StudentListScreen({super.key});

  @override
  State<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends State<StudentListScreen> {
  final TextEditingController _searchController = TextEditingController();

  // 多选状态
  bool _isSelectionMode = false;
  final Set<int> _selectedStudentIds = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// 切换选择模式
  void _toggleSelectionMode() {
    setState(() {
      _isSelectionMode = !_isSelectionMode;
      if (!_isSelectionMode) {
        _selectedStudentIds.clear();
      }
    });
  }

  /// 切换学生选中状态
  void _toggleStudentSelection(int studentId) {
    setState(() {
      if (_selectedStudentIds.contains(studentId)) {
        _selectedStudentIds.remove(studentId);
      } else {
        _selectedStudentIds.add(studentId);
      }
    });
  }

  /// 全选/取消全选
  void _toggleSelectAll(List<Student> students) {
    setState(() {
      if (_selectedStudentIds.length == students.length) {
        // 已全选，则取消全选
        _selectedStudentIds.clear();
      } else {
        // 全选
        _selectedStudentIds.clear();
        for (var student in students) {
          _selectedStudentIds.add(student.id!);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSelectionMode ? '已选 ${_selectedStudentIds.length} 人' : '学生列表'),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (!_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: '多选',
            ),
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _showSearchDialog,
            ),
          ],
          if (_isSelectionMode) ...[
            Consumer<StudentProvider>(
              builder: (context, studentProvider, child) {
                return TextButton(
                  onPressed: () {
                    _toggleSelectAll(studentProvider.filteredStudents);
                  },
                  child: Text(
                    _selectedStudentIds.length == studentProvider.filteredStudents.length
                        ? '取消全选'
                        : '全选',
                  ),
                );
              },
            ),
            if (_selectedStudentIds.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.smart_toy),
                onPressed: () => _openBatchAiFunctions(context),
                tooltip: 'AI功能',
              ),
          ],
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, studentProvider, child) {
          final students = studentProvider.filteredStudents;

          if (students.isEmpty) {
            return _buildEmptyState();
          }

          return Column(
            children: [
              _buildFilterChips(),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    return _buildStudentCard(students[index]);
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddStudent,
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
            Icons.people_outline,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '还没有学生',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮添加学生',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    return Consumer<StudentProvider>(
      builder: (context, studentProvider, child) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip(
                label: '全部',
                isSelected: studentProvider.genderFilter == null,
                onSelected: () {
                  studentProvider.clearFilters();
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: '男',
                isSelected: studentProvider.genderFilter == 'male',
                onSelected: () {
                  studentProvider.setGenderFilter('male');
                },
              ),
              const SizedBox(width: 8),
              _buildFilterChip(
                label: '女',
                isSelected: studentProvider.genderFilter == 'female',
                onSelected: () {
                  studentProvider.setGenderFilter('female');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      selectedColor: Theme.of(context).colorScheme.primaryContainer,
    );
  }

  Widget _buildStudentCard(Student student) {
    final isSelected = _selectedStudentIds.contains(student.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          if (_isSelectionMode) {
            _toggleStudentSelection(student.id!);
          } else {
            _navigateToDetail(student);
          }
        },
        onLongPress: () {
          if (!_isSelectionMode) {
            _toggleSelectionMode();
            _toggleStudentSelection(student.id!);
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 多选复选框
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (_) => _toggleStudentSelection(student.id!),
                  ),
                ),
              // 学生信息
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          child: Text(
                            student.name.substring(0, 1),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                student.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '学号: ${student.studentNumber}',
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (!_isSelectionMode)
                          _buildNoteCountButton(student),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.contact_phone, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          '${student.parentName} ${student.parentPhone}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (student.hasPosition)
                          Chip(
                            label: Text(student.classPosition!),
                            avatar: const Icon(Icons.star, size: 16),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        if (student.isCommitteeMember)
                          Chip(
                            label: Text(student.committeePosition!),
                            avatar: const Icon(Icons.groups, size: 16),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                        if (student.personality != null && student.personality!.isNotEmpty)
                          Chip(
                            label: Text(student.personality!),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSearchDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('搜索学生'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            hintText: '输入姓名或学号',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            context.read<StudentProvider>().setSearchKeyword(value);
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('完成'),
          ),
        ],
      ),
    );
  }

  void _navigateToDetail(Student student) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentDetailScreen(studentId: student.id!),
      ),
    );
    // 刷新数据
    if (mounted) {
      final appProvider = context.read<AppProvider>();
      await context.read<StudentProvider>().loadStudents(appProvider.currentClass!.id!);
    }
  }

  Future<void> _navigateToAddStudent() async {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload, color: Colors.blue),
              title: const Text('Excel批量导入'),
              subtitle: const Text('从Excel文件导入学生数据'),
              onTap: () {
                Navigator.pop(context);
                _importFromExcel();
              },
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.green),
              title: const Text('手动添加'),
              subtitle: const Text('手动填写学生信息'),
              onTap: () {
                Navigator.pop(context);
                _openManualAddForm();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _importFromExcel() async {
    final appProvider = context.read<AppProvider>();
    if (appProvider.currentClass == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择班级')),
        );
      }
      return;
    }

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
    }
  }

  Future<void> _openManualAddForm() async {
    final appProvider = context.read<AppProvider>();
    if (appProvider.currentClass == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('请先选择班级')),
        );
      }
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudentFormScreen(),
      ),
    );

    if (result == true && mounted) {
      // 刷新数据
      await context.read<StudentProvider>().loadStudents(appProvider.currentClass!.id!);
    }
  }

  /// 打开批量AI功能列表
  void _openBatchAiFunctions(BuildContext context) {
    final students = context.read<StudentProvider>().filteredStudents;
    final selectedStudents = students.where((s) => _selectedStudentIds.contains(s.id)).toList();
    final selectedIds = selectedStudents.map((s) => s.id!).toList();
    final selectedNames = selectedStudents.map((s) => s.name).toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BatchAiFunctionListScreen(
          selectedStudentIds: selectedIds,
          selectedStudentNames: selectedNames,
        ),
      ),
    ).then((_) {
      // 返回后退出选择模式
      if (mounted) {
        setState(() {
          _isSelectionMode = false;
          _selectedStudentIds.clear();
        });
      }
    });
  }

  /// 构建随笔数量按钮
  Widget _buildNoteCountButton(Student student) {
    final noteCount = student.noteCount ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => StudentNoteListScreen(
              studentId: student.id!,
              studentName: student.name,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Icon(
              Icons.edit_note,
              size: 24,
              color: noteCount > 0 ? Colors.blue : Colors.grey,
            ),
            if (noteCount > 0)
              Positioned(
                right: -6,
                top: -6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    noteCount > 99 ? '99+' : '$noteCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
