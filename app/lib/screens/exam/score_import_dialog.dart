import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/models/class_model.dart';
import 'package:teacher_tools/models/exam.dart';
import 'package:teacher_tools/providers/exam_provider.dart';
import 'package:teacher_tools/providers/app_provider.dart';
import 'package:teacher_tools/utils/constants.dart';

/// 成绩导入全屏对话框
class ScoreImportDialog extends StatefulWidget {
  final File excelFile;

  const ScoreImportDialog({
    super.key,
    required this.excelFile,
  });

  @override
  State<ScoreImportDialog> createState() => _ScoreImportDialogState();
}

class _ScoreImportDialogState extends State<ScoreImportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _examNameController = TextEditingController();

  ClassModel? _selectedClass;
  ImportMode _importMode = ImportMode.create;
  Exam? _selectedExam;
  ExamType _examType = ExamType.other;
  DateTime? _examDate;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // 设置默认当前班级
    _selectedClass = context.read<AppProvider>().currentClass;
  }

  @override
  void dispose() {
    _examNameController.dispose();
    super.dispose();
  }

  Future<void> _handleImport() async {
    if (_selectedClass == null) {
      setState(() => _errorMessage = '请先选择班级');
      return;
    }

    if (_importMode == ImportMode.create) {
      if (_examNameController.text.trim().isEmpty) {
        setState(() => _errorMessage = '请输入考试名称');
        return;
      }
    } else {
      if (_selectedExam == null) {
        setState(() => _errorMessage = '请选择要更新的考试');
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final examProvider = context.read<ExamProvider>();
      Map<String, dynamic> result;

      if (_importMode == ImportMode.create) {
        // 新增模式
        result = await examProvider.importScoresFromExcel(
          excelFile: widget.excelFile,
          classId: _selectedClass!.id!,
          examName: _examNameController.text.trim(),
          examType: _examType,
          examDate: _examDate,
        );
      } else {
        // 更新模式
        result = await examProvider.updateScoresFromExcel(
          excelFile: widget.excelFile,
          classId: _selectedClass!.id!,
          examId: _selectedExam!.id!,
        );
      }

      // 显示导入结果
      if (mounted) {
        _showImportResult(result);
      }
    } catch (e) {
      setState(() {
        _errorMessage = '导入失败: $e';
        _isLoading = false;
      });
    }
  }

  void _showImportResult(Map<String, dynamic> result) {
    final success = result['success'] as int;
    final failed = result['failed'] as int;
    final errors = result['errors'] as List<String>;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('导入完成'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '✅ 成功导入: $success 条',
                style: const TextStyle(color: Colors.green, fontSize: 16),
              ),
              if (failed > 0)
                Text(
                  '❌ 导入失败: $failed 条',
                  style: const TextStyle(color: Colors.red, fontSize: 16),
                ),
              if (errors.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text('失败详情:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...errors.take(10).map((error) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $error', style: const TextStyle(fontSize: 12)),
                    )),
                if (errors.length > 10)
                  Text('...还有 ${errors.length - 10} 条错误', style: const TextStyle(fontSize: 12)),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // 关闭结果对话框
              Navigator.of(context).pop(); // 关闭导入对话框
            },
            child: const Text('确定'),
          ),
        ],
      ),
    );

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('导入成绩'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 班级选择
              Text(
                '选择班级',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              _buildClassSelector(),
              const SizedBox(height: 24),

              // 导入模式选择
              Text(
                '导入模式',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              SegmentedButton<ImportMode>(
                segments: const [
                  ButtonSegment(
                    value: ImportMode.create,
                    label: Text('新增考试'),
                    icon: Icon(Icons.add),
                  ),
                  ButtonSegment(
                    value: ImportMode.update,
                    label: Text('更新已有考试'),
                    icon: Icon(Icons.edit),
                  ),
                ],
                selected: {_importMode},
                onSelectionChanged: (Set<ImportMode> selected) {
                  setState(() => _importMode = selected.first);
                },
              ),
              const SizedBox(height: 24),

              // 新增模式UI
              if (_importMode == ImportMode.create) ...[
                Text(
                  '考试名称',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _examNameController,
                  decoration: const InputDecoration(
                    hintText: '例如：2025年1月期末考试',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return '请输入考试名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 考试类型选择
                Text(
                  '考试类型',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<ExamType>(
                  initialValue: _examType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  items: ExamType.values.map((type) {
                    return DropdownMenuItem(
                      value: type,
                      child: Text(type.label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _examType = value);
                    }
                  },
                ),
                const SizedBox(height: 16),

                // 考试日期选择
                Text(
                  '考试日期（可选）',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => _examDate = date);
                    }
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _examDate == null
                          ? '点击选择日期'
                          : '${_examDate!.year}-${_examDate!.month.toString().padLeft(2, '0')}-${_examDate!.day.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],

              // 更新模式UI
              if (_importMode == ImportMode.update) ...[
                Text(
                  '选择要更新的考试',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildExamSelector(),
              ],

              const SizedBox(height: 32),

              // 错误提示
              if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              // 确认按钮
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleImport,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('开始导入', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassSelector() {
    return FutureBuilder<List<ClassModel>>(
      future: context.read<AppProvider>().loadAllClasses(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final classes = snapshot.data!;
        if (classes.isEmpty) {
          return const Text('暂无班级', style: TextStyle(color: Colors.grey));
        }

        return DropdownButtonFormField<ClassModel>(
          initialValue: _selectedClass,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: classes.map((classModel) {
            return DropdownMenuItem(
              value: classModel,
              child: Text(classModel.name),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedClass = value);
            }
          },
        );
      },
    );
  }

  Widget _buildExamSelector() {
    if (_selectedClass == null) {
      return const Text('请先选择班级', style: TextStyle(color: Colors.grey));
    }

    return FutureBuilder<List<Exam>>(
      future: context.read<ExamProvider>().loadRecentExams(_selectedClass!.id!),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final exams = snapshot.data!;
        if (exams.isEmpty) {
          return const Text('该班级暂无考试记录', style: TextStyle(color: Colors.grey));
        }

        return DropdownButtonFormField<Exam>(
          initialValue: _selectedExam,
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
          ),
          items: exams.map((exam) {
            return DropdownMenuItem(
              value: exam,
              child: Text('${exam.name} - ${exam.subjectText}'),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedExam = value);
            }
          },
        );
      },
    );
  }
}

/// 导入模式枚举
enum ImportMode {
  create,
  update;
}
