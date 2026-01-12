import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:teacher_tools/providers/note_provider.dart';
import 'package:teacher_tools/providers/score_provider.dart';
import 'package:teacher_tools/widgets/personality_display_card.dart';
import 'package:teacher_tools/utils/constants.dart';
import 'package:teacher_tools/screens/note/note_create_screen.dart';
import 'package:teacher_tools/screens/score/student_score_screen.dart';
import 'package:intl/intl.dart';

/// 学生详情页
class StudentDetailScreen extends StatefulWidget {
  final int studentId;

  const StudentDetailScreen({super.key, required this.studentId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  Student? _student;
  int _noteCount = 0;

  // 编辑模式状态
  bool _isEditing = false;

  // TextEditingController 管理器
  final Map<String, TextEditingController> _controllers = {};

  // 特殊字段状态
  Gender? _selectedGender;
  DateTime? _selectedBirthDate;

  @override
  void initState() {
    super.initState();
    // 延迟加载数据,避免在 build 期间触发 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadStudentData();
    });
  }

  @override
  void dispose() {
    // 释放所有 controllers
    _controllers.forEach((key, controller) => controller.dispose());
    _controllers.clear();
    super.dispose();
  }

  Future<void> _loadStudentData() async {
    final studentProvider = context.read<StudentProvider>();
    final noteProvider = context.read<NoteProvider>();

    final student = await studentProvider.getStudentDetail(widget.studentId);
    final noteCount = await noteProvider.getStudentNoteCount(widget.studentId);

    if (mounted) {
      setState(() {
        _student = student;
        _noteCount = noteCount;
      });
    }
  }

  // 初始化 controllers
  void _initControllers() {
    _controllers.clear();

    if (_student == null) return;

    // 初始化特殊字段
    _selectedGender = _student!.gender;
    _selectedBirthDate = _student!.birthDate;

    // 基本信息
    _controllers['name'] = TextEditingController(text: _student!.name);
    _controllers['studentNumber'] = TextEditingController(text: _student!.studentNumber);
    _controllers['height'] = TextEditingController(text: _student!.height?.toString() ?? '');
    _controllers['vision'] = TextEditingController(text: _student!.vision ?? '');
    _controllers['address'] = TextEditingController(text: _student!.address ?? '');

    // 家长信息
    _controllers['parentTitle'] = TextEditingController(text: _student!.parentTitle ?? '');
    _controllers['parentName'] = TextEditingController(text: _student!.parentName);
    _controllers['parentPhone'] = TextEditingController(text: _student!.parentPhone);
    _controllers['parentCompany'] = TextEditingController(text: _student!.parentCompany ?? '');
    _controllers['parentPosition'] = TextEditingController(text: _student!.parentPosition ?? '');

    // 第二家长 - 始终创建controller,即使为空
    _controllers['parentTitle2'] = TextEditingController(text: _student!.parentTitle2 ?? '');
    _controllers['parentName2'] = TextEditingController(text: _student!.parentName2 ?? '');
    _controllers['parentPhone2'] = TextEditingController(text: _student!.parentPhone2 ?? '');
    _controllers['parentCompany2'] = TextEditingController(text: _student!.parentCompany2 ?? '');
    _controllers['parentPosition2'] = TextEditingController(text: _student!.parentPosition2 ?? '');

    // 职务信息 - 始终创建controller,即使为空
    _controllers['classPosition'] = TextEditingController(text: _student!.classPosition ?? '');
    _controllers['committeePosition'] = TextEditingController(text: _student!.committeePosition ?? '');
  }

  // 释放 controllers
  void _disposeControllers() {
    _controllers.forEach((key, controller) => controller.dispose());
    _controllers.clear();
  }

  // 切换编辑模式
  void _toggleEdit() async {
    if (_isEditing) {
      // 退出编辑模式，保存更改
      await _saveChanges();
    } else {
      // 进入编辑模式
      setState(() {
        _isEditing = true;
        _initControllers();
      });
    }
  }

  // 保存更改
  Future<void> _saveChanges() async {
    if (_student == null) return;

    try {
      final provider = context.read<StudentProvider>();

      // 辅助函数:获取文本值,如果为空则返回null
      String? getTextValue(String? key) {
        if (key == null) return null;
        final controller = _controllers[key];
        if (controller == null) return null;
        final text = controller.text.trim();
        return text.isEmpty ? null : text;
      }

      // 构建更新后的学生对象
      final updatedStudent = _student!.copyWith(
        name: _controllers['name']?.text.trim() ?? _student!.name,
        studentNumber: _controllers['studentNumber']?.text.trim() ?? _student!.studentNumber,
        gender: _selectedGender ?? _student!.gender,
        birthDate: _selectedBirthDate ?? _student!.birthDate,
        height: double.tryParse(_controllers['height']?.text.trim() ?? ''),
        vision: Value(getTextValue('vision')),
        address: Value(getTextValue('address')),
        parentTitle: Value(getTextValue('parentTitle')),
        parentName: _controllers['parentName']?.text.trim() ?? _student!.parentName,
        parentPhone: _controllers['parentPhone']?.text.trim() ?? _student!.parentPhone,
        parentCompany: Value(getTextValue('parentCompany')),
        parentPosition: Value(getTextValue('parentPosition')),
        parentTitle2: Value(getTextValue('parentTitle2')),
        parentName2: Value(getTextValue('parentName2')),
        parentPhone2: Value(getTextValue('parentPhone2')),
        parentCompany2: Value(getTextValue('parentCompany2')),
        parentPosition2: Value(getTextValue('parentPosition2')),
        classPosition: Value(getTextValue('classPosition')),
        committeePosition: Value(getTextValue('committeePosition')),
      );

      final success = await provider.updateStudent(updatedStudent);

      if (success && mounted) {
        // 保存成功，退出编辑模式并刷新数据
        setState(() {
          _isEditing = false;
          _disposeControllers();
        });
        await _loadStudentData();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('保存成功')),
          );
        }
      } else if (mounted) {
        // 保存失败，保持编辑模式
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存失败，请重试')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存出错: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_student == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('学生详情'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('学生详情'),
        actions: [
          IconButton(
            icon: const Icon(Icons.psychology),
            onPressed: _openAiFunctions,
            tooltip: 'AI助手',
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _showMoreOptions,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            _buildSectionTitle('📋 基本信息', Colors.blue),
            const SizedBox(height: 12),
            _buildBasicInfo(),
            const SizedBox(height: 24),
            _buildSectionTitle('👪 家长信息', Colors.green),
            const SizedBox(height: 12),
            _buildParentInfo(),
            if (_student!.hasPosition || _isEditing) ...[
              const SizedBox(height: 24),
              _buildSectionTitle('🏫 学校职务', Colors.orange),
              const SizedBox(height: 12),
              _buildPositionInfo(),
            ],
            const SizedBox(height: 24),
            _buildSectionTitle('🎭 性格特质', Colors.purple),
            const SizedBox(height: 12),
            _buildPersonalityCard(),
            const SizedBox(height: 24),
            _buildSectionTitle('📝 随笔记录 ($_noteCount条)', Colors.red),
            const SizedBox(height: 12),
            _buildNotesPreview(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _toggleEdit,
        backgroundColor: _isEditing
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.primaryContainer,
        foregroundColor: _isEditing
            ? Theme.of(context).colorScheme.onPrimary
            : Theme.of(context).colorScheme.onPrimaryContainer,
        child: Icon(_isEditing ? Icons.save : Icons.edit),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildHeader() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                  child: Text(
                    _student!.name.substring(0, 1),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _student!.name,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text('学号: ${_student!.studentNumber}'),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Chip(
                            label: Text(_student!.genderText),
                            labelStyle: const TextStyle(fontSize: 12),
                          ),
                          if (_student!.age != null)
                            Chip(
                              label: Text('${_student!.age}岁'),
                              labelStyle: const TextStyle(fontSize: 12),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(Icons.phone, '拨打电话', () => _callParent()),
                _buildQuickAction(Icons.edit_note, '快速记录', () => _addNote()),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildBasicInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildEditableField(
              label: '姓名',
              value: _student!.name,
              fieldKey: 'name',
            ),
            _buildEditableField(
              label: '学号',
              value: _student!.studentNumber,
              fieldKey: 'studentNumber',
            ),
            // 性别选择
            if (!_isEditing)
              _buildInfoRow('性别', _student!.genderText)
            else
              _buildGenderSelector(),
            // 出生日期选择
            if (!_isEditing)
              _buildInfoRow('出生日期', _formatDate(_student!.birthDate))
            else
              _buildBirthDatePicker(),
            _buildEditableField(
              label: '身高',
              value: _student!.height != null ? '${_student!.height} cm' : null,
              fieldKey: 'height',
              keyboardType: TextInputType.number,
            ),
            _buildEditableField(
              label: '视力',
              value: _formatVision() != '-' ? _formatVision() : null,
              fieldKey: 'vision',
            ),
            if (_student!.address != null && _student!.address!.isNotEmpty || _isEditing)
              _buildEditableField(
                label: '家庭住址',
                value: _student!.address,
                fieldKey: 'address',
                maxLines: 2,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildParentInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '家长1',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700],
                  ),
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              label: '称谓',
              value: _student!.parentTitle,
              fieldKey: 'parentTitle',
            ),
            _buildEditableField(
              label: '姓名',
              value: _student!.parentName,
              fieldKey: 'parentName',
            ),
            _buildEditableField(
              label: '电话',
              value: _student!.parentPhone,
              fieldKey: 'parentPhone',
              keyboardType: TextInputType.phone,
            ),
            _buildEditableField(
              label: '工作单位',
              value: _student!.parentCompany,
              fieldKey: 'parentCompany',
            ),
            _buildEditableField(
              label: '职务',
              value: _student!.parentPosition,
              fieldKey: 'parentPosition',
            ),
            if (_student!.parentName2 != null && _student!.parentName2!.isNotEmpty || _isEditing) ...[
              const Divider(height: 32),
              Text(
                '家长2',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 12),
              _buildEditableField(
                label: '称谓',
                value: _student!.parentTitle2,
                fieldKey: 'parentTitle2',
              ),
              _buildEditableField(
                label: '姓名',
                value: _student!.parentName2,
                fieldKey: 'parentName2',
              ),
              _buildEditableField(
                label: '电话',
                value: _student!.parentPhone2,
                fieldKey: 'parentPhone2',
                keyboardType: TextInputType.phone,
              ),
              _buildEditableField(
                label: '工作单位',
                value: _student!.parentCompany2,
                fieldKey: 'parentCompany2',
              ),
              _buildEditableField(
                label: '职务',
                value: _student!.parentPosition2,
                fieldKey: 'parentPosition2',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPositionInfo() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (_student!.hasPosition || _isEditing)
              _buildEditableField(
                label: '班干部',
                value: _student!.classPosition,
                fieldKey: 'classPosition',
              ),
            if (_student!.isCommitteeMember || _isEditing)
              _buildEditableField(
                label: '家委会',
                value: _student!.committeePosition,
                fieldKey: 'committeePosition',
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalityCard() {
    return PersonalityDisplayCard(
      traits: _student?.personalityTraits,
      readonly: false,
      onUpdate: (updatedTraits) async {
        // 更新学生性格数据
        if (_student != null) {
          final updatedStudent = _student!.copyWith(
            personalityTraits: Value(updatedTraits),
          );

          // 调用Provider更新
          final provider = Provider.of<StudentProvider>(context, listen: false);
          final success = await provider.updateStudent(updatedStudent);

          if (success && mounted) {
            // 重新加载学生数据
            await _loadStudentData();
          }
        }
      },
      showChart: true,
    );
  }

  Widget _buildNotesPreview() {
    return InkWell(
      onTap: _addNote,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_noteCount == 0) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(Icons.note_add, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('暂无记录，点击添加'),
                      ],
                    ),
                  ),
                ),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      '添加记录 (已有 $_noteCount 条)',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomItem(Icons.edit_note, '记录笔记', () => _addNote()),
          _buildBottomItem(Icons.quiz, '查看成绩', () => _viewScores()),
        ],
      ),
    );
  }

  Widget _buildBottomItem(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
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
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  // 通用可编辑字段组件
  Widget _buildEditableField({
    required String label,
    required String? value,
    required String fieldKey,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    if (!_isEditing) {
      // 查看模式：显示为普通文本
      return _buildInfoRow(label, value ?? '-');
    }

    // 编辑模式：显示为 TextField
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          TextField(
            controller: _controllers[fieldKey],
            keyboardType: keyboardType,
            maxLines: maxLines,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  // 性别选择器
  Widget _buildGenderSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '性别',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          DropdownButtonFormField<Gender>(
            initialValue: _selectedGender,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              isDense: true,
            ),
            items: const [
              DropdownMenuItem(value: Gender.male, child: Text('男')),
              DropdownMenuItem(value: Gender.female, child: Text('女')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedGender = value;
              });
            },
          ),
        ],
      ),
    );
  }

  // 出生日期选择器
  Widget _buildBirthDatePicker() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '出生日期',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
          const SizedBox(height: 4),
          InkWell(
            onTap: () => _selectBirthDate(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    _selectedBirthDate != null
                        ? DateFormat('yyyy-MM-dd').format(_selectedBirthDate!)
                        : '选择日期',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 选择出生日期
  Future<void> _selectBirthDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedBirthDate = picked;
      });
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatVision() {
    if (_student!.vision != null) {
      return '${_student!.vision}';
    }
    return '-';
  }

  void _callParent() {
    // TODO: 实现拨打电话
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('拨打 ${_student!.parentName} 的电话')),
    );
  }

  Future<void> _addNote() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteCreateScreen(studentId: widget.studentId),
      ),
    );

    // 如果添加成功，刷新笔记数量
    if (result == true && mounted) {
      _loadStudentData();
    }
  }

  void _viewScores() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider(
          create: (_) => ScoreProvider(),
          child: StudentScoreScreen(
            studentId: widget.studentId,
            studentName: _student?.name ?? '',
          ),
        ),
      ),
    );
  }

  void _showMoreOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('导出信息'),
              onTap: () {
                Navigator.pop(context);
                // TODO: 导出学生信息
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete),
              title: const Text('删除学生'),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('确定要删除这位学生吗？此操作不可恢复。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStudent();
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteStudent() async {
    final studentProvider = context.read<StudentProvider>();
    final success = await studentProvider.deleteStudent(_student!.id!);

    if (success && mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('学生已删除')),
      );
    }
  }

  void _openAiFunctions() {
    Navigator.pushNamed(
      context,
      '/ai/functions',
      arguments: {
        'studentId': widget.studentId,
        'studentName': _student?.name ?? '',
      },
    );
  }
}
