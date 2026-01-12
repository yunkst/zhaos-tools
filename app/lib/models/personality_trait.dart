import 'dart:convert';

/// 性格特质模型
class PersonalityTrait {
  final String dimension;      // 维度名称
  final int value;             // 值范围 -10 到 +10
  final String negativeLabel;  // 负向标签
  final String positiveLabel;  // 正向标签

  PersonalityTrait({
    required this.dimension,
    required this.value,
    required this.negativeLabel,
    required this.positiveLabel,
  });

  /// 从JSON创建实例
  factory PersonalityTrait.fromJson(Map<String, dynamic> json) {
    return PersonalityTrait(
      dimension: json['dimension'] as String,
      value: json['value'] as int,
      negativeLabel: json['negativeLabel'] as String,
      positiveLabel: json['positiveLabel'] as String,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'dimension': dimension,
      'value': value,
      'negativeLabel': negativeLabel,
      'positiveLabel': positiveLabel,
    };
  }

  /// 复制并更新部分字段
  PersonalityTrait copyWith({
    String? dimension,
    int? value,
    String? negativeLabel,
    String? positiveLabel,
  }) {
    return PersonalityTrait(
      dimension: dimension ?? this.dimension,
      value: value ?? this.value,
      negativeLabel: negativeLabel ?? this.negativeLabel,
      positiveLabel: positiveLabel ?? this.positiveLabel,
    );
  }

  /// 获取带程度修饰的标签描述（静态工具方法）
  ///
  /// 参数:
  /// - [value]: 性格值 (-10 到 +10)
  /// - [negativeLabel]: 负向标签（如"粗心马虎"）
  /// - [positiveLabel]: 正向标签（如"细心认真"）
  ///
  /// 返回带程度修饰的描述，如"极致细心认真"或"彻底粗心马虎"
  static String getLabelWithLevel({
    required int value,
    required String negativeLabel,
    required String positiveLabel,
  }) {
    if (value == 0) return '中性';

    final absValue = value.abs();
    final isPositive = value > 0;

    // 正向值：使用程度前缀 + positiveLabel
    // 负向值：使用程度副词 + negativeLabel（避免双重否定）
    if (isPositive) {
      String prefix;
      if (absValue == 1) {
        prefix = '尝试性';
      } else if (absValue == 2) {
        prefix = '探索性';
      } else if (absValue == 3) {
        prefix = '萌芽';
      } else if (absValue == 4) {
        prefix = '展现';
      } else if (absValue == 5) {
        prefix = '明显';
      } else if (absValue == 6) {
        prefix = '突出';
      } else if (absValue == 7) {
        prefix = '显著';
      } else if (absValue == 8) {
        prefix = '卓越';
      } else if (absValue == 9) {
        prefix = '杰出';
      } else {
        // absValue == 10
        prefix = '极致';
      }
      return '$prefix$positiveLabel';
    } else {
      // 负向值：根据绝对值选择对应的负面描述
      if (absValue == 1) {
        return '轻微$negativeLabel';
      } else if (absValue == 2) {
        return '轻度$negativeLabel';
      } else if (absValue == 3) {
        return '中度$negativeLabel';
      } else if (absValue == 4) {
        return '较${negativeLabel.substring(0, 2)}';
      } else if (absValue == 5) {
        return negativeLabel; // 直接使用
      } else if (absValue == 6) {
        return '非常$negativeLabel';
      } else if (absValue == 7) {
        return '极度$negativeLabel';
      } else if (absValue == 8) {
        return '完全$negativeLabel';
      } else if (absValue == 9) {
        return '严重$negativeLabel';
      } else {
        // absValue == 10
        return '彻底$negativeLabel';
      }
    }
  }

  /// 获取当前值对应的标签描述（带程度修饰）
  String get currentLabel => getLabelWithLevel(
        value: value,
        negativeLabel: negativeLabel,
        positiveLabel: positiveLabel,
      );

  @override
  String toString() {
    return '$dimension: $value ($currentLabel)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PersonalityTrait &&
        other.dimension == dimension &&
        other.value == value;
  }

  @override
  int get hashCode => dimension.hashCode ^ value.hashCode;
}

/// 性格维度配置
class PersonalityDimensions {
  /// 所有可用的性格维度
  static final List<PersonalityTrait> allDimensions = [
    PersonalityTrait(
      dimension: '细心度',
      value: 0,
      negativeLabel: '粗心马虎',
      positiveLabel: '细心认真',
    ),
    PersonalityTrait(
      dimension: '活泼度',
      value: 0,
      negativeLabel: '内向害羞',
      positiveLabel: '活泼开朗',
    ),
    PersonalityTrait(
      dimension: '耐心度',
      value: 0,
      negativeLabel: '急躁冲动',
      positiveLabel: '耐心沉稳',
    ),
    PersonalityTrait(
      dimension: '独立性',
      value: 0,
      negativeLabel: '依赖性强',
      positiveLabel: '独立自主',
    ),
    PersonalityTrait(
      dimension: '合作度',
      value: 0,
      negativeLabel: '固执独断',
      positiveLabel: '合作友善',
    ),
    PersonalityTrait(
      dimension: '创造力',
      value: 0,
      negativeLabel: '刻板保守',
      positiveLabel: '创新思维',
    ),
  ];

  /// 从JSON数组创建性格特质列表
  static List<PersonalityTrait> fromJsonList(String jsonStr) {
    if (jsonStr.isEmpty) return [];
    try {
      final List<dynamic> jsonList = json.decode(jsonStr);
      return jsonList.map((json) => PersonalityTrait.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 将性格特质列表转换为JSON数组
  static String toJsonList(List<PersonalityTrait> traits) {
    return json.encode(traits.map((t) => t.toJson()).toList());
  }

  /// 获取默认的性格特质列表（全部为0）
  static List<PersonalityTrait> getDefaultTraits() {
    return allDimensions.map((d) => PersonalityTrait(
      dimension: d.dimension,
      value: 0,
      negativeLabel: d.negativeLabel,
      positiveLabel: d.positiveLabel,
    )).toList();
  }

  /// 根据维度名称查找配置
  static PersonalityTrait? getDimensionConfig(String dimension) {
    for (var trait in allDimensions) {
      if (trait.dimension == dimension) return trait;
    }
    return null;
  }
}
