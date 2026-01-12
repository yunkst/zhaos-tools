import 'package:teacher_tools/models/student.dart';
import 'package:teacher_tools/models/note.dart';
import 'package:intl/intl.dart';

/// 学生数据导出服务
/// 将学生信息和随笔整合为Dify需要的格式
class StudentDataExporter {
  /// 导出学生数据用于评语生成
  static Map<String, dynamic> exportForComment(Student student, List<Note> notes) {
    return {
      'student_info': {
        'basic_info': _buildBasicInfo(student),
        'personality_traits': _buildPersonalityTraits(student),
        'health_info': _buildHealthInfo(student),
        'teacher_notes': _buildNotes(notes),
        'summary': _buildSummary(student, notes),
      }
    };
  }

  /// 构建基本信息
  static Map<String, dynamic> _buildBasicInfo(Student student) {
    return {
      'name': student.name,
      'gender': student.gender.label,
      'student_number': student.studentNumber,
      'class_position': student.classPosition,
      'committee_position': student.committeePosition,
      'age': student.age,
    };
  }

  /// 构建性格特质
  static List<Map<String, dynamic>> _buildPersonalityTraits(Student student) {
    if (student.personalityTraits == null || student.personalityTraits!.isEmpty) {
      return [];
    }

    return student.personalityTraits!.map((trait) {
      return {
        'dimension': trait.dimension,
        'value': trait.value,
        'label': trait.value >= 0 ? trait.positiveLabel : trait.negativeLabel,
      };
    }).toList();
  }

  /// 构建健康信息
  static Map<String, dynamic>? _buildHealthInfo(Student student) {
    final hasData = student.height != null || student.vision != null;
    if (!hasData) return null;

    return {
      'height': student.height,
      'vision': student.vision,
    };
  }

  /// 构建教师观察记录
  static List<Map<String, dynamic>> _buildNotes(List<Note> notes) {
    return notes.map((note) {
      return {
        'date': _formatDate(note.occurredAt),
        'title': note.title ?? '无标题',
        'content': note.content,
        'tags': note.tags,
      };
    }).toList();
  }

  /// 构建统计信息
  static Map<String, dynamic> _buildSummary(Student student, List<Note> notes) {
    // 提取所有标签
    final allTags = <String>[];
    for (var note in notes) {
      allTags.addAll(note.tags);
    }

    return {
      'total_notes': notes.length,
      'note_tags_summary': allTags.toSet().toList(),
      'semester': _getCurrentSemester(),
    };
  }

  /// 导出为文本格式（用于调试或直接作为提示词）
  static String exportToText(Student student, List<Note> notes) {
    final buffer = StringBuffer();

    // 基本信息
    buffer.writeln('【学生基本信息】');
    buffer.writeln('姓名：${student.name}');
    buffer.writeln('性别：${student.gender.label}');
    buffer.writeln('学号：${student.studentNumber}');
    if (student.classPosition != null) {
      buffer.writeln('班级职务：${student.classPosition}');
    }
    if (student.age != null) {
      buffer.writeln('年龄：${student.age}岁');
    }
    buffer.writeln();

    // 性格特质
    if (student.personalityTraits != null && student.personalityTraits!.isNotEmpty) {
      buffer.writeln('【性格特质分析】');
      for (var trait in student.personalityTraits!) {
        final label = trait.value >= 0 ? trait.positiveLabel : trait.negativeLabel;
        buffer.writeln('${trait.dimension}：${trait.value}/10（$label）');
      }
      buffer.writeln();
    }

    // 健康信息
    if (student.height != null || student.vision != null) {
      buffer.writeln('【身心健康】');
      if (student.height != null) {
        buffer.writeln('身高：${student.height}cm');
      }
      if (student.vision != null) {
        buffer.writeln('视力：${student.vision}');
      }
      buffer.writeln();
    }

    // 教师观察记录
    if (notes.isNotEmpty) {
      buffer.writeln('【教师观察记录】');
      int index = 1;
      for (var note in notes) {
        buffer.writeln('$index. [${_formatDate(note.occurredAt)}] ${note.title ?? '无标题'}');
        buffer.writeln('   ${note.content}');
        if (note.tags.isNotEmpty) {
          final tags = note.tags.join(' #');
          buffer.writeln('   标签：#$tags');
        }
        buffer.writeln();
        index++;
      }
    }

    // 统计信息
    buffer.writeln('【统计信息】');
    buffer.writeln('本学期记录：${notes.length}条');
    if (notes.isNotEmpty) {
      final allTags = notes.expand((note) => note.tags).toSet().toList();
      buffer.writeln('主要标签：${allTags.join('、')}');
    }
    buffer.writeln('学期：${_getCurrentSemester()}');

    return buffer.toString();
  }

  /// 格式化日期
  static String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// 获取当前学期
  static String _getCurrentSemester() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    if (month >= 2 && month <= 7) {
      return '$year年春季学期';
    } else if (month >= 8 || month == 1) {
      // 1月属于上学年秋季
      final semesterYear = month == 1 ? year - 1 : year;
      return '$semesterYear年秋季学期';
    } else {
      return '$year年寒假';
    }
  }
}
