import 'dart:convert';
import 'package:teacher_tools/utils/constants.dart';

/// 随笔事件模型
class Note {
  final int? id;
  final int studentId;
  final int classId;
  final String? title;
  final String content;

  /// 事件类型（已废弃，保留以兼容数据库）
  /// UI 层已不再使用此字段，新记录默认为 NoteType.other
  @Deprecated('UI已不再使用事件类型，请使用标签系统替代。此字段保留仅用于数据库兼容。')
  final NoteType type;

  final List<String> tags;
  final DateTime occurredAt;
  final DateTime createdAt;

  Note({
    this.id,
    required this.studentId,
    required this.classId,
    this.title,
    required this.content,
    required this.type,
    List<String>? tags,
    DateTime? occurredAt,
    DateTime? createdAt,
  })  : tags = tags ?? [],
        occurredAt = occurredAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  /// 从数据库创建实例
  factory Note.fromMap(Map<String, dynamic> map) {
    return Note(
      id: map['id'] as int?,
      studentId: map['student_id'] as int,
      classId: map['class_id'] as int,
      title: map['title'] as String?,
      content: map['content'] as String,
      // ignore: deprecated_member_use_from_same_package
      type: NoteType.fromValue(map['type'] as String? ?? 'other'),
      tags: map['tags'] != null
          ? List<String>.from(jsonDecode(map['tags'] as String))
          : [],
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'student_id': studentId,
      'class_id': classId,
      'title': title,
      'content': content,
      // ignore: deprecated_member_use_from_same_package
      'type': type.value,
      'tags': jsonEncode(tags),
      'occurred_at': occurredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// 复制并更新部分字段
  Note copyWith({
    int? id,
    int? studentId,
    int? classId,
    String? title,
    String? content,
    // ignore: deprecated_member_use_from_same_package
    NoteType? type,
    List<String>? tags,
    DateTime? occurredAt,
    DateTime? createdAt,
  }) {
    return Note(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      classId: classId ?? this.classId,
      title: title ?? this.title,
      content: content ?? this.content,
      // ignore: deprecated_member_use_from_same_package
      type: type ?? this.type,
      tags: tags ?? this.tags,
      occurredAt: occurredAt ?? this.occurredAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// 获取类型文本（已废弃）
  @Deprecated('UI已不再使用事件类型，此方法已废弃')
  // ignore: deprecated_member_use_from_same_package
  String get typeText => type.label;

  /// 是否有标签
  bool get hasTags => tags.isNotEmpty;

  @override
  String toString() {
    // ignore: deprecated_member_use_from_same_package
    return 'Note{id: $id, title: $title, type: $type, occurredAt: $occurredAt}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Note && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
