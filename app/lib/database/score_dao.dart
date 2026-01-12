import 'package:sqflite/sqflite.dart';
import 'package:teacher_tools/database/database_helper.dart';
import 'package:teacher_tools/models/score.dart';

/// 成绩数据访问对象
class ScoreDAO {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// 插入成绩
  Future<int> insert(Score score) async {
    return await _db.insert('scores', score.toMap());
  }

  /// 批量插入成绩
  Future<int> insertBatch(List<Score> scores) async {
    int count = 0;
    for (var score in scores) {
      count += await insert(score);
    }
    return count;
  }

  /// 更新成绩
  Future<int> update(Score score) async {
    if (score.id == null) return 0;
    return await _db.update(
      'scores',
      score.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [score.id],
    );
  }

  /// 删除成绩
  Future<int> delete(int id) async {
    return await _db.delete(
      'scores',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 根据ID获取成绩
  Future<Score?> getById(int id) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'scores',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Score.fromMap(maps.first);
  }

  /// 获取考试的所有成绩
  Future<List<Score>> getByExamId(int examId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'scores',
      where: 'exam_id = ?',
      whereArgs: [examId],
      orderBy: 'score DESC',
    );

    return maps.map((map) => Score.fromMap(map)).toList();
  }

  /// 获取学生的所有成绩
  Future<List<Score>> getByStudentId(int studentId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'scores',
      where: 'student_id = ?',
      whereArgs: [studentId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Score.fromMap(map)).toList();
  }

  /// 获取班级成绩
  Future<List<Score>> getByClassId(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'scores',
      where: 'class_id = ?',
      whereArgs: [classId],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => Score.fromMap(map)).toList();
  }

  /// 获取学生在某次考试的成绩
  Future<Score?> getStudentExamScore(int examId, int studentId) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'scores',
      where: 'exam_id = ? AND student_id = ?',
      whereArgs: [examId, studentId],
      limit: 1,
    );

    if (maps.isEmpty) return null;
    return Score.fromMap(maps.first);
  }

  /// 检查成绩是否已存在
  Future<bool> isScoreExists(int examId, int studentId) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM scores WHERE exam_id = ? AND student_id = ?',
      [examId, studentId],
    );
    final count = Sqflite.firstIntValue(maps) ?? 0;
    return count > 0;
  }

  /// 更新排名
  Future<int> updateRanking(int examId) async {
    // 先获取考试的所有成绩，按分数排序
    final scores = await getByExamId(examId);

    // 更新每个学生的排名
    int count = 0;
    for (int i = 0; i < scores.length; i++) {
      final ranking = i + 1;
      count += await _db.update(
        'scores',
        {'ranking': ranking},
        where: 'id = ?',
        whereArgs: [scores[i].id],
      );
    }

    return count;
  }

  /// 获取成绩数量
  Future<int> getCount(int examId) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM scores WHERE exam_id = ?',
      [examId],
    );
    return Sqflite.firstIntValue(maps) ?? 0;
  }

  /// 删除考试的所有成绩
  Future<int> deleteByExamId(int examId) async {
    return await _db.delete(
      'scores',
      where: 'exam_id = ?',
      whereArgs: [examId],
    );
  }
}
