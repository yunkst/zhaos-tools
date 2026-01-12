import 'package:sqflite/sqflite.dart';
import 'package:teacher_tools/database/database_helper.dart';
import 'package:teacher_tools/models/note.dart';

/// 笔记数据访问对象
class NoteDAO {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// 插入笔记
  Future<int> insert(Note note) async {
    return await _db.insert('notes', note.toMap());
  }

  /// 更新笔记
  Future<int> update(Note note) async {
    if (note.id == null) return 0;
    return await _db.update(
      'notes',
      note.toMap(),
      where: 'id = ?',
      whereArgs: [note.id],
    );
  }

  /// 删除笔记
  Future<int> delete(int id) async {
    return await _db.delete(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 根据ID获取笔记
  Future<Note?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'notes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Note.fromMap(maps.first);
  }

  /// 获取学生的所有笔记
  Future<List<Note>> getByStudentId(int studentId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'notes',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'occurred_at DESC',
    );

    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// 获取班级的所有笔记
  Future<List<Note>> getByClassId(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'notes',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'occurred_at DESC',
    );

    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// 获取最近的笔记
  Future<List<Note>> getRecentNotes(int classId, {int limit = 10}) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'notes',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'occurred_at DESC',
      limit: limit,
    );

    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// 根据标签搜索笔记
  Future<List<Note>> searchByTag(int classId, String tag) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      'SELECT * FROM notes WHERE class_id = ? AND tags LIKE ? ORDER BY occurred_at DESC',
      [classId, '%"$tag"%'],
    );

    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// 搜索笔记内容
  Future<List<Note>> search(int classId, String keyword) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'notes',
      where: 'class_id = ? AND (title LIKE ? OR content LIKE ?)',
      whereArgs: [classId, '%$keyword%', '%$keyword%'],
      orderBy: 'occurred_at DESC',
    );

    return maps.map((map) => Note.fromMap(map)).toList();
  }

  /// 获取笔记数量
  Future<int> getCount(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE class_id = ?',
      [classId],
    );
    return Sqflite.firstIntValue(maps) ?? 0;
  }

  /// 获取学生笔记数量
  Future<int> getStudentNoteCount(int studentId) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM notes WHERE student_id = ?',
      [studentId],
    );
    return Sqflite.firstIntValue(maps) ?? 0;
  }

  /// 批量获取多个学生的笔记数量
  /// 返回 Map，key为学生ID，value为笔记数量
  Future<Map<int, int>> getStudentsNoteCount(List<int> studentIds) async {
    if (studentIds.isEmpty) return {};

    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      'SELECT student_id, COUNT(*) as count FROM notes WHERE student_id IN (${studentIds.map((id) => '?').join(',')}) GROUP BY student_id',
      studentIds,
    );

    return {
      for (var map in maps)
        map['student_id'] as int: map['count'] as int,
    };
  }
}
