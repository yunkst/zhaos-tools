import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:teacher_tools/utils/constants.dart';
import 'package:teacher_tools/models/class_model.dart';
import 'package:teacher_tools/database/class_dao.dart';
import 'package:teacher_tools/providers/data_migration_provider.dart';

/// 应用状态管理Provider
class AppProvider with ChangeNotifier {
  final ClassDAO _classDAO = ClassDAO();

  static const _fileReceiverChannel = MethodChannel('com.teacher_tools/file_receiver');

  // 是否完成引导
  bool _onboardingComplete = false;
  bool get onboardingComplete => _onboardingComplete;

  // 待处理的文件（从外部APP转发）
  File? _pendingReceivedFile;
  File? get pendingReceivedFile => _pendingReceivedFile;

  // 当前班级
  ClassModel? _currentClass;
  ClassModel? get currentClass => _currentClass;

  // 班级列表
  List<ClassModel> _classes = [];
  List<ClassModel> get classes => _classes;

  // 加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 初始化
  Future<void> init() async {
    try {
      _isLoading = true;
      notifyListeners();

      debugPrint('🚀 开始初始化应用...');

      await _loadOnboardingStatus();
      debugPrint('✅ 引导状态加载完成');

      await _loadCurrentClass();
      debugPrint('✅ 当前班级加载完成');

      await _loadClasses();
      debugPrint('✅ 班级列表加载完成');

      // 执行数据迁移（在后台异步执行）
      _performDataMigration();

      // 设置文件接收监听
      _setupFileReceiver();

      _isLoading = false;
      notifyListeners();

      debugPrint('🎉 应用初始化完成');
    } catch (e, stackTrace) {
      debugPrint('❌ 应用初始化失败: $e');
      debugPrint('堆栈信息: $stackTrace');

      // 即使初始化失败，也要取消加载状态，避免应用卡死
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 设置文件接收监听
  void _setupFileReceiver() {
    _fileReceiverChannel.setMethodCallHandler((call) async {
      if (call.method == 'onFileReceived') {
        final filePath = call.arguments as String;
        debugPrint('📂 接收到文件: $filePath');

        // 验证文件是否为Excel文件
        if (filePath.endsWith('.xlsx') || filePath.endsWith('.xls')) {
          _pendingReceivedFile = File(filePath);
          notifyListeners();
          debugPrint('✅ Excel文件已准备好导入');
        } else {
          debugPrint('⚠️ 接收的文件不是Excel格式: $filePath');
        }
      }
    });
    debugPrint('📡 文件接收监听器已设置');
  }

  /// 清除待处理的文件
  void clearPendingFile() {
    _pendingReceivedFile = null;
    notifyListeners();
  }

  /// 执行数据迁移（不阻塞初始化）
  void _performDataMigration() {
    Future.microtask(() async {
      try {
        final migrationProvider = DataMigrationProvider();
        await migrationProvider.checkAndMigratePinyin();
      } catch (e) {
        debugPrint('⚠️  数据迁移失败: $e');
      }
    });
  }

  /// 加载引导状态
  Future<void> _loadOnboardingStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _onboardingComplete = prefs.getBool(AppConstants.keyOnboardingComplete) ?? false;
  }

  /// 完成引导
  Future<void> completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyOnboardingComplete, true);
    _onboardingComplete = true;
    notifyListeners();
  }

  /// 加载当前班级
  Future<void> _loadCurrentClass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final classId = prefs.getInt(AppConstants.keyCurrentClassId);

      if (classId != null) {
        _currentClass = await _classDAO.getById(classId);
        debugPrint('📖 当前班级: ${_currentClass?.name ?? '未设置'}');
      }
    } catch (e) {
      debugPrint('⚠️  加载当前班级失败: $e');
      _currentClass = null;
    }
  }

  /// 设置当前班级
  Future<void> setCurrentClass(ClassModel classModel) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(AppConstants.keyCurrentClassId, classModel.id!);
    _currentClass = classModel;
    notifyListeners();
  }

  /// 切换班级
  Future<bool> switchClass(ClassModel classModel) async {
    if (_currentClass?.id == classModel.id) return false;

    await setCurrentClass(classModel);
    return true;
  }

  /// 加载班级列表
  Future<void> _loadClasses() async {
    try {
      _classes = await _classDAO.getActiveClasses();
      debugPrint('📚 加载了 ${_classes.length} 个班级');
    } catch (e) {
      debugPrint('⚠️  加载班级列表失败: $e');
      _classes = [];
    }
  }

  /// 加载所有班级（包括非活跃班级）
  Future<List<ClassModel>> loadAllClasses() async {
    try {
      return await _classDAO.getAllClasses();
    } catch (e) {
      debugPrint('⚠️  加载所有班级失败: $e');
      return [];
    }
  }

  /// 刷新班级列表
  Future<void> refreshClasses() async {
    await _loadClasses();
    notifyListeners();
  }

  /// 添加班级
  Future<bool> addClass(ClassModel classModel) async {
    try {
      final id = await _classDAO.insert(classModel);
      final newClass = classModel.copyWith(id: id);

      _classes.add(newClass);
      await setCurrentClass(newClass);

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error adding class: $e');
      return false;
    }
  }

  /// 更新班级
  Future<bool> updateClass(ClassModel classModel) async {
    try {
      await _classDAO.update(classModel);

      // 更新列表中的班级
      final index = _classes.indexWhere((c) => c.id == classModel.id);
      if (index != -1) {
        _classes[index] = classModel;
      }

      // 如果是当前班级，也更新当前班级
      if (_currentClass?.id == classModel.id) {
        _currentClass = classModel;
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating class: $e');
      return false;
    }
  }

  /// 删除班级
  Future<bool> deleteClass(int classId) async {
    try {
      await _classDAO.delete(classId);

      _classes.removeWhere((c) => c.id == classId);

      // 如果删除的是当前班级，清空当前班级
      if (_currentClass?.id == classId) {
        _currentClass = _classes.isNotEmpty ? _classes.first : null;
        if (_currentClass != null) {
          await setCurrentClass(_currentClass!);
        }
      }

      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting class: $e');
      return false;
    }
  }

  /// 清空数据（开发测试用）
  Future<void> clearData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _onboardingComplete = false;
    _currentClass = null;
    _classes = [];

    notifyListeners();
  }
}
