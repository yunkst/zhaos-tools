import 'package:flutter/foundation.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/database/student_dao.dart';
import 'package:teacher_tools/database/note_dao.dart';
import 'package:teacher_tools/utils/excel_importer.dart';
import 'package:teacher_tools/utils/constants.dart';
import 'package:teacher_tools/utils/pinyin_helper.dart';

/// 学生状态管理Provider
class StudentProvider with ChangeNotifier {
  final StudentDAO _studentDAO = StudentDAO();
  final NoteDAO _noteDAO = NoteDAO();

  // 必填字段
  static const List<String> _requiredFields = [
    '学号',
    '姓名',
    '家长1姓名',
    '家长1电话',
  ];

  // 学生列表
  List<Student> _students = [];
  List<Student> get students => _students;

  // 过滤后的学生列表
  List<Student> get filteredStudents => _filterStudents();

  // 搜索关键词
  String _searchKeyword = '';
  String get searchKeyword => _searchKeyword;

  // 性别筛选
  String? _genderFilter;
  String? get genderFilter => _genderFilter;

  // 是否只显示班干部
  bool _onlyPosition = false;
  bool get onlyPosition => _onlyPosition;

  // 加载状态
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  /// 加载班级学生
  Future<void> loadStudents(int classId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _students = await _studentDAO.getByClassId(classId);

      // 批量加载学生的随笔数量
      if (_students.isNotEmpty) {
        final studentIds = _students.map((s) => s.id!).toList();
        final noteCountMap = await _noteDAO.getStudentsNoteCount(studentIds);

        // 填充随笔数量到每个学生对象
        _students = _students.map((s) {
          return s.copyWith(noteCount: noteCountMap[s.id] ?? 0);
        }).toList();
      }
    } catch (e, stackTrace) {
      debugPrint('❌ 加载学生失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      _students = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 过滤学生
  List<Student> _filterStudents() {
    var result = _students;

    // 搜索过滤（支持中文、拼音、首字母、混合搜索）
    if (_searchKeyword.isNotEmpty) {
      result = result.where((s) {
        // 学号匹配
        if (s.studentNumber.contains(_searchKeyword)) return true;

        // 姓名匹配（中文、拼音、首字母、混合）
        return PinyinHelperUtils.matches(
          _searchKeyword,
          s.name,
          s.pinyin,
          s.pinyinAbbr,
        );
      }).toList();
    }

    // 性别过滤
    if (_genderFilter != null) {
      result = result.where((s) => s.gender.value == _genderFilter).toList();
    }

    // 班干部过滤
    if (_onlyPosition) {
      result = result.where((s) => s.hasPosition).toList();
    }

    return result;
  }

  /// 设置搜索关键词
  void setSearchKeyword(String keyword) {
    _searchKeyword = keyword;
    notifyListeners();
  }

  /// 设置性别筛选
  void setGenderFilter(String? gender) {
    _genderFilter = gender;
    notifyListeners();
  }

  /// 设置是否只显示班干部
  void setOnlyPosition(bool value) {
    _onlyPosition = value;
    notifyListeners();
  }

  /// 清除筛选
  void clearFilters() {
    _searchKeyword = '';
    _genderFilter = null;
    _onlyPosition = false;
    notifyListeners();
  }

  /// 添加学生
  Future<bool> addStudent(Student student) async {
    try {
      // 检查学号是否已存在
      final exists = await _studentDAO.isStudentNumberExists(
        student.classId,
        student.studentNumber,
      );

      if (exists) {
        debugPrint('Student number already exists');
        return false;
      }

      final id = await _studentDAO.insert(student);
      _students.add(student.copyWith(id: id));
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ 添加学生失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return false;
    }
  }

  /// 批量插入或更新学生
  /// 如果学号已存在则更新，不存在则插入
  Future<Map<String, int>> insertOrUpdateStudentsBatch(List<Student> students) async {
    try {
      int insertCount = 0;
      int updateCount = 0;

      for (var student in students) {
        final existingStudent = await _studentDAO.getByStudentNumber(
          student.classId,
          student.studentNumber,
        );

        if (existingStudent == null) {
          // 不存在，插入新学生
          await _studentDAO.insert(student);
          _students.add(student.copyWith(id: _students.length + 1)); // 临时ID，会在loadStudents时刷新
          insertCount++;
          debugPrint('✅ 插入学生: ${student.name} (${student.studentNumber})');
        } else {
          // 已存在，更新学生信息
          final updatedStudent = student.copyWith(id: existingStudent.id);
          await _studentDAO.update(updatedStudent);

          // 更新本地列表
          final index = _students.indexWhere((s) => s.id == existingStudent.id);
          if (index != -1) {
            _students[index] = updatedStudent;
          }

          updateCount++;
          debugPrint('🔄 更新学生: ${student.name} (${student.studentNumber})');
        }
      }

      notifyListeners();
      return {
        'inserted': insertCount,
        'updated': updateCount,
        'total': students.length,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ 批量插入或更新学生失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return {
        'inserted': 0,
        'updated': 0,
        'total': 0,
      };
    }
  }

  /// 从Excel导入学生数据（支持部分列和更新）
  Future<Map<String, dynamic>> importStudentsFromExcel(int classId) async {
    try {
      // 1. 读取并解析Excel文件
      final studentsData = await ExcelImporter.importStudentsFromExcel();

      if (studentsData.isEmpty) {
        return {
          'success': false,
          'message': '未找到有效的学生数据',
          'inserted': 0,
          'updated': 0,
        };
      }

      // 2. 获取Excel中的列名
      if (studentsData.isNotEmpty) {
        final headers = studentsData.first.keys.toList();
        debugPrint('📋 Excel列名: $headers');

        // 验证必填字段是否存在
        final missingFields = _requiredFields.where((field) => !headers.contains(field)).toList();
        if (missingFields.isNotEmpty) {
          return {
            'success': false,
            'message': '缺少必填字段: ${missingFields.join(', ')}',
            'inserted': 0,
            'updated': 0,
          };
        }
      }

      // 3. 转换为Student对象（支持部分列）
      final List<Student> students = [];
      final List<String> errors = [];

      for (var i = 0; i < studentsData.length; i++) {
        try {
          final data = studentsData[i];

          // 验证必填字段
          final studentNumber = (data['学号'] ?? '').toString().trim();
          final name = (data['姓名'] ?? '').toString().trim();
          final parentName = (data['家长1姓名'] ?? '').toString().trim();
          final parentPhone = (data['家长1电话'] ?? '').toString().trim();

          if (studentNumber.isEmpty || name.isEmpty || parentName.isEmpty || parentPhone.isEmpty) {
            errors.add('第${i + 2}行必填字段缺失');
            continue;
          }

          // 解析出生日期
          DateTime? birthDate;
          if (data['出生日期'] != null && data['出生日期'].toString().isNotEmpty) {
            try {
              birthDate = DateTime.parse(data['出生日期'].toString());
            } catch (e) {
              birthDate = null;
            }
          }

          // 解析性别
          String genderStr = 'unknown';
          if (data['性别'] != null) {
            final genderValue = data['性别'].toString().trim();
            genderStr = genderValue == '男' ? 'male' : genderValue == '女' ? 'female' : 'unknown';
          }

          // 解析身高
          double? height;
          if (data['身高'] != null && data['身高'].toString().isNotEmpty) {
            try {
              height = double.parse(data['身高'].toString());
            } catch (e) {
              height = null;
            }
          }

          // 构建Student对象（仅包含Excel中提供的字段）
          final student = Student(
            classId: classId,
            name: name,
            studentNumber: studentNumber,
            gender: Gender.fromValue(genderStr),
            birthDate: birthDate,
            height: height,
            vision: data['视力']?.toString().trim(),
            primarySchool: data['毕业小学']?.toString().trim(),
            address: data['家庭住址']?.toString().trim(),
            phone: data['联系方式']?.toString().trim(),
            transportMethod: data['交通方式']?.toString().trim(),
            licensePlate: data['车牌号']?.toString().trim(),
            parentName: parentName,
            parentPhone: parentPhone,
            parentTitle: data['家长1称谓']?.toString().trim(),
            parentCompany: data['家长1工作单位']?.toString().trim(),
            parentPosition: data['家长1职务']?.toString().trim(),
            parentName2: data['家长2姓名']?.toString().trim(),
            parentPhone2: data['家长2电话']?.toString().trim(),
            parentTitle2: data['家长2称谓']?.toString().trim(),
            parentCompany2: data['家长2工作单位']?.toString().trim(),
            parentPosition2: data['家长2职务']?.toString().trim(),
            currentSchool: data['就读小学']?.toString().trim(),
            classPosition: data['担任职务']?.toString().trim(),
            awards: data['获奖情况']?.toString().trim(),
            talents: data['其他特长']?.toString().trim(),
            idCardNumber: data['身份证号']?.toString().trim(),
          );

          students.add(student);
        } catch (e, stackTrace) {
          errors.add('第${i + 2}行数据格式错误: $e');
          debugPrint('❌ 解析第${i + 2}行学生数据失败: $e');
          debugPrint('数据内容: ${studentsData[i]}');
          debugPrint('堆栈跟踪: $stackTrace');
        }
      }

      // 4. 批量插入或更新数据库
      debugPrint('📊 开始批量处理 ${students.length} 名学生...');
      final result = await insertOrUpdateStudentsBatch(students);
      debugPrint('✅ 成功插入 ${result['inserted']} 名学生，更新 ${result['updated']} 名学生');

      // 5. 返回结果
      final inserted = result['inserted'] ?? 0;
      final updated = result['updated'] ?? 0;

      String message;
      if (updated > 0) {
        message = '✅ 成功导入 $inserted 名学生，更新 $updated 名学生';
      } else {
        message = '✅ 成功导入 $inserted 名学生';
      }

      if (errors.isNotEmpty) {
        message += '，${errors.length}条数据有误';
      }

      debugPrint('📋 $message');

      return {
        'success': true,
        'message': message,
        'inserted': inserted,
        'updated': updated,
        'total': inserted + updated,
        'errors': errors,
      };
    } catch (e, stackTrace) {
      debugPrint('❌ 从Excel导入学生失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return {
        'success': false,
        'message': '导入失败: $e',
        'inserted': 0,
        'updated': 0,
      };
    }
  }

  /// 更新学生
  Future<bool> updateStudent(Student student) async {
    try {
      // 检查学号是否与其他学生重复
      final exists = await _studentDAO.isStudentNumberExists(
        student.classId,
        student.studentNumber,
        excludeId: student.id,
      );

      if (exists) {
        debugPrint('Student number already exists');
        return false;
      }

      await _studentDAO.update(student);

      final index = _students.indexWhere((s) => s.id == student.id);
      if (index != -1) {
        _students[index] = student;
      }

      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ 更新学生失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return false;
    }
  }

  /// 删除学生
  Future<bool> deleteStudent(int id) async {
    try {
      await _studentDAO.delete(id);
      _students.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ 删除学生失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return false;
    }
  }

  /// 获取学生详情
  Future<Student?> getStudentDetail(int id) async {
    try {
      final student = await _studentDAO.getById(id);
      return student;
    } catch (e, stackTrace) {
      debugPrint('❌ 获取学生详情失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return null;
    }
  }

  /// 获取学生笔记数量
  Future<int> getStudentNoteCount(int studentId) async {
    try {
      return await _noteDAO.getStudentNoteCount(studentId);
    } catch (e, stackTrace) {
      debugPrint('❌ 获取学生笔记数量失败: $e');
      debugPrint('堆栈跟踪: $stackTrace');
      return 0;
    }
  }
}
