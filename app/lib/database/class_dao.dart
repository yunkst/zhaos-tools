import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:teacher_tools/database/database_helper.dart';
import 'package:teacher_tools/models/class_model.dart';

/// 班级数据访问对象
class ClassDAO {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// 插入班级
  Future<int> insert(ClassModel classModel) async {
    return await _db.insert('classes', classModel.toMap());
  }

  /// 更新班级
  Future<int> update(ClassModel classModel) async {
    if (classModel.id == null) return 0;
    return await _db.update(
      'classes',
      classModel.toMap(),
      where: 'id = ?',
      whereArgs: [classModel.id],
    );
  }

  /// 删除班级
  Future<int> delete(int id) async {
    return await _db.delete(
      'classes',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// 根据ID获取班级
  Future<ClassModel?> getById(int id) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'classes',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (maps.isEmpty) return null;
      return ClassModel.fromMap(maps.first);
    } catch (e) {
      debugPrint('⚠️  获取班级 $id 失败: $e');
      return null;
    }
  }

  /// 获取所有班级
  Future<List<ClassModel>> getAll() async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'classes',
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => ClassModel.fromMap(map)).toList();
  }

  /// 获取所有班级（包括非活跃班级）
  Future<List<ClassModel>> getAllClasses() async {
    return await getAll();
  }

  /// 获取激活的班级列表
  Future<List<ClassModel>> getActiveClasses() async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query(
        'classes',
        where: 'is_active = ?',
        whereArgs: [1],
        orderBy: 'created_at DESC',
      );

      return maps.map((map) => ClassModel.fromMap(map)).toList();
    } catch (e) {
      debugPrint('⚠️  获取班级列表失败: $e');
      return [];
    }
  }

  /// 搜索班级（按名称）
  Future<List<ClassModel>> search(String keyword) async {
    final List<Map<String, dynamic>> maps = await _db.query(
      'classes',
      where: 'name LIKE ?',
      whereArgs: ['%$keyword%'],
      orderBy: 'created_at DESC',
    );

    return maps.map((map) => ClassModel.fromMap(map)).toList();
  }

  /// 获取班级数量
  Future<int> getCount() async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM classes',
    );
    return Sqflite.firstIntValue(maps) ?? 0;
  }

  /// 获取班级学生数量
  Future<int> getStudentCount(int classId) async {
    final List<Map<String, dynamic>> maps = await _db.rawQuery(
      'SELECT COUNT(*) as count FROM students WHERE class_id = ? AND is_active = ?',
      [classId, 1],
    );
    return Sqflite.firstIntValue(maps) ?? 0;
  }
}
