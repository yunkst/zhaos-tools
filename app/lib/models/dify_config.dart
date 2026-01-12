/// Dify配置模型
/// 用于存储Dify后端的连接信息
class DifyConfig {
  final String host;
  final String token;

  const DifyConfig({
    required this.host,
    required this.token,
  });

  /// 从JSON创建
  factory DifyConfig.fromJson(Map<String, dynamic> json) {
    return DifyConfig(
      host: json['host'] as String,
      token: json['token'] as String,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'host': host,
      'token': token,
    };
  }

  /// 复制并更新部分字段
  DifyConfig copyWith({
    String? host,
    String? token,
  }) {
    return DifyConfig(
      host: host ?? this.host,
      token: token ?? this.token,
    );
  }

  /// 验证配置是否有效
  bool get isValid {
    return host.isNotEmpty && token.isNotEmpty;
  }

  /// 获取授权头
  String get authorizationHeader => 'Bearer $token';

  /// 获取API基础URL
  String get apiBaseUrl => host.endsWith('/') ? host : '$host/';

  @override
  String toString() {
    return 'DifyConfig{host: $host, token: ${token.substring(0, 8)}...}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DifyConfig &&
        other.host == host &&
        other.token == token;
  }

  @override
  int get hashCode => Object.hash(host, token);
}
