import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/models/note.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:teacher_tools/providers/note_provider.dart';
import 'package:teacher_tools/providers/app_provider.dart';
import 'package:teacher_tools/utils/constants.dart';

/// 快速记录页 / 编辑页
class NoteCreateScreen extends StatefulWidget {
  final int? studentId;
  final String? noteId; // 编辑模式：传入笔记ID

  const NoteCreateScreen({
    super.key,
    this.studentId,
    this.noteId,
  });

  @override
  State<NoteCreateScreen> createState() => _NoteCreateScreenState();
}

class _NoteCreateScreenState extends State<NoteCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contentController = TextEditingController();
  final _titleController = TextEditingController();

  // 改为支持多选学生
  List<Student> _selectedStudents = [];
  // 事件类型已移除UI展示，保留以兼容数据库
  // NoteType _selectedType = NoteType.performance;
  DateTime _occurredAt = DateTime.now();
  final List<String> _selectedTags = [];

  // 编辑模式：原始笔记数据
  Note? _originalNote;
  bool _isEditMode = false;
  bool _isLoading = false;

  // 推荐标签
  final List<String> _recommendedTags = [
    '#积极',
    '#进步',
    '#优秀',
    '#待改进',
    '#表扬',
    '#提醒',
    '#作业',
    '#课堂',
  ];

  @override
  void initState() {
    super.initState();
    _isEditMode = widget.noteId != null;

    if (_isEditMode) {
      // 编辑模式：加载笔记数据
      _loadNote();
    } else if (widget.studentId != null) {
      // 创建模式：加载学生数据
      _loadStudent(widget.studentId!);
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _loadStudent(int studentId) async {
    final studentProvider = context.read<StudentProvider>();
    final student = await studentProvider.getStudentDetail(studentId);
    if (mounted && student != null) {
      setState(() {
        _selectedStudents = [student];
      });
    }
  }

  /// 编辑模式：加载笔记数据
  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final noteId = int.parse(widget.noteId!);
      final note = await context.read<NoteProvider>().getNoteById(noteId);

      if (note == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('记录不存在')),
          );
          Navigator.pop(context);
        }
        return;
      }

      // 加载学生信息
      // ignore: use_build_context_synchronously
      final studentProvider = context.read<StudentProvider>();
      final student = await studentProvider.getStudentDetail(note.studentId);

      if (mounted) {
        setState(() {
          _originalNote = note;
          _selectedStudents = student != null ? [student] : [];
          _titleController.text = note.title ?? '';
          _contentController.text = note.content;
          _occurredAt = note.occurredAt;
          _selectedTags.clear();
          _selectedTags.addAll(note.tags);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('加载失败: $e')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 加载中
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditMode ? '编辑记录' : '快速记录'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '编辑记录' : '快速记录'),
        actions: [
          TextButton(
            onPressed: _saveNote,
            child: Text(_isEditMode ? '更新' : '保存'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 选择学生（多选标签）
              _buildStudentSelector(),
              const SizedBox(height: 24),

              // 记录内容
              _buildContentSection(),
              const SizedBox(height: 24),

              // 发生时间
              _buildDateTimePicker(),
              const SizedBox(height: 24),

              // 添加标签
              _buildTagsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStudentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '选择学生',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        // 已选学生标签
        if (_selectedStudents.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedStudents.map((student) {
              return Chip(
                label: Text(student.name),
                avatar: CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    student.name.substring(0, 1),
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                onDeleted: () {
                  setState(() {
                    _selectedStudents.remove(student);
                  });
                },
                deleteIconColor: Theme.of(context).colorScheme.onSurface,
              );
            }).toList(),
          ),
        // 添加学生按钮
        InkWell(
          onTap: _showStudentSelector,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: _selectedStudents.isEmpty
                    ? Theme.of(context).colorScheme.outline
                    : Theme.of(context).colorScheme.primary,
                width: _selectedStudents.isEmpty ? 1 : 2,
              ),
              borderRadius: BorderRadius.circular(8),
              color: _selectedStudents.isEmpty
                  ? null
                  : Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: _selectedStudents.isEmpty
                      ? Colors.grey
                      : Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  _selectedStudents.isEmpty ? '添加学生' : '继续添加',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: _selectedStudents.isEmpty
                            ? Colors.grey
                            : Theme.of(context).colorScheme.primary,
                        fontWeight: _selectedStudents.isEmpty
                            ? FontWeight.normal
                            : FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (_selectedStudents.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '点击上方按钮添加学生',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ),
      ],
    );
  }

  Widget _buildContentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '记录内容 *',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: _contentController,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: '请输入记录内容...',
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入记录内容';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '发生时间',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _selectDateTime,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.access_time),
                const SizedBox(width: 12),
                Text(
                  _formatDateTime(_occurredAt),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                const Icon(Icons.arrow_drop_down),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '添加标签（可选）',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        if (_selectedTags.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    _selectedTags.remove(tag);
                  });
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
        ],
        Text(
          '推荐标签：',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recommendedTags.map((tag) {
            final isSelected = _selectedTags.contains(tag);
            return FilterChip(
              label: Text(tag),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedTags.add(tag);
                  } else {
                    _selectedTags.remove(tag);
                  }
                });
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }

  /// 显示学生选择器（支持搜索和多选）
  Future<void> _showStudentSelector() async {
    final studentProvider = context.read<StudentProvider>();

    if (studentProvider.students.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('暂无学生，请先添加学生')),
      );
      return;
    }

    // 临时存储选中的学生ID
    var selectedIds = _selectedStudents.map((s) => s.id!).toSet();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => _StudentSelectorSheet(
        initialSelectedIds: selectedIds,
        onSelectionChanged: (ids) {
          selectedIds = ids;
        },
        onConfirm: (selectedStudents) {
          setState(() {
            _selectedStudents = selectedStudents;
          });
        },
      ),
    );
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_occurredAt),
      );

      if (time != null && mounted) {
        setState(() {
          _occurredAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _saveNote() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请至少选择一个学生')),
      );
      return;
    }

    final appProvider = context.read<AppProvider>();
    final noteProvider = context.read<NoteProvider>();

    if (_isEditMode) {
      // 编辑模式：更新笔记
      final updatedNote = _originalNote!.copyWith(
        title: _titleController.text.trim().isEmpty
            ? null
            : _titleController.text.trim(),
        content: _contentController.text.trim(),
        tags: _selectedTags,
        occurredAt: _occurredAt,
      );

      final success = await noteProvider.updateNote(updatedNote);

      if (mounted) {
        if (success) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('已更新记录')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('更新失败，请重试')),
          );
        }
      }
    } else {
      // 创建模式：为每个选中的学生创建记录
      int successCount = 0;
      for (var student in _selectedStudents) {
        final note = Note(
          studentId: student.id!,
          classId: appProvider.currentClass!.id!,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          content: _contentController.text.trim(),
          // ignore: deprecated_member_use_from_same_package
          type: NoteType.other, // UI移除类型选择后，使用默认值（数据库兼容）
          tags: _selectedTags,
          occurredAt: _occurredAt,
        );

        final success = await noteProvider.addNote(note);
        if (success) {
          successCount++;
        }
      }

      if (successCount > 0 && mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('已为 $successCount 个学生添加记录')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (date == today) {
      return '今天 ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${dateTime.month}-${dateTime.day} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}

/// 学生选择器底部弹窗
class _StudentSelectorSheet extends StatefulWidget {
  final Set<int> initialSelectedIds;
  final Function(Set<int>) onSelectionChanged;
  final Function(List<Student>) onConfirm;

  const _StudentSelectorSheet({
    required this.initialSelectedIds,
    required this.onSelectionChanged,
    required this.onConfirm,
  });

  @override
  State<_StudentSelectorSheet> createState() => _StudentSelectorSheetState();
}

class _StudentSelectorSheetState extends State<_StudentSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  Set<int> _selectedIds = {};
  String _searchKeyword = '';
  String? _originalSearchKeyword;
  StudentProvider? _studentProvider; // 保存 Provider 引用

  @override
  void initState() {
    super.initState();
    _selectedIds = widget.initialSelectedIds;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // 在这里安全地访问 Provider 并保存引用
    if (_studentProvider == null) {
      _studentProvider = context.read<StudentProvider>();
      _originalSearchKeyword = _studentProvider!.searchKeyword;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    // 使用保存的 Provider 引用恢复原始搜索状态
    if (_originalSearchKeyword != null && _studentProvider != null) {
      _studentProvider!.setSearchKeyword(_originalSearchKeyword!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final studentProvider = context.watch<StudentProvider>();

    // 获取过滤后的学生
    final filteredStudents = studentProvider.filteredStudents;

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Column(
        children: [
          // AppBar
          AppBar(
            title: const Text('选择学生'),
            actions: [
              TextButton(
                onPressed: _confirmSelection,
                child: Text(
                  '确定(${_selectedIds.length})',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          // 搜索框
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: '搜索学生姓名或学号',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchKeyword.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchKeyword = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onChanged: (value) {
                setState(() {
                  _searchKeyword = value;
                });
                // 同步更新 Provider 的搜索关键词
                context.read<StudentProvider>().setSearchKeyword(value);
              },
            ),
          ),
          // 搜索结果统计
          if (_searchKeyword.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '找到 ${filteredStudents.length} 个学生',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                ),
              ),
            ),
          const Divider(height: 1),
          // 学生列表
          Expanded(
            child: filteredStudents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          '未找到匹配的学生',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filteredStudents.length,
                    itemBuilder: (context, index) {
                      final student = filteredStudents[index];
                      final isSelected = _selectedIds.contains(student.id!);

                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (value) {
                          setState(() {
                            if (value == true) {
                              _selectedIds.add(student.id!);
                            } else {
                              _selectedIds.remove(student.id!);
                            }
                            widget.onSelectionChanged(_selectedIds);
                          });
                        },
                        title: Text(
                          student.name,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        subtitle: Text(student.studentNumber),
                        secondary: isSelected
                            ? Icon(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _confirmSelection() {
    final studentProvider = context.read<StudentProvider>();

    // 获取选中的学生
    final selectedStudents = studentProvider.students
        .where((s) => _selectedIds.contains(s.id))
        .toList();

    widget.onConfirm(selectedStudents);
    Navigator.pop(context);
  }
}
