import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/providers/dify_config_provider.dart';
import 'package:teacher_tools/models/dify_config.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:teacher_tools/utils/backup_manager.dart';
import 'package:teacher_tools/utils/backup_data.dart';

/// 设置页
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  PackageInfo _packageInfo = PackageInfo(
    appName: 'Unknown',
    packageName: 'Unknown',
    version: 'Unknown',
    buildNumber: 'Unknown',
  );

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _packageInfo = info;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
      ),
      body: ListView(
        children: [
          _buildAppInfoCard(),
          const SizedBox(height: 8),
          _buildAIConfigSection(),
          const SizedBox(height: 8),
          _buildDataManagementSection(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAppInfoCard() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.school,
                size: 48,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _packageInfo.appName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '版本 ${_packageInfo.version} (${_packageInfo.buildNumber})',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '教师助手',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIConfigSection() {
    return Consumer<DifyConfigProvider>(
      builder: (context, configProvider, child) {
        final isConfigured = configProvider.isConfigured;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      'AI配置',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Spacer(),
                    if (isConfigured)
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                  ],
                ),
              ),
              ListTile(
                leading: const Icon(Icons.settings, color: Colors.purple),
                title: const Text('Dify配置'),
                subtitle: Text(isConfigured ? '已配置' : '未配置'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showDifyConfigDialog(context, configProvider),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDifyConfigDialog(BuildContext context, DifyConfigProvider configProvider) {
    final hostController = TextEditingController(text: configProvider.config?.host ?? '');
    final tokenController = TextEditingController(text: configProvider.config?.token ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('配置Dify'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: hostController,
                decoration: const InputDecoration(
                  labelText: 'Host',
                  hintText: 'https://api.dify.ai',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tokenController,
                decoration: const InputDecoration(
                  labelText: 'Token',
                  hintText: '你的API Token',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () async {
              final host = hostController.text.trim();
              final token = tokenController.text.trim();

              if (host.isEmpty || token.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('请填写完整的配置信息'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }

              final config = DifyConfig(host: host, token: token);
              final success = await configProvider.saveConfig(config);

              if (success && context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('配置保存成功'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('配置保存失败'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Widget _buildDataManagementSection() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '数据管理',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.backup, color: Colors.blue),
            title: const Text('备份数据'),
            subtitle: const Text('将所有数据备份到文件'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _backupData,
          ),
          const Divider(height: 1),
          ListTile(
            leading: const Icon(Icons.restore, color: Colors.green),
            title: const Text('恢复数据'),
            subtitle: const Text('从备份文件恢复数据'),
            trailing: const Icon(Icons.chevron_right),
            onTap: _restoreData,
          ),
        ],
      ),
    );
  }

  /// 备份数据
  void _backupData() async {
    try {
      // 显示备份进度对话框
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _BackupProgressDialog(
          onBackup: (onProgress) async {
            final manager = BackupManager();
            final filePath = await manager.createBackup(
              onProgress: (current, total, message) {
                onProgress(current, total, message);
              },
            );
            return filePath;
          },
        ),
      );
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('备份失败: $e');
      }
    }
  }

  /// 恢复数据
  void _restoreData() async {
    try {
      // 1. 选择文件
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: '选择备份文件',
      );

      if (result == null || result.files.single.path == null) {
        return;
      }

      final filePath = result.files.single.path!;

      // 2. 验证并显示预览
      final manager = BackupManager();
      final backupData = await manager.validateBackup(filePath);

      if (backupData == null) {
        if (mounted) {
          _showErrorSnackBar('备份文件无效或已损坏');
        }
        return;
      }

      // 3. 显示恢复预览对话框
      if (mounted) {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => _RestorePreviewDialog(
            backupData: backupData,
          ),
        );

        if (confirmed != true) return;

        // 4. 显示恢复进度对话框
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _RestoreProgressDialog(
            filePath: filePath,
            onRestore: (onProgress) async {
              return await manager.restoreBackup(
                filePath,
                onProgress: (current, total, message) {
                  onProgress(current, total, message);
                },
              );
            },
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('恢复失败: $e');
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
}

/// 备份进度对话框
class _BackupProgressDialog extends StatefulWidget {
  final Function(Function(int, int, String)) onBackup;

  const _BackupProgressDialog({required this.onBackup});

  @override
  State<_BackupProgressDialog> createState() => _BackupProgressDialogState();
}

class _BackupProgressDialogState extends State<_BackupProgressDialog> {
  int _current = 0;
  String _message = '正在准备...';

  @override
  void initState() {
    super.initState();
    _startBackup();
  }

  Future<void> _startBackup() async {
    try {
      final filePath = await widget.onBackup((current, total, message) {
        if (mounted) {
          setState(() {
            _current = current;
            _message = message;
          });
        }
      });

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (context) => _BackupSuccessDialog(filePath: filePath),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('备份失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('正在备份数据'),
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

/// 备份成功对话框
class _BackupSuccessDialog extends StatelessWidget {
  final String filePath;

  const _BackupSuccessDialog({required this.filePath});

  @override
  Widget build(BuildContext context) {
    final fileName = filePath.split('/').last;

    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green[700]),
          const SizedBox(width: 8),
          const Text('备份成功'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('备份文件已保存到:'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              fileName,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '路径: $filePath',
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 恢复预览对话框
class _RestorePreviewDialog extends StatelessWidget {
  final BackupData backupData;

  const _RestorePreviewDialog({required this.backupData});

  @override
  Widget build(BuildContext context) {
    final meta = backupData.meta;

    return AlertDialog(
      title: const Text('确认恢复'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('此操作将清空当前所有数据并恢复备份,是否继续?'),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('取消'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('确定恢复', style: TextStyle(color: Colors.red)),
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
  final Function(Function(int, int, String)) onRestore;

  const _RestoreProgressDialog({
    required this.filePath,
    required this.onRestore,
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
      await widget.onRestore((current, total, message) {
        if (mounted) {
          setState(() {
            _current = current;
            _message = message;
          });
        }
      });

      if (mounted) {
        Navigator.pop(context);
        // 返回首页
        Navigator.of(context).popUntil((route) => route.isFirst);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('数据恢复成功'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('恢复失败: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('正在恢复数据'),
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
