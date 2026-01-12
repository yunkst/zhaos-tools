import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:teacher_tools/providers/dify_config_provider.dart';
import 'package:teacher_tools/database/note_dao.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/models/note.dart';
import 'package:teacher_tools/services/student_data_exporter.dart';
import 'package:teacher_tools/services/dify_service.dart';
import 'dart:async';

/// 评语生成页面
/// 流式显示AI生成的评语内容
class CommentGenerationScreen extends StatefulWidget {
  final int studentId;

  const CommentGenerationScreen({
    super.key,
    required this.studentId,
  });

  @override
  State<CommentGenerationScreen> createState() => _CommentGenerationScreenState();
}

class _CommentGenerationScreenState extends State<CommentGenerationScreen> {
  bool _isLoading = true;
  bool _isGenerating = false;
  Student? _student;
  List<Note> _notes = [];
  String _generatedComment = '';
  StreamSubscription<String>? _streamSubscription;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStudentData();
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    super.dispose();
  }

  /// 加载学生数据
  Future<void> _loadStudentData() async {
    try {
      final studentProvider = context.read<StudentProvider>();
      final noteDAO = NoteDAO();

      final student = await studentProvider.getStudentDetail(widget.studentId);
      final notes = await noteDAO.getByStudentId(widget.studentId);

      if (mounted) {
        setState(() {
          _student = student;
          _notes = notes;
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

  /// 开始生成评语
  Future<void> _startGeneration() async {
    // 检查配置
    final configProvider = context.read<DifyConfigProvider>();
    if (!configProvider.isConfigured) {
      _showErrorSnackBar('请先在设置中配置Dify');
      return;
    }

    // 导出学生数据为AI可读的文本格式
    final studentInfoText = StudentDataExporter.exportToText(_student!, _notes);

    debugPrint('📦 [CommentGeneration] 学生数据:\n$studentInfoText');

    // 开始生成
    setState(() {
      _isGenerating = true;
      _generatedComment = '';
      _errorMessage = null;
    });

    try {
      final config = configProvider.config!;
      final service = DifyService(config: config);

      _streamSubscription = service
          .runWorkflow(studentInfoText, '单独生成期末评语')
          .listen(
            (chunk) {
              debugPrint('📨 [CommentGeneration] 收到数据块: "$chunk"');
              debugPrint('📨 [CommentGeneration] 数据块长度: ${chunk.length}');
              if (mounted) {
                setState(() {
                  _generatedComment += chunk;
                  debugPrint('✅ [CommentGeneration] 已追加文本，当前总长度: ${_generatedComment.length}');
                });
              } else {
                debugPrint('⚠️ [CommentGeneration] widget已销毁，无法更新UI');
              }
            },
            onError: (error) {
              debugPrint('❌ [CommentGeneration] 错误: $error');
              if (mounted) {
                setState(() {
                  _isGenerating = false;
                  _errorMessage = error.toString();
                });
                _showErrorSnackBar('生成失败: $error');
              }
            },
            onDone: () {
              debugPrint('✅ [CommentGeneration] 生成完成');
              if (mounted) {
                setState(() {
                  _isGenerating = false;
                });
                _showSuccessSnackBar('评语生成完成');
              }
              service.close();
            },
          );
    } catch (e) {
      if (mounted) {
        setState(() {
          _isGenerating = false;
          _errorMessage = e.toString();
        });
        _showErrorSnackBar('启动生成失败: $e');
      }
    }
  }

  /// 复制到剪贴板
  Future<void> _copyToClipboard() async {
    await Clipboard.setData(ClipboardData(text: _generatedComment));
    if (mounted) {
      _showSuccessSnackBar('已复制到剪贴板');
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
          title: const Text('生成期末评语'),
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

    if (_errorMessage != null && _student == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('生成期末评语'),
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
        title: const Text('生成期末评语'),
        actions: [
          if (!_isGenerating && _generatedComment.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.copy),
              onPressed: _copyToClipboard,
              tooltip: '复制',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 学生信息预览
            _buildStudentInfoCard(),
            const SizedBox(height: 24),

            // 生成按钮
            if (!_isGenerating && _generatedComment.isEmpty)
              Center(
                child: ElevatedButton.icon(
                  onPressed: _startGeneration,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('开始生成'),
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
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('正在生成中...'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // 生成的评语
            if (_generatedComment.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                '生成结果',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    _generatedComment,
                    style: const TextStyle(
                      height: 1.5,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],

            // 错误信息
            if (_errorMessage != null && _isGenerating == false)
              Card(
                color: Colors.red[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Icon(Icons.error, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentInfoCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '学生信息预览',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildInfoRow('姓名', _student?.name ?? ''),
            _buildInfoRow('学号', _student?.studentNumber ?? ''),
            _buildInfoRow('随笔记录', '${_notes.length}条'),
          ],
        ),
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
