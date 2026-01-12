import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:teacher_tools/providers/dify_config_provider.dart';
import 'package:teacher_tools/database/note_dao.dart';
import 'package:teacher_tools/models/note.dart';
import 'package:teacher_tools/services/student_data_exporter.dart';
import 'package:teacher_tools/services/dify_service.dart';
import 'package:teacher_tools/services/batch_comment_exporter.dart';

/// 批量评语生成页面
/// 支持批量生成期末评语，显示进度，完成后导出Excel
class BatchCommentGenerationScreen extends StatefulWidget {
  final List<int> studentIds;
  final List<String> studentNames;

  const BatchCommentGenerationScreen({
    super.key,
    required this.studentIds,
    required this.studentNames,
  });

  @override
  State<BatchCommentGenerationScreen> createState() => _BatchCommentGenerationScreenState();
}

class _BatchCommentGenerationScreenState extends State<BatchCommentGenerationScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  bool _isExporting = false;

  // 学生数据
  List<Student> _students = [];
  Map<int, List<Note>> _studentNotes = {};

  // 生成进度
  double _progress = 0.0;
  int _completedCount = 0;
  final Map<int, String> _generatedComments = {}; // 学生ID -> 评语
  final Map<int, String> _failedStudents = {}; // 学生ID -> 错误信息

  String? _currentGeneratingStudent;
  String? _errorMessage;
  bool _isCancelled = false; // 取消标志

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  /// 加载学生数据（并发加载，性能优化）
  Future<void> _loadStudentData() async {
    try {
      final studentProvider = context.read<StudentProvider>();
      final noteDAO = NoteDAO();

      // 并发批量获取学生详情和随笔记录
      final futures = widget.studentIds.map((studentId) async {
        final student = await studentProvider.getStudentDetail(studentId);
        if (student != null) {
          final notes = await noteDAO.getByStudentId(studentId);
          return (student, notes);
        }
        return null;
      }).toList();

      // 等待所有并发请求完成
      final results = await Future.wait(futures);

      // 过滤掉空结果并组装数据
      final students = <Student>[];
      final studentNotes = <int, List<Note>>{};

      for (final result in results) {
        if (result != null) {
          final student = result.$1;
          final notes = result.$2;
          students.add(student);
          studentNotes[student.id!] = notes;
        }
      }

      if (mounted) {
        setState(() {
          _students = students;
          _studentNotes = studentNotes;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = '加载数据失败: $e';
        });
      }
    }
  }

  /// 开始批量生成评语
  Future<void> _startBatchGeneration() async {
    // 检查配置
    final configProvider = context.read<DifyConfigProvider>();
    if (!configProvider.isConfigured) {
      _showErrorSnackBar('请先在设置中配置Dify');
      return;
    }

    setState(() {
      _isGenerating = true;
      _completedCount = 0;
      _progress = 0.0;
      _generatedComments.clear();
      _failedStudents.clear();
      _errorMessage = null;
      _isCancelled = false;
    });

    final config = configProvider.config!;

    // 串行生成每个学生的评语
    for (final student in _students) {
      // 检查是否取消
      if (_isCancelled || !mounted) {
        debugPrint('⚠️ [BatchCommentGeneration] 用户取消生成');
        break;
      }

      setState(() {
        _currentGeneratingStudent = student.name;
      });

      try {
        // 导出学生数据为AI可读的文本格式
        final notes = _studentNotes[student.id!] ?? [];
        final studentInfoText = StudentDataExporter.exportToText(student, notes);

        debugPrint('📦 [BatchCommentGeneration] 学生: ${student.name}');
        debugPrint('📦 [BatchCommentGeneration] 数据预览:\n${studentInfoText.substring(0, studentInfoText.length > 200 ? 200 : studentInfoText.length)}...');

        // 调用Dify API
        final service = DifyService(config: config);
        final comment = await _generateSingleComment(service, studentInfoText);

        // 再次检查是否取消（在API调用期间可能已取消）
        if (_isCancelled) {
          service.close();
          break;
        }

        if (comment.isNotEmpty) {
          _generatedComments[student.id!] = comment;
        } else {
          _failedStudents[student.id!] = '生成结果为空';
        }

        service.close();
      } catch (e) {
        _failedStudents[student.id!] = e.toString();
        debugPrint('❌ 生成失败 (${student.name}): $e');
      }

      // 更新进度
      if (mounted) {
        setState(() {
          _completedCount++;
          _progress = _completedCount / _students.length;
        });
      }
    }

    // 生成完成
    if (mounted) {
      setState(() {
        _isGenerating = false;
        _currentGeneratingStudent = null;
      });

      // 显示完成提示
      final successCount = _generatedComments.length;
      final failedCount = _failedStudents.length;

      if (_isCancelled) {
        // 用户取消
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已取消生成：成功 $successCount 条${failedCount > 0 ? '，失败 $failedCount 条' : ''}'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (failedCount == 0) {
        _showSuccessSnackBar('成功生成 $successCount 条评语');
      } else if (successCount == 0) {
        _showErrorSnackBar('全部生成失败');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('生成完成：成功 $successCount 条，失败 $failedCount 条'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  /// 取消生成
  void _cancelGeneration() {
    setState(() {
      _isCancelled = true;
    });
    debugPrint('🛑 [BatchCommentGeneration] 用户请求取消');
  }

  /// 生成单个学生的评语
  Future<String> _generateSingleComment(DifyService service, String studentInfoText) async {
    final buffer = StringBuffer();

    await for (final chunk in service.runWorkflow(studentInfoText, '单独生成期末评语')) {
      buffer.write(chunk);
    }

    return buffer.toString();
  }

  /// 导出到Excel并分享
  Future<void> _exportToExcel() async {
    if (_generatedComments.isEmpty) {
      _showErrorSnackBar('没有可导出的评语');
      return;
    }

    setState(() {
      _isExporting = true;
    });

    try {
      // 构建评语数据（包含学号、姓名、评语）
      final commentData = <int, String>{};
      for (final student in _students) {
        if (_generatedComments.containsKey(student.id!)) {
          commentData[student.id!] = _generatedComments[student.id!]!;
        }
      }

      // 生成Excel文件
      final filePath = await BatchCommentExporter.exportToExcel(
        _students,
        commentData,
        _failedStudents,
      );

      if (mounted) {
        setState(() {
          _isExporting = false;
        });

        // 自动弹出分享菜单
        await Share.shareXFiles(
          [XFile(filePath)],
          subject: '期末评语',
          text: '学生期末评语（${_students.length}人）',
        );

        // 分享后提示
        _showSuccessSnackBar('导出并分享成功！');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        _showErrorSnackBar('导出失败: $e');
      }
    }
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('批量生成期末评语'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('正在加载数据...'),
            ],
          ),
        ),
      );
    }

    if (_errorMessage != null && _students.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('批量生成期末评语'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  _errorMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('批量生成期末评语'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学生信息预览
            _buildStudentsInfoCard(),
            const SizedBox(height: 24),

            // 开始生成按钮
            if (!_isGenerating && _generatedComments.isEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _startBatchGeneration,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始批量生成'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ),

            // 生成中状态
            if (_isGenerating) ...[
              _buildProgressCard(),
              const SizedBox(height: 16),
            ],

            // 生成完成后的统计
            if (!_isGenerating && _generatedComments.isNotEmpty) ...[
              _buildCompletionStatsCard(),
              const SizedBox(height: 16),

              // 导出按钮
              Center(
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _exportToExcel,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.file_download),
                  label: Text(_isExporting ? '正在导出...' : '导出并分享'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 生成的评语列表
            if (_generatedComments.isNotEmpty) ...[
              Text(
                '已生成评语 (${_generatedComments.length}/${_students.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _buildGeneratedCommentsList(),
            ],

            // 失败列表
            if (_failedStudents.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '生成失败 (${_failedStudents.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
              ),
              const SizedBox(height: 12),
              _buildFailedStudentsList(),
            ],
          ],
        ),
      ),
    );
  }

  /// 构建学生信息预览卡片
  Widget _buildStudentsInfoCard() {
    final totalNotes = _studentNotes.values.fold<int>(0, (sum, notes) => sum + notes.length);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据概览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('学生总数', '${_students.length}人'),
            _buildInfoRow('随笔记录', '$totalNotes条'),
          ],
        ),
      ),
    );
  }

  /// 构建进度卡片
  Widget _buildProgressCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '正在生成中...',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '$_completedCount/${_students.length}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: _progress,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 12),
            if (_currentGeneratingStudent != null)
              Text(
                '当前: $_currentGeneratingStudent',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            const SizedBox(height: 16),
            // 取消按钮
            Center(
              child: OutlinedButton.icon(
                onPressed: _cancelGeneration,
                icon: const Icon(Icons.cancel),
                label: const Text('取消生成'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建完成统计卡片
  Widget _buildCompletionStatsCard() {
    final successCount = _generatedComments.length;
    final failedCount = _failedStudents.length;

    return Card(
      color: failedCount == 0 ? Colors.green[50] : Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem('成功', successCount, Colors.green),
            if (failedCount > 0) _buildStatItem('失败', failedCount, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  /// 构建已生成评语列表
  Widget _buildGeneratedCommentsList() {
    return _buildStudentListCard(
      itemCount: _generatedComments.length,
      itemBuilder: (context, index) {
        final studentId = _generatedComments.keys.elementAt(index);
        final student = _students.firstWhere((s) => s.id == studentId);
        final comment = _generatedComments[studentId]!;

        return ExpansionTile(
          title: Text(student.name),
          subtitle: Text(
            comment.length > 50 ? '${comment.substring(0, 50)}...' : comment,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: SelectableText(
                comment,
                style: const TextStyle(height: 1.5),
              ),
            ),
          ],
        );
      },
    );
  }

  /// 构建失败学生列表
  Widget _buildFailedStudentsList() {
    return _buildStudentListCard(
      itemCount: _failedStudents.length,
      cardColor: Colors.red[50],
      itemBuilder: (context, index) {
        final studentId = _failedStudents.keys.elementAt(index);
        final student = _students.firstWhere((s) => s.id == studentId);
        final error = _failedStudents[studentId]!;

        return ListTile(
          leading: const Icon(Icons.error, color: Colors.red),
          title: Text(student.name),
          subtitle: Text(
            error,
            style: const TextStyle(color: Colors.red),
          ),
        );
      },
    );
  }

  /// 通用学生列表卡片构建器（代码复用优化）
  Widget _buildStudentListCard({
    required int itemCount,
    Color? cardColor,
    required Widget Function(BuildContext, int) itemBuilder,
  }) {
    return Card(
      color: cardColor,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: itemBuilder,
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
