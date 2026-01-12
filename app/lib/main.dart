import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:teacher_tools/providers/app_provider.dart';
import 'package:teacher_tools/providers/student_provider.dart';
import 'package:teacher_tools/providers/note_provider.dart';
import 'package:teacher_tools/providers/exam_provider.dart';
import 'package:teacher_tools/providers/dify_config_provider.dart';
import 'package:teacher_tools/screens/home/home_screen.dart';
import 'package:teacher_tools/screens/onboarding/welcome_screen.dart';
import 'package:teacher_tools/screens/note/note_list_screen.dart';
import 'package:teacher_tools/screens/note/note_detail_screen.dart';
import 'package:teacher_tools/screens/note/note_create_screen.dart' as note_create;
import 'package:teacher_tools/screens/ai/ai_function_list_screen.dart';
import 'package:teacher_tools/screens/ai/comment_generation_screen.dart';
import 'package:teacher_tools/screens/exam/score_import_dialog.dart';

void main() async {
  // 确保Flutter绑定初始化
  WidgetsFlutterBinding.ensureInitialized();

  // 添加启动日志
  debugPrint('🚀 [TeacherTools] 应用开始启动...');

  runApp(const TeacherToolsApp());

  debugPrint('✅ [TeacherTools] runApp 调用完成');
}

class TeacherToolsApp extends StatefulWidget {
  const TeacherToolsApp({super.key});

  @override
  State<TeacherToolsApp> createState() => _TeacherToolsAppState();
}

class _TeacherToolsAppState extends State<TeacherToolsApp> {
  late AppProvider _appProvider;

  @override
  void initState() {
    super.initState();
    debugPrint('📱 [TeacherTools] _TeacherToolsAppState initState 开始');

    _appProvider = AppProvider();
    debugPrint('📱 [TeacherTools] AppProvider 实例已创建');

    // 延迟调用 init,避免在 build 期间触发 notifyListeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('📱 [TeacherTools] 开始调用 AppProvider.init()');
      _appProvider.init();
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 [TeacherTools] _TeacherToolsAppState build 调用');
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _appProvider),
        ChangeNotifierProvider(create: (_) => StudentProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => ExamProvider()),
        ChangeNotifierProvider(create: (_) => DifyConfigProvider()),
      ],
      child: MaterialApp(
        title: '教师工具',
        debugShowCheckedModeBanner: false,
        theme: _buildLightTheme(),
        darkTheme: _buildDarkTheme(),
        themeMode: ThemeMode.system,
        home: const AppRoot(),
        routes: {
          '/notes': (context) => const NoteListScreen(),
          '/notes/create': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return note_create.NoteCreateScreen(
              studentId: args?['studentId'],
            );
          },
          '/ai/functions': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return AiFunctionListScreen(
              studentId: args?['studentId'] ?? 0,
              studentName: args?['studentName'] ?? '',
            );
          },
          '/ai/comment-generation': (context) {
            final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
            return CommentGenerationScreen(
              studentId: args?['studentId'] ?? 0,
            );
          },
        },
        onGenerateRoute: (settings) {
          // 处理带参数的路由
          if (settings.name == '/notes/detail') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => NoteDetailScreen(
                noteId: args?['noteId'] ?? '',
              ),
            );
          }

          if (settings.name == '/notes/edit') {
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(
              builder: (context) => note_create.NoteCreateScreen(
                noteId: args?['noteId'],
              ),
            );
          }

          return null;
        },
      ),
    );
  }

  /// 浅色主题
  ThemeData _buildLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3), // 蓝色主色调
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// 深色主题
  ThemeData _buildDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF2196F3),
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

/// 应用根组件（决定显示欢迎页还是主页）
class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  bool _difyConfigInitialized = false;

  @override
  void initState() {
    super.initState();
    // 延迟初始化 Dify 配置，确保 Provider 已完全注入
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_difyConfigInitialized) {
        final difyConfigProvider = context.read<DifyConfigProvider>();
        difyConfigProvider.loadConfig();
        if (mounted) {
          setState(() {
            _difyConfigInitialized = true;
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🏠 [TeacherTools] AppRoot build 调用');

    return Consumer<AppProvider>(
      builder: (context, appProvider, child) {
        debugPrint('🏠 [TeacherTools] Consumer builder: isLoading=${appProvider.isLoading}, onboardingComplete=${appProvider.onboardingComplete}');

        // 如果还在加载中,显示加载页面
        if (appProvider.isLoading) {
          debugPrint('⏳ [TeacherTools] 显示加载页面');
          return const _LoadingScreen();
        }

        // 如果未完成引导,显示欢迎页
        if (!appProvider.onboardingComplete) {
          debugPrint('👋 [TeacherTools] 显示欢迎页(未完成引导)');
          return const WelcomeScreen();
        }

        // 如果已完成引导但没有班级,显示创建班级引导
        if (appProvider.currentClass == null) {
          // TODO: 显示创建班级引导页
          debugPrint('👋 [TeacherTools] 显示欢迎页(无当前班级)');
          return const WelcomeScreen();
        }

        // 检查是否有待处理的文件（从外部APP转发的Excel）
        if (appProvider.pendingReceivedFile != null) {
          // 延迟弹出对话框，确保UI已经完全构建
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && appProvider.pendingReceivedFile != null) {
              final file = appProvider.pendingReceivedFile!;
              // 清除待处理文件，避免重复弹出
              appProvider.clearPendingFile();
              // 显示导入对话框
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ScoreImportDialog(excelFile: file),
                  fullscreenDialog: true,
                ),
              );
            }
          });
        }

        // 显示主页
        debugPrint('🏠 [TeacherTools] 显示主页');
        return const HomeScreen();
      },
    );
  }
}

/// 加载页面
class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              '正在加载...',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}
