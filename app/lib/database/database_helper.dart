import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:teacher_tools/utils/constants.dart';

/// 数据库帮助类
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() => instance;

  DatabaseHelper._internal();

  /// 获取数据库实例
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// 初始化数据库
  Future<Database> _initDatabase() async {
    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, AppConstants.databaseName);

      debugPrint('📂 正在初始化数据库: $path');

      final db = await openDatabase(
        path,
        version: AppConstants.databaseVersion,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );

      debugPrint('✅ 数据库初始化成功');
      return db;
    } catch (e, stackTrace) {
      debugPrint('❌ 数据库初始化失败: $e');
      debugPrint('堆栈信息: $stackTrace');
      rethrow;
    }
  }

  /// 创建数据库表
  Future<void> _onCreate(Database db, int version) async {
    // 创建班级表
    await db.execute('''
      CREATE TABLE classes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // 创建学生表
    await db.execute('''
      CREATE TABLE students (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        student_number TEXT NOT NULL,
        gender TEXT NOT NULL,
        birth_date TEXT,
        height REAL,
        vision TEXT,
        phone TEXT,
        parent_name TEXT NOT NULL,
        parent_phone TEXT NOT NULL,
        parent_name2 TEXT,
        parent_phone2 TEXT,
        class_position TEXT,
        committee_position TEXT,
        personality TEXT,
        remarks TEXT,
        address TEXT,
        is_active INTEGER DEFAULT 1,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        id_card_number TEXT,
        primary_school TEXT,
        transport_method TEXT,
        license_plate TEXT,
        parent_title TEXT,
        parent_company TEXT,
        parent_position TEXT,
        parent_title2 TEXT,
        parent_company2 TEXT,
        parent_position2 TEXT,
        current_school TEXT,
        awards TEXT,
        talents TEXT,
        personality_traits TEXT,
        pinyin TEXT,
        pinyin_abbr TEXT,
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
        UNIQUE(class_id, student_number)
      )
    ''');

    // 创建学生表索引
    await db.execute('CREATE INDEX idx_students_class ON students(class_id)');
    await db.execute('CREATE INDEX idx_students_number ON students(student_number)');

    // 创建笔记表
    await db.execute('''
      CREATE TABLE notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        class_id INTEGER NOT NULL,
        title TEXT,
        content TEXT NOT NULL,
        type TEXT NOT NULL,
        tags TEXT,
        occurred_at TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE
      )
    ''');

    // 创建笔记表索引
    await db.execute('CREATE INDEX idx_notes_student ON notes(student_id)');
    await db.execute('CREATE INDEX idx_notes_class ON notes(class_id)');
    await db.execute('CREATE INDEX idx_notes_date ON notes(occurred_at DESC)');

    // 创建考试表
    await db.execute('''
      CREATE TABLE exams (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        class_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        subject TEXT NOT NULL,
        type TEXT NOT NULL,
        exam_date TEXT NOT NULL,
        average_score REAL,
        max_score REAL,
        min_score REAL,
        pass_count INTEGER,
        student_count INTEGER,
        full_score REAL DEFAULT 100,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
        CHECK(subject IN ('math', 'chinese', 'english', 'science', 'morality'))
      )
    ''');

    // 创建考试表索引
    await db.execute('CREATE INDEX idx_exams_class ON exams(class_id)');
    await db.execute('CREATE INDEX idx_exams_date ON exams(exam_date DESC)');
    await db.execute('CREATE INDEX idx_exams_subject ON exams(subject)');

    // 创建成绩表
    await db.execute('''
      CREATE TABLE scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        exam_id INTEGER NOT NULL,
        student_id INTEGER NOT NULL,
        class_id INTEGER NOT NULL,
        score REAL NOT NULL,
        full_score REAL DEFAULT 100,
        ranking INTEGER,
        school_ranking INTEGER,
        remarks TEXT,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        FOREIGN KEY (exam_id) REFERENCES exams(id) ON DELETE CASCADE,
        FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE,
        FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
        UNIQUE(exam_id, student_id)
      )
    ''');

    // 创建成绩表索引
    await db.execute('CREATE INDEX idx_scores_exam ON scores(exam_id)');
    await db.execute('CREATE INDEX idx_scores_student ON scores(student_id)');
    await db.execute('CREATE INDEX idx_scores_class ON scores(class_id)');
  }

  /// 数据库升级
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // 版本 2 -> 3: 扩展学生表字段（支持完整Excel导入）
    if (oldVersion < 3) {
      // 由于是初始阶段无数据，直接重建表
      await db.execute('DROP TABLE IF EXISTS students');

      // 创建新的学生表（包含所有字段）
      await db.execute('''
        CREATE TABLE students (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          class_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          student_number TEXT NOT NULL,
          gender TEXT NOT NULL,
          birth_date TEXT,
          height REAL,
          vision TEXT,
          phone TEXT,
          parent_name TEXT NOT NULL,
          parent_phone TEXT NOT NULL,
          parent_name2 TEXT,
          parent_phone2 TEXT,
          class_position TEXT,
          committee_position TEXT,
          personality TEXT,
          remarks TEXT,
          address TEXT,
          is_active INTEGER DEFAULT 1,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          id_card_number TEXT,
          primary_school TEXT,
          transport_method TEXT,
          license_plate TEXT,
          parent_title TEXT,
          parent_company TEXT,
          parent_position TEXT,
          parent_title2 TEXT,
          parent_company2 TEXT,
          parent_position2 TEXT,
          current_school TEXT,
          awards TEXT,
          talents TEXT,
          FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
          UNIQUE(class_id, student_number)
        )
      ''');

      // 重建索引
      await db.execute('CREATE INDEX idx_students_class ON students(class_id)');
      await db.execute('CREATE INDEX idx_students_number ON students(student_number)');
    }

    // 版本 3 -> 4: 添加性格特质字段
    if (oldVersion < 4) {
      await db.execute('ALTER TABLE students ADD COLUMN personality_traits TEXT');
    }

    // 版本 4 -> 5: 添加拼音搜索字段
    if (oldVersion < 5) {
      await db.execute('ALTER TABLE students ADD COLUMN pinyin TEXT');
      await db.execute('ALTER TABLE students ADD COLUMN pinyin_abbr TEXT');
    }

    // 版本 5 -> 6: 迁移考试科目从中文到英文
    if (oldVersion < 6) {
      // 由于SQLite不支持直接修改CHECK约束，需要重建表
      debugPrint('🔄 开始迁移考试表：科目字段从中文改为英文');

      // 1. 备份数据
      final List<Map<String, dynamic>> exams = await db.query('exams');

      // 2. 删除旧表
      await db.execute('DROP TABLE IF EXISTS exams');

      // 3. 创建新表（使用英文科目值）
      await db.execute('''
        CREATE TABLE exams (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          class_id INTEGER NOT NULL,
          name TEXT NOT NULL,
          subject TEXT NOT NULL,
          type TEXT NOT NULL,
          exam_date TEXT NOT NULL,
          average_score REAL,
          max_score REAL,
          min_score REAL,
          pass_count INTEGER,
          student_count INTEGER,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL,
          FOREIGN KEY (class_id) REFERENCES classes(id) ON DELETE CASCADE,
          CHECK(subject IN ('math', 'chinese', 'english', 'science', 'morality'))
        )
      ''');

      // 4. 创建索引
      await db.execute('CREATE INDEX idx_exams_class ON exams(class_id)');
      await db.execute('CREATE INDEX idx_exams_date ON exams(exam_date DESC)');
      await db.execute('CREATE INDEX idx_exams_subject ON exams(subject)');

      // 5. 迁移数据（将中文科目名转换为英文）
      final subjectMapping = {
        '数学': 'math',
        '语文': 'chinese',
        '英语': 'english',
        '科学': 'science',
        '道德': 'morality',
      };

      for (var exam in exams) {
        final chineseSubject = exam['subject'] as String;
        final englishSubject = subjectMapping[chineseSubject] ?? chineseSubject;

        await db.insert('exams', {
          ...exam,
          'subject': englishSubject,
        });
      }

      debugPrint('✅ 考试表迁移完成，共迁移 ${exams.length} 条记录');
    }

    // 版本 6 -> 7: 添加 exam_group_id 字段，支持考试批次管理
    if (oldVersion < 7) {
      debugPrint('🔄 开始添加考试批次ID字段');

      // 1. 添加 exam_group_id 字段
      await db.execute('ALTER TABLE exams ADD COLUMN exam_group_id INTEGER');

      // 2. 为已有数据生成 exam_group_id
      // 按 (class_id, name, exam_date) 分组
      final exams = await db.query('exams', orderBy: 'class_id, name, exam_date');

      int currentGroupId = DateTime.now().millisecondsSinceEpoch;
      String? lastGroupKey;

      for (var exam in exams) {
        final examDate = (exam['exam_date'] as String).substring(0, 10); // 只取日期部分
        final groupKey = '${exam['class_id']}_${exam['name']}_$examDate';

        // 如果分组key变化，生成新的groupId
        if (groupKey != lastGroupKey) {
          currentGroupId++;
          lastGroupKey = groupKey;
        }

        // 更新该记录的 exam_group_id
        await db.update(
          'exams',
          {'exam_group_id': currentGroupId},
          where: 'id = ?',
          whereArgs: [exam['id']],
        );
      }

      // 3. 创建索引
      await db.execute('CREATE INDEX IF NOT EXISTS idx_exams_group ON exams(exam_group_id)');

      debugPrint('✅ 考试批次ID字段添加完成');
    }

    // 版本 7 -> 8: 添加 school_ranking 字段，存储总校排名
    if (oldVersion < 8) {
      debugPrint('🔄 开始添加总校排名字段');
      await db.execute('ALTER TABLE scores ADD COLUMN school_ranking INTEGER');
      debugPrint('✅ 总校排名字段添加完成');
    }

    // 版本 8 -> 9: 添加 full_score 字段到 exams 表
    if (oldVersion < 9) {
      debugPrint('🔄 开始添加考试满分字段');

      // 1. 添加 full_score 字段
      await db.execute('ALTER TABLE exams ADD COLUMN full_score REAL DEFAULT 100');

      // 2. 为已有数据根据科目设置满分
      final exams = await db.query('exams');
      int updateCount = 0;

      for (var exam in exams) {
        final subject = exam['subject'] as String?;
        // 道德科目满分100，其他科目满分120
        final fullScore = (subject == 'morality') ? 100.0 : 120.0;

        await db.update(
          'exams',
          {'full_score': fullScore},
          where: 'id = ?',
          whereArgs: [exam['id']],
        );
        updateCount++;
      }

      debugPrint('✅ 考试满分字段添加完成，已更新 $updateCount 条记录');
    }
  }

  /// 通用查询方法
  Future<List<Map<String, dynamic>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      distinct: distinct,
      columns: columns,
      where: where,
      whereArgs: whereArgs,
      groupBy: groupBy,
      having: having,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  /// 通用插入方法
  Future<int> insert(String table, Map<String, Object?> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  /// 通用更新方法
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  /// 通用删除方法
  Future<int> delete(
    String table, {
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  /// 执行原始SQL
  Future<List<Map<String, dynamic>>> rawQuery(
    String sql, [
    List<Object?>? arguments,
  ]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  /// 关闭数据库
  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  /// 清空所有数据（开发测试用）
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('scores');
    await db.delete('exams');
    await db.delete('notes');
    await db.delete('students');
    await db.delete('classes');
  }
}
