import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/providers/app_provider.dart';
import 'package:teacher_tools/screens/onboarding/create_class_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teacher_tools/utils/backup_manager.dart';
import 'package:teacher_tools/utils/backup_data.dart';

/// 欢迎页面
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo区域
              Icon(
                Icons.school,
                size: 100,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 32),

              // 标题
              Text(
                '教师工具',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),

              // 副标题
              Text(
                'Teacher Tools',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 48),

              // 功能介绍
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildFeatureItem(
                        context,
                        Icons.people_outline,
                        '学生管理',
                        '轻松管理学生信息和档案',
                      ),
                      const Divider(height: 24),
                      _buildFeatureItem(
                        context,
                        Icons.edit_note_outlined,
                        '快速记录',
                        '随时记录学生表现和成绩',
                      ),
                      const Divider(height: 24),
                      _buildFeatureItem(
                        context,
                        Icons.upload_file,
                        '批量导入',
                        '支持Excel批量导入数据',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // 开始按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => _handleGetStarted(context),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    '开始使用',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 导入数据按钮
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: () => _handleImportData(context),
                  icon: const Icon(Icons.upload_file, size: 20),
                  label: const Text(
                    '导入数据',
                    style: TextStyle(fontSize: 16),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.grey[700],
                    side: BorderSide(color: Colors.grey[400]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _handleGetStarted(BuildContext context) async {
    final appProvider = context.read<AppProvider>();

    // 完成引导
    await appProvider.completeOnboarding();

    // 跳转到创建班级页面
    if (context.mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const CreateClassScreen(),
        ),
      );
    }
  }

  /// 处理导入数据
  void _handleImportData(BuildContext context) async {
    try {
      // 1. 选择备份文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择备份文件',
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final filePath = result.files.single.path!;

      // 2. 验证备份文件
      final manager = BackupManager();
      final backupData = await manager.validateBackup(filePath);

      if (backupData == null) {
        if (context.mounted) {
          _showErrorSnackBar(context, '备份文件无效或已损坏');
        }
        return;
      }

      // 3. 显示预览对话框
      if (!context.mounted) return;
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _ImportPreviewDialog(backupData: backupData),
      );

      if (confirmed != true) return;

      // 4. 显示恢复进度对话框
      if (!context.mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _RestoreProgressDialog(
          filePath: filePath,
          onComplete: () async {
            // 完成引导
            if (context.mounted) {
              await context.read<AppProvider>().completeOnboarding();
            }
          },
        ),
      );
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, '导入失败: $e');
      }
    }
  }

  /// 显示错误提示
  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}

/// 导入预览对话框
class _ImportPreviewDialog extends StatelessWidget {
  final BackupData backupData;

  const _ImportPreviewDialog({required this.backupData});

  @override
  Widget build(BuildContext context) {
    final meta = backupData.meta;

    return AlertDialog(
      title: const Text('确认导入'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('是否导入以下备份数据?'),
            const SizedBox(height: 16),
            _buildInfoRow('备份时间', _formatDate(meta.backupDate)),
            _buildInfoRow('APP版本', '${meta.appVersion} (DB v${meta.databaseVersion})'),
            const SizedBox(height: 8),
            const Text('备份数据:', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildInfoRow('班级', '${meta.dataStats.classesCount} 个'),
            _buildInfoRow('学生', '${meta.dataStats.studentsCount} 人'),
            _buildInfoRow('笔记', '${meta.dataStats.notesCount} 条'),
            _buildInfoRow('考试', '${meta.dataStats.examsCount} 场'),
            _buildInfoRow('成绩', '${meta.dataStats.scoresCount} 条'),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确定导入'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}

/// 恢复进度对话框
class _RestoreProgressDialog extends StatefulWidget {
  final String filePath;
  final VoidCallback onComplete;

  const _RestoreProgressDialog({
    required this.filePath,
    required this.onComplete,
  });

  @override
  State<_RestoreProgressDialog> createState() => _RestoreProgressDialogState();
}

class _RestoreProgressDialogState extends State<_RestoreProgressDialog> {
  int _current = 0;
  String _message = '正在准备...';

  @override
  void initState() {
    super.initState();
    _startRestore();
  }

  Future<void> _startRestore() async {
    try {
      final manager = BackupManager();
      await manager.restoreBackup(
        widget.filePath,
        onProgress: (current, total, message) {
          if (mounted) {
            setState(() {
              _current = current;
              _message = message;
            });
          }
        },
      );

      if (mounted) {
        // 恢复成功
        widget.onComplete();

        // 刷新AppProvider状态,重新加载班级列表
        if (!mounted) return;
        await context.read<AppProvider>().refreshClasses();

        // 如果有班级,自动设置第一个为当前班级
        if (!mounted) return;
        final appProvider = context.read<AppProvider>();
        if (appProvider.classes.isNotEmpty) {
          await appProvider.setCurrentClass(appProvider.classes.first);
        }

        if (!mounted) return;
        Navigator.pop(context); // 关闭进度对话框

        // 显示成功提示
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据导入成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // 关闭进度对话框
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导入失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('正在导入数据'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          LinearProgressIndicator(value: _current / 100),
          const SizedBox(height: 16),
          Text('$_current% - $_message'),
        ],
      ),
    );
  }
}
