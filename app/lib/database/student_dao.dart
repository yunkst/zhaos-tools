import 'package:sqflite/sqflite.dart';
import 'package:teacher_tools/database/database_helper.dart';
import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/utils/pinyin_helper.dart';

/// 学生数据访问对象
class StudentDAO {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// 插入学生
  Future<int> insert(Student student) async {
    // 自动生成拼音
    final pinyin = PinyinHelperUtils.getPinyin(student.name);
    final pinyinAbbr = PinyinHelperUtils.getPinyinAbbr(student.name);

    // 如果学生对象中已有拼音（比如从Excel导入时已生成），则使用已有的
    final studentWithPinyin = student.copyWith(
      pinyin: Value(student.pinyin ?? pinyin),
      pinyinAbbr: Value(student.pinyinAbbr ?? pinyinAbbr),
    );

    return await _db.insert('students', studentWithPinyin.toMap());
  }

  /// 批量插入学生
  Future<int> insertBatch(List<Student> students) async {
    int count = 0;
    for (var student in students) {
      count += await insert(student);
    }
    return count;
  }

  /// 更新学生
  Future<int> update(Student student) async {
    if (student.id == null) return 0;

    // 自动生成拼音（如果姓名有变化）
    final pinyin = PinyinHelperUtils.getPinyin(student.name);
    final pinyinAbbr = PinyinHelperUtils.getPinyinAbbr(student.name);

    final studentWithPinyin = student.copyWith(
      updatedAt: DateTime.now(),
      pinyin: Value(student.pinyin ?? pinyin),
      pinyinAbbr: Value(student.pinyinAbbr ?? pinyinAbbr),
    );

    return await _db.update(
      'students',
      studentWithPinyin.toMap(),
      where: 'id = ?',
      whereArgs: [student.id],
    );
  }

  /// 删除学生
  Future<int> delete(int id) async {
    return await _db.delete(
      'students',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 软删除学生（标记为不活跃）
  Future<int> softDelete(int id) async {
    return await _db.update(
      'students',
      {'is_active': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 根据ID获取学生
  Future<Student?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'students',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Student.fromMap(maps.first);
  }

  /// 根据学号获取学生
  Future<Student?> getByStudentNumber(int classId, String studentNumber) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'students',
      where: 'class_id = ? AND student_number = ?',
      whereArgs: [classId, studentNumber],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Student.fromMap(maps.first);
  }

  /// 获取班级所有学生
  Future<List<Student>> getByClassId(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'students',
      where: 'class_id = ? AND is_active = ?',
      whereArgs: [classId, 1],
    );

    final students = maps.map((map) => Student.fromMap(map)).toList();

    // 按学号的数字值排序
    students.sort((a, b) {
      final aNum = int.tryParse(a.studentNumber) ?? double.maxFinite.toInt();
      final bNum = int.tryParse(b.studentNumber) ?? double.maxFinite.toInt();
      return aNum.compareTo(bNum);
    });

    return students;
  }

  /// 获取所有学生
  Future<List<Student>> getAll() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'students',
      where: 'is_active = ?',
      whereArgs: [1],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Student.fromMap(map)).toList();
  }

  /// 搜索学生
  Future<List<Student>> search(int classId, String keyword) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'students',
      where: 'class_id = ? AND is_active = ? AND (name LIKE ? OR student_number LIKE ?)',
      whereArgs: [classId, 1, '%$keyword%', '%$keyword%'],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Student.fromMap(map)).toList();
  }

  /// 根据性别筛选
  Future<List<Student>> filterByGender(int classId, String gender) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'students',
      where: 'class_id = ? AND is_active = ? AND gender = ?',
      whereArgs: [classId, 1, gender],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Student.fromMap(map)).toList();
  }

  /// 获取有班干部职位的学生
  Future<List<Student>> getWithPosition(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'students',
      where: 'class_id = ? AND is_active = ? AND class_position IS NOT NULL AND class_position != ""',
      whereArgs: [classId, 1],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Student.fromMap(map)).toList();
  }

  /// 获取家委会成员
  Future<List<Student>> getCommitteeMembers(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'students',
      where: 'class_id = ? AND is_active = ? AND committee_position IS NOT NULL AND committee_position != ""',
      whereArgs: [classId, 1],
      orderBy: 'name ASC',
    );

    return maps.map((map) => Student.fromMap(map)).toList();
  }

  /// 获取班级学生数量
  Future<int> getCount(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM students WHERE class_id = ? AND is_active = ?',
      [classId, 1],
    );
    return Sqflite.firstIntValue(maps) ?? 0;
  }

  /// 检查学号是否存在
  Future<bool> isStudentNumberExists(int classId, String studentNumber, {int? excludeId}) async {
    String sql = 'SELECT COUNT(*) as count FROM students WHERE class_id = ? AND student_number = ?';
    List<Object?> args = [classId, studentNumber];

    if (excludeId != null) {
      sql += ' AND id != ?';
      args.add(excludeId);
    }

    final List<Map<String, dynamic>> maps = await _db.rawQuery(sql, args);
    final count = Sqflite.firstIntValue(maps) ?? 0;
    return count > 0;
  }
}
