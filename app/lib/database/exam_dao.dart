import 'package:sqflite/sqflite.dart';
import 'package:teacher_tools/database/database_helper.dart';
import 'package:teacher_tools/models/exam.dart';

/// 考试数据访问对象
class ExamDAO {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// 插入考试
  Future<int> insert(Exam exam) async {
    return await _db.insert('exams', exam.toMap());
  }

  /// 更新考试
  Future<int> update(Exam exam) async {
    if (exam.id == null) return 0;
    return await _db.update(
      'exams',
      exam.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [exam.id],
    );
  }

  /// 删除考试
  Future<int> delete(int id) async {
    return await _db.delete(
      'exams',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 根据ID获取考试
  Future<Exam?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'exams',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Exam.fromMap(maps.first);
  }

  /// 获取班级的所有考试
  Future<List<Exam>> getByClassId(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'exams',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'exam_date DESC',
    );

    return maps.map((map) => Exam.fromMap(map)).toList();
  }

  /// 根据科目获取考试
  Future<List<Exam>> getBySubject(int classId, String subject) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'exams',
      where: 'class_id = ? AND subject = ?',
      whereArgs: [classId, subject],
      orderBy: 'exam_date DESC',
    );

    return maps.map((map) => Exam.fromMap(map)).toList();
  }

  /// 根据类型获取考试
  Future<List<Exam>> getByType(int classId, String type) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'exams',
      where: 'class_id = ? AND type = ?',
      whereArgs: [classId, type],
      orderBy: 'exam_date DESC',
    );

    return maps.map((map) => Exam.fromMap(map)).toList();
  }

  /// 获取最近的考试
  Future<List<Exam>> getRecentExams(int classId, {int limit = 5}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'exams',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'exam_date DESC',
      limit: limit,
    );

    return maps.map((map) => Exam.fromMap(map)).toList();
  }

  /// 获取日期范围内的考试
  Future<List<Exam>> getByDateRange(int classId, DateTime start, DateTime end) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'exams',
      where: 'class_id = ? AND exam_date BETWEEN ? AND ?',
      whereArgs: [classId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'exam_date DESC',
    );

    return maps.map((map) => Exam.fromMap(map)).toList();
  }

  /// 搜索考试
  Future<List<Exam>> search(int classId, String keyword) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'exams',
      where: 'class_id = ? AND name LIKE ?',
      whereArgs: [classId, '%$keyword%'],
      orderBy: 'exam_date DESC',
    );

    return maps.map((map) => Exam.fromMap(map)).toList();
  }

  /// 获取考试数量
  Future<int> getCount(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM exams WHERE class_id = ?',
      [classId],
    );
    return Sqflite.firstIntValue(maps) ?? 0;
  }

  /// 获取班级的所有考试组
  /// 返回按 exam_group_id 分组的考试
  Future<List<Map<String, dynamic>>> getExamGroups(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery('''
      SELECT
        exam_group_id,
        class_id,
        name,
        type,
        exam_date,
        COUNT(*) as subject_count,
        (SELECT COUNT(DISTINCT s.student_id)
         FROM scores s
         JOIN exams e ON s.exam_id = e.id
         WHERE e.exam_group_id = exams.exam_group_id) as total_students,
        MIN(created_at) as created_at
      FROM exams
      WHERE class_id = ? AND exam_group_id IS NOT NULL
      GROUP BY exam_group_id
      ORDER BY exam_date DESC
    ''', [classId]);

    return maps;
  }

  /// 根据 exam_group_id 获取该组的所有科目考试
  Future<List<Exam>> getByExamGroupId(int examGroupId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'exams',
      where: 'exam_group_id = ?',
      whereArgs: [examGroupId],
      orderBy: 'subject ASC',
    );

    return maps.map((map) => Exam.fromMap(map)).toList();
  }

  /// 根据 exam_group_id 删除整组考试
  Future<int> deleteByExamGroupId(int examGroupId) async {
    return await _db.delete(
      'exams',
      where: 'exam_group_id = ?',
      whereArgs: [examGroupId],
    );
  }
}
