import 'package:teacher_tools/utils/constants.dart';
import 'package:teacher_tools/models/personality_trait.dart';

/// 用于区分"未传入参数"和"显式传入null"的辅助类
class Value<T> {
  final T? value;
  const Value(this.value);
}

/// 学生模型
class Student {
  final int? id;
  final int classId;
  final String name;
  final String studentNumber;
  final Gender gender;
  final DateTime? birthDate;
  final double? height;
  final String? vision;
  final String? phone;
  final String parentName;
  final String parentPhone;
  final String? parentName2;
  final String? parentPhone2;
  final String? classPosition;
  final String? committeePosition;
  final String? personality;
  final String? remarks;
  final String? address;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 新增字段
  final String? idCardNumber;      // 身份证号
  final String? primarySchool;      // 毕业小学
  final String? transportMethod;    // 交通方式
  final String? licensePlate;       // 车牌号
  final String? parentTitle;        // 家长1称谓
  final String? parentCompany;      // 家长1工作单位
  final String? parentPosition;     // 家长1职务
  final String? parentTitle2;       // 家长2称谓
  final String? parentCompany2;     // 家长2工作单位
  final String? parentPosition2;    // 家长2职务
  final String? currentSchool;      // 就读小学
  final String? awards;             // 获奖情况
  final String? talents;            // 其他特长
  final List<PersonalityTrait>? personalityTraits; // 性格特质

  // 拼音搜索字段
  final String? pinyin;             // 姓名全拼 (如: "zhangsan")
  final String? pinyinAbbr;         // 拼音首字母 (如: "zs")

  // 统计字段(非持久化)
  final int? noteCount;             // 随笔数量

  Student({
    this.id,
    required this.classId,
    required this.name,
    required this.studentNumber,
    required this.gender,
    this.birthDate,
    this.height,
    this.vision,
    this.phone,
    required this.parentName,
    required this.parentPhone,
    this.parentName2,
    this.parentPhone2,
    this.classPosition,
    this.committeePosition,
    this.personality,
    this.remarks,
    this.address,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
    // 新增字段
    this.idCardNumber,
    this.primarySchool,
    this.transportMethod,
    this.licensePlate,
    this.parentTitle,
    this.parentCompany,
    this.parentPosition,
    this.parentTitle2,
    this.parentCompany2,
    this.parentPosition2,
    this.currentSchool,
    this.awards,
    this.talents,
    this.personalityTraits,
    // 拼音搜索字段
    this.pinyin,
    this.pinyinAbbr,
    // 统计字段
    this.noteCount,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// 从数据库创建实例
  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] as int?,
      classId: map['class_id'] as int,
      name: map['name'] as String,
      studentNumber: map['student_number'] as String,
      gender: Gender.fromValue(map['gender'] as String? ?? 'unknown'),
      birthDate: map['birth_date'] != null
          ? DateTime.parse(map['birth_date'] as String)
          : null,
      height: map['height'] as double?,
      vision: map['vision'] as String?,
      phone: map['phone'] as String?,
      parentName: map['parent_name'] as String,
      parentPhone: map['parent_phone'] as String,
      parentName2: map['parent_name2'] as String?,
      parentPhone2: map['parent_phone2'] as String?,
      classPosition: map['class_position'] as String?,
      committeePosition: map['committee_position'] as String?,
      personality: map['personality'] as String?,
      remarks: map['remarks'] as String?,
      address: map['address'] as String?,
      isActive: (map['is_active'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      // 新增字段
      idCardNumber: map['id_card_number'] as String?,
      primarySchool: map['primary_school'] as String?,
      transportMethod: map['transport_method'] as String?,
      licensePlate: map['license_plate'] as String?,
      parentTitle: map['parent_title'] as String?,
      parentCompany: map['parent_company'] as String?,
      parentPosition: map['parent_position'] as String?,
      parentTitle2: map['parent_title2'] as String?,
      parentCompany2: map['parent_company2'] as String?,
      parentPosition2: map['parent_position2'] as String?,
      currentSchool: map['current_school'] as String?,
      awards: map['awards'] as String?,
      talents: map['talents'] as String?,
      personalityTraits: map['personality_traits'] != null
          ? PersonalityDimensions.fromJsonList(map['personality_traits'] as String)
          : null,
      // 拼音搜索字段
      pinyin: map['pinyin'] as String?,
      pinyinAbbr: map['pinyin_abbr'] as String?,
      // 统计字段(非持久化,不从数据库读取)
      noteCount: null,
    );
  }

  /// 转换为数据库Map
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'class_id': classId,
      'name': name,
      'student_number': studentNumber,
      'gender': gender.value,
      'birth_date': birthDate?.toIso8601String(),
      'height': height,
      'vision': vision,
      'phone': phone,
      'parent_name': parentName,
      'parent_phone': parentPhone,
      'parent_name2': parentName2,
      'parent_phone2': parentPhone2,
      'class_position': classPosition,
      'committee_position': committeePosition,
      'personality': personality,
      'remarks': remarks,
      'address': address,
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      // 新增字段
      'id_card_number': idCardNumber,
      'primary_school': primarySchool,
      'transport_method': transportMethod,
      'license_plate': licensePlate,
      'parent_title': parentTitle,
      'parent_company': parentCompany,
      'parent_position': parentPosition,
      'parent_title2': parentTitle2,
      'parent_company2': parentCompany2,
      'parent_position2': parentPosition2,
      'current_school': currentSchool,
      'awards': awards,
      'talents': talents,
      'personality_traits': personalityTraits != null
          ? PersonalityDimensions.toJsonList(personalityTraits!)
          : null,
      // 拼音搜索字段
      'pinyin': pinyin,
      'pinyin_abbr': pinyinAbbr,
    };
  }

  /// 复制并更新部分字段
  Student copyWith({
    int? id,
    int? classId,
    String? name,
    String? studentNumber,
    Gender? gender,
    DateTime? birthDate,
    double? height,
    Value<String>? vision,
    Value<String>? phone,
    String? parentName,
    String? parentPhone,
    Value<String>? parentName2,
    Value<String>? parentPhone2,
    Value<String>? classPosition,
    Value<String>? committeePosition,
    Value<String>? personality,
    Value<String>? remarks,
    Value<String>? address,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    // 新增字段
    Value<String>? idCardNumber,
    Value<String>? primarySchool,
    Value<String>? transportMethod,
    Value<String>? licensePlate,
    Value<String>? parentTitle,
    Value<String>? parentCompany,
    Value<String>? parentPosition,
    Value<String>? parentTitle2,
    Value<String>? parentCompany2,
    Value<String>? parentPosition2,
    Value<String>? currentSchool,
    Value<String>? awards,
    Value<String>? talents,
    Value<List<PersonalityTrait>>? personalityTraits,
    // 拼音搜索字段
    Value<String>? pinyin,
    Value<String>? pinyinAbbr,
    // 统计字段
    int? noteCount,
  }) {
    return Student(
      id: id ?? this.id,
      classId: classId ?? this.classId,
      name: name ?? this.name,
      studentNumber: studentNumber ?? this.studentNumber,
      gender: gender ?? this.gender,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      vision: vision != null ? vision.value : this.vision,
      phone: phone != null ? phone.value : this.phone,
      parentName: parentName ?? this.parentName,
      parentPhone: parentPhone ?? this.parentPhone,
      parentName2: parentName2 != null ? parentName2.value : this.parentName2,
      parentPhone2: parentPhone2 != null ? parentPhone2.value : this.parentPhone2,
      classPosition: classPosition != null ? classPosition.value : this.classPosition,
      committeePosition: committeePosition != null ? committeePosition.value : this.committeePosition,
      personality: personality != null ? personality.value : this.personality,
      remarks: remarks != null ? remarks.value : this.remarks,
      address: address != null ? address.value : this.address,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      // 新增字段
      idCardNumber: idCardNumber != null ? idCardNumber.value : this.idCardNumber,
      primarySchool: primarySchool != null ? primarySchool.value : this.primarySchool,
      transportMethod: transportMethod != null ? transportMethod.value : this.transportMethod,
      licensePlate: licensePlate != null ? licensePlate.value : this.licensePlate,
      parentTitle: parentTitle != null ? parentTitle.value : this.parentTitle,
      parentCompany: parentCompany != null ? parentCompany.value : this.parentCompany,
      parentPosition: parentPosition != null ? parentPosition.value : this.parentPosition,
      parentTitle2: parentTitle2 != null ? parentTitle2.value : this.parentTitle2,
      parentCompany2: parentCompany2 != null ? parentCompany2.value : this.parentCompany2,
      parentPosition2: parentPosition2 != null ? parentPosition2.value : this.parentPosition2,
      currentSchool: currentSchool != null ? currentSchool.value : this.currentSchool,
      awards: awards != null ? awards.value : this.awards,
      talents: talents != null ? talents.value : this.talents,
      personalityTraits: personalityTraits != null ? personalityTraits.value : this.personalityTraits,
      // 拼音搜索字段
      pinyin: pinyin != null ? pinyin.value : this.pinyin,
      pinyinAbbr: pinyinAbbr != null ? pinyinAbbr.value : this.pinyinAbbr,
      // 统计字段
      noteCount: noteCount ?? this.noteCount,
    );
  }

  /// 计算年龄
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  /// 获取性别文本
  String get genderText => gender.label;

  /// 是否有班干部职位
  bool get hasPosition => classPosition != null && classPosition!.isNotEmpty;

  /// 是否是家委会成员
  bool get isCommitteeMember =>
      committeePosition != null && committeePosition!.isNotEmpty;

  @override
  String toString() {
    return 'Student{id: $id, name: $name, studentNumber: $studentNumber}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Student && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
