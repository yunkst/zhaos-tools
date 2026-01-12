import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/models/class_model.dart';
import 'package:teacher_tools/providers/app_provider.dart';
import 'package:teacher_tools/screens/home/home_screen.dart';

/// 创建班级页面
class CreateClassScreen extends StatefulWidget {
  const CreateClassScreen({super.key});

  @override
  State<CreateClassScreen> createState() => _CreateClassScreenState();
}

class _CreateClassScreenState extends State<CreateClassScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('创建班级'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 班级名称
                Text(
                  '班级信息',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: '班级名称',
                    hintText: '例如：三年级2班',
                    prefixIcon: Icon(Icons.class_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return '请输入班级名称';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 48),

                // 创建按钮
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _handleCreateClass,
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      '创建班级',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleCreateClass() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final appProvider = context.read<AppProvider>();

    // 创建班级对象
    final classModel = ClassModel(
      name: _nameController.text.trim(),
    );

    // 显示加载对话框
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // 添加班级
    final success = await appProvider.addClass(classModel);

    // 隐藏加载对话框
    if (mounted) {
      Navigator.of(context).pop();
    }

    if (success) {
      // 显示成功提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('班级创建成功')),
        );

        // 跳转到主页
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } else {
      // 显示失败提示
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('班级创建失败，请重试')),
        );
      }
    }
  }
}
