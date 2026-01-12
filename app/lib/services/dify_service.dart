import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:teacher_tools/models/dify_config.dart';

/// Dify API服务
/// 用于调用Dify工作流并流式接收响应
class DifyService {
  final DifyConfig config;
  final http.Client _client;

  DifyService({
    required this.config,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// 运行工作流并流式返回结果
  ///
  /// [studentInfo] - 学生信息JSON字符串
  /// [cmd] - 命令参数（如"单独生成期末评语"）
  /// 返回Stream，每次接收到数据块就发出
  Stream<String> runWorkflow(String studentInfo, String cmd) async* {
    // 验证配置
    if (!config.isValid) {
      throw Exception('Dify配置无效，请检查host和token');
    }

    // 构建请求URL
    final url = Uri.parse('${config.apiBaseUrl}v1/workflows/run');

    // 构建请求体
    final body = jsonEncode({
      'inputs': {
        'student_info': studentInfo,
        'cmd': cmd,
      },
      'response_mode': 'streaming', // 启用流式响应
      'user': 'teacher-app',
    });

    debugPrint('🚀 [DifyService] 发送请求到: $url');
    debugPrint('📦 [DifyService] 请求体: $body');

    try {
      // 发送POST请求
      final request = http.Request('POST', url);
      request.headers.addAll({
        'Authorization': config.authorizationHeader,
        'Content-Type': 'application/json',
        'Accept': 'text/event-stream',
      });
      request.body = body;

      // 获取流式响应
      final streamedResponse = await _client.send(request);

      // 检查状态码
      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('API请求失败: ${streamedResponse.statusCode}, $errorBody');
      }

      // 处理SSE流
      yield* _handleSSEStream(streamedResponse.stream);

    } on TimeoutException {
      throw Exception('请求超时，请检查网络连接');
    } catch (e) {
      debugPrint('❌ [DifyService] 请求失败: $e');
      rethrow;
    }
  }

  /// 处理SSE流
  Stream<String> _handleSSEStream(http.ByteStream stream) async* {
    // 将字节流转换为字符串流
    final stringStream = stream
        .transform(utf8.decoder)
        .transform(const LineSplitter());

    await for (final line in stringStream) {
      if (line.isEmpty) continue;

      debugPrint('📨 [DifyService] 收到数据: $line');

      // SSE格式: data: {...}
      if (line.startsWith('data: ')) {
        final data = line.substring(6); // 移除 "data: " 前缀

        try {
          final json = jsonDecode(data) as Map<String, dynamic>;

          // 🔍 详细日志：输出完整的 JSON 结构
          debugPrint('🔍 [DifyService] JSON结构: ${json.keys.toList()}');
          debugPrint('🔍 [DifyService] event类型: ${json['event']}');
          debugPrint('🔍 [DifyService] 完整数据: $json');

          // 处理不同类型的事件
          final eventType = json['event'] as String?;

          if (eventType == 'workflow_finished') {
            // 工作流完成
            debugPrint('✅ [DifyService] 工作流完成');
            break;
          } else if (eventType == 'message' || eventType == 'text_chunk') {
            // ✅ 支持 message 和 text_chunk 两种事件类型
            final text = json['data']['text'] as String?;
            debugPrint('✉️ [DifyService] 提取到文本 ($eventType): "$text"');
            if (text != null) {
              yield text;
            }
          } else if (eventType == 'error') {
            // 错误消息
            final errorMessage = json['message'] as String?;
            throw Exception('Dify错误: $errorMessage');
          } else if (eventType == 'workflow_started') {
            // 工作流开始，忽略
            debugPrint('▶️ [DifyService] 工作流开始');
            continue;
          } else if (eventType == 'node_started' || eventType == 'node_finished') {
            // 节点事件，忽略
            debugPrint('🔧 [DifyService] 节点事件: $eventType');
            continue;
          } else {
            // ⚠️ 未知事件类型
            debugPrint('⚠️ [DifyService] 未知事件类型: $eventType');
            debugPrint('⚠️ [DifyService] 尝试查找文本字段...');

            // 尝试查找其他可能的文本字段
            if (json['text'] != null) {
              final text = json['text'] as String;
              debugPrint('✅ [DifyService] 从根节点找到文本: "$text"');
              yield text;
            } else if (json['output'] != null) {
              debugPrint('✅ [DifyService] 找到output字段: ${json['output']}');
              // 处理 output 字段
              final output = json['output'];
              if (output is String) {
                yield output;
              } else if (output is Map && output['text'] != null) {
                yield output['text'] as String;
              }
            }
          }
        } catch (e) {
          debugPrint('⚠️ [DifyService] 解析SSE数据失败: $e');
          debugPrint('⚠️ [DifyService] 原始数据: $data');
        }
      }
    }
  }

  /// 关闭客户端
  void close() {
    _client.close();
  }
}
