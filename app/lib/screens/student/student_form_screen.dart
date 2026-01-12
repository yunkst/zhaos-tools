import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/providers/app_provider.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:teacher_tools/utils/constants.dart';
import 'package:intl/intl.dart';

/// 学生添加/编辑页面
class StudentFormScreen extends StatefulWidget {
  final int? studentId;

  const StudentFormScreen({super.key, this.studentId});

  @override
  State<StudentFormScreen> createState() => _StudentFormScreenState();
}

class _StudentFormScreenState extends State<StudentFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();

  // 基本信息
  final _nameController = TextEditingController();
  final _studentNumberController = TextEditingController();
  final _phoneController = TextEditingController();
  Gender? _selectedGender;
  DateTime? _birthDate;
  final _heightController = TextEditingController();
  final _visionController = TextEditingController();
  final _addressController = TextEditingController();

  // 家长信息1
  final _parentNameController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentProfessionController = TextEditingController();
  final _parentTitleController = TextEditingController();
  final _parentCompanyController = TextEditingController();
  final _parentPositionController = TextEditingController();

  // 家长信息2
  final _parentName2Controller = TextEditingController();
  final _parentPhone2Controller = TextEditingController();
  final _parentProfession2Controller = TextEditingController();
  final _parentTitle2Controller = TextEditingController();
  final _parentCompany2Controller = TextEditingController();
  final _parentPosition2Controller = TextEditingController();

  // 职务和备注
  final _classPositionController = TextEditingController();
  final _committeePositionController = TextEditingController();
  final _personalityController = TextEditingController();
  final _remarksController = TextEditingController();

  final int _currentStep = 0;
  bool _isSaving = false;
  bool _hasSecondParent = false;

  @override
  void initState() {
    super.initState();
    if (widget.studentId != null) {
      _loadStudent();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _studentNumberController.dispose();
    _phoneController.dispose();
    _heightController.dispose();
    _visionController.dispose();
    _addressController.dispose();
    _parentNameController.dispose();
    _parentPhoneController.dispose();
    _parentProfessionController.dispose();
    _parentTitleController.dispose();
    _parentCompanyController.dispose();
    _parentPositionController.dispose();
    _parentName2Controller.dispose();
    _parentPhone2Controller.dispose();
    _parentProfession2Controller.dispose();
    _parentTitle2Controller.dispose();
    _parentCompany2Controller.dispose();
    _parentPosition2Controller.dispose();
    _classPositionController.dispose();
    _committeePositionController.dispose();
    _personalityController.dispose();
    _remarksController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadStudent() async {
    // TODO: 加载学生数据用于编辑
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studentId == null ? '添加学生' : '编辑学生'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveStudent,
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildBasicInfoPage(),
            _buildBodyInfoPage(),
            _buildParent1InfoPage(),
            _buildParent2InfoPage(),
            _buildPositionInfoPage(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBasicInfoPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStepTitle('基本信息', '1/5'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _nameController,
          decoration: const InputDecoration(
            labelText: '姓名 *',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入姓名';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _studentNumberController,
          decoration: const InputDecoration(
            labelText: '学号 *',
            prefixIcon: Icon(Icons.badge),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入学号';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<Gender>(
          initialValue: _selectedGender,
          decoration: const InputDecoration(
            labelText: '性别 *',
            prefixIcon: Icon(Icons.wc),
            border: OutlineInputBorder(),
          ),
          items: const [
            DropdownMenuItem(value: Gender.male, child: Text('男')),
            DropdownMenuItem(value: Gender.female, child: Text('女')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedGender = value;
              });
            }
          },
          validator: (value) {
            if (value == null) {
              return '请选择性别';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        InkWell(
          onTap: _selectBirthDate,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(Icons.cake, color: Colors.blue),
                const SizedBox(width: 12),
                Text(
                  _birthDate == null ? '选择出生日期' : DateFormat('yyyy-MM-dd').format(_birthDate!),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: '学生电话',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildBodyInfoPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStepTitle('身体信息', '2/5'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _heightController,
          decoration: const InputDecoration(
            labelText: '身高 (cm)',
            prefixIcon: Icon(Icons.height),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _visionController,
          decoration: const InputDecoration(
            labelText: '视力',
            prefixIcon: Icon(Icons.remove_red_eye),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressController,
          decoration: const InputDecoration(
            labelText: '家庭住址',
            prefixIcon: Icon(Icons.home),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildParent1InfoPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStepTitle('家长信息', '3/5'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _parentNameController,
          decoration: const InputDecoration(
            labelText: '家长姓名 *',
            prefixIcon: Icon(Icons.person_outline),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入家长姓名';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _parentPhoneController,
          decoration: const InputDecoration(
            labelText: '家长电话 *',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return '请输入家长电话';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _parentTitleController,
          decoration: const InputDecoration(
            labelText: '称谓',
            prefixIcon: Icon(Icons.label),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _parentCompanyController,
          decoration: const InputDecoration(
            labelText: '工作单位',
            prefixIcon: Icon(Icons.business),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _parentPositionController,
          decoration: const InputDecoration(
            labelText: '职务',
            prefixIcon: Icon(Icons.work),
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }

  Widget _buildParent2InfoPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _buildStepTitle('家长信息2（可选）', '4/5'),
            const Spacer(),
            SwitchListTile(
              title: const Text('添加第二位家长'),
              value: _hasSecondParent,
              onChanged: (value) {
                setState(() {
                  _hasSecondParent = value;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (!_hasSecondParent)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                '如需添加第二位家长信息，请打开开关',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          Column(
            children: [
              TextFormField(
                controller: _parentName2Controller,
                decoration: const InputDecoration(
                  labelText: '家长姓名',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentPhone2Controller,
                decoration: const InputDecoration(
                  labelText: '家长电话',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentTitle2Controller,
                decoration: const InputDecoration(
                  labelText: '称谓',
                  prefixIcon: Icon(Icons.label),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentCompany2Controller,
                decoration: const InputDecoration(
                  labelText: '工作单位',
                  prefixIcon: Icon(Icons.business),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentPosition2Controller,
                decoration: const InputDecoration(
                  labelText: '职务',
                  prefixIcon: Icon(Icons.work),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildPositionInfoPage() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStepTitle('职务与备注', '5/5'),
        const SizedBox(height: 16),
        TextFormField(
          controller: _classPositionController,
          decoration: const InputDecoration(
            labelText: '班级职务',
            prefixIcon: Icon(Icons.star),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _committeePositionController,
          decoration: const InputDecoration(
            labelText: '家委会职务',
            prefixIcon: Icon(Icons.groups),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _personalityController,
          decoration: const InputDecoration(
            labelText: '性格特点',
            prefixIcon: Icon(Icons.psychology),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _remarksController,
          decoration: const InputDecoration(
            labelText: '备注',
            prefixIcon: Icon(Icons.note),
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildStepTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
        ),
        const SizedBox(height: 16),
        Divider(),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentStep,
      onTap: (index) {
        if (index < _currentStep) {
          _pageController.jumpToPage(index);
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: '基本信息',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.accessibility_new),
          label: '身体',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.family_restroom),
          label: '家长1',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: '家长2',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.work),
          label: '职务',
        ),
      ],
    );
  }

  Future<void> _selectBirthDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(2010),
      firstDate: DateTime(2005),
      lastDate: DateTime.now(),
    );

    if (date != null && mounted) {
      setState(() {
        _birthDate = date;
      });
    }
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appProvider = context.read<AppProvider>();
    final studentProvider = context.read<StudentProvider>();
    final classId = appProvider.currentClass!.id!;

    setState(() {
      _isSaving = true;
    });

    try {
      final student = Student(
        id: widget.studentId,
        classId: classId,
        name: _nameController.text.trim(),
        studentNumber: _studentNumberController.text.trim(),
        gender: _selectedGender!,
        birthDate: _birthDate,
        height: double.tryParse(_heightController.text.trim()),
        vision: _visionController.text.trim().isEmpty ? null : _visionController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        parentName: _parentNameController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        parentName2: _parentName2Controller.text.trim().isEmpty ? null : _parentName2Controller.text.trim(),
        parentPhone2: _parentPhone2Controller.text.trim().isEmpty ? null : _parentPhone2Controller.text.trim(),
        classPosition: _classPositionController.text.trim().isEmpty ? null : _classPositionController.text.trim(),
        committeePosition: _committeePositionController.text.trim().isEmpty ? null : _committeePositionController.text.trim(),
        personality: _personalityController.text.trim().isEmpty ? null : _personalityController.text.trim(),
        remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        address: _addressController.text.trim().isEmpty ? null : _addressController.text.trim(),
      );

      final success = widget.studentId == null
          ? await studentProvider.addStudent(student)
          : await studentProvider.updateStudent(student);

      if (!mounted) return;

      if (success) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.studentId == null ? '学生已添加' : '学生信息已更新'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('保存失败：$e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
