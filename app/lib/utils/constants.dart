/// 应用常量定义
class AppConstants {
  // 数据库相关
  static const String databaseName = 'teacher_tools.db';
  static const int databaseVersion = 9; // 升级到版本9：添加考试满分字段

  // SharedPreferences Keys
  static const String keyOnboardingComplete = 'onboarding_complete';
  static const String keyCurrentClassId = 'current_class_id';

  // 主题相关
  static const String themeLight = 'light';
  static const String themeDark = 'dark';
  static const String themeSystem = 'system';
}

/// 性别枚举
enum Gender {
  male('male', '男'),
  female('female', '女'),
  unknown('unknown', '未知');

  final String value;
  final String label;

  const Gender(this.value, this.label);

  static Gender fromValue(String value) {
    return Gender.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Gender.unknown,
    );
  }
}

/// 科目枚举
enum Subject {
  math('math', '数学'),
  chinese('chinese', '语文'),
  english('english', '英语'),
  science('science', '科学'),
  morality('morality', '道德');

  final String value;
  final String label;

  const Subject(this.value, this.label);

  static Subject fromValue(String value) {
    return Subject.values.firstWhere(
      (e) => e.value == value,
      orElse: () => Subject.math,
    );
  }
}

/// 考试类型枚举
enum ExamType {
  midTerm('mid_term', '期中考试'),
  finalTerm('final_term', '期末考试'),
  unit('unit', '单元测试'),
  monthly('monthly', '月考'),
  quiz('quiz', '随堂测验'),
  other('other', '其他');

  final String value;
  final String label;

  const ExamType(this.value, this.label);

  static ExamType fromValue(String value) {
    return ExamType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ExamType.other,
    );
  }
}

/// 记录类型枚举（已废弃）
/// 已弃用，请使用标签系统替代
/// 保留此枚举仅用于数据库历史数据兼容
@Deprecated('UI已不再使用事件类型，请使用标签系统替代。此枚举保留仅用于数据库兼容。')
enum NoteType {
  performance('performance', '课堂表现'),
  homework('homework', '作业完成'),
  attendance('attendance', '考勤情况'),
  activity('activity', '活动'),
  other('other', '其他');

  final String value;
  final String label;

  const NoteType(this.value, this.label);

  static NoteType fromValue(String value) {
    return NoteType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => NoteType.other,
    );
  }
}
