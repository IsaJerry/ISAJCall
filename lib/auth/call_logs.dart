import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import 'auth_service.dart';

class CallLogsService {
  /// 新增通话记录
  static Future<String?> addCallLog({
    required int callerId,
    required int calleeId,
    required String startTime,
    required String endTime,
    required String status,
  }) async {
    final res = await http.post(
      Uri.parse(Config.baseUrl + Config.callLogsApi),
      headers: await AuthService.authHeaders(),
      body: jsonEncode({
        "caller_id": callerId,
        "callee_id": calleeId,
        "start_time": startTime,
        "end_time": endTime,
        "status": status,
      }),
    );

    if (res.statusCode == 200) return null;
    return jsonDecode(res.body)["error"];
  }

  /// 获取通话记录
  static Future<List> getCallLogs({
    required int userId,
    required int contactId,
  }) async {
    final uri = Uri.parse(
      Config.baseUrl +
          Config.callLogsApi +
          "?userId=$userId&contactId=$contactId",
    );

    final res = await http.get(uri, headers: await AuthService.authHeaders());

    if (res.statusCode == 200) return jsonDecode(res.body);
    return [];
  }

  /// ===== 新增：发送消息 =====
  static Future<String?> sendMessage({
    required int recipientId,
    required String content,
  }) async {
    final res = await http.post(
      Uri.parse(Config.baseUrl + Config.sendMessageApi),
      headers: await AuthService.authHeaders(),
      body: jsonEncode({"recipientId": recipientId, "content": content}),
    );

    if (res.statusCode == 200) {
      return null;
    }
    return jsonDecode(res.body)["error"];
  }

  /// ===== 新增：聊天 + 通话合并记录 =====
  static Future<List> getChatHistory(int contactId) async {
    final res = await http.get(
      Uri.parse(
        "${Config.baseUrl}${Config.chatHistoryApi}?contactId=$contactId",
      ),
      headers: await AuthService.authHeaders(),
    );

    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return body["data"] ?? [];
    }

    return [];
  }

  /// ===== 新增：未读消息 =====
  static Future<Map<String, dynamic>?> getUnreadMessages() async {
    final res = await http.get(
      Uri.parse(Config.baseUrl + Config.unreadMessageApi),
      headers: await AuthService.authHeaders(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return null;
  }

  /// ===== 新增：标记已读 =====
  static Future<void> markMessageRead(int messageId) async {
    await http.post(
      Uri.parse(Config.baseUrl + Config.messageReadApi),
      headers: await AuthService.authHeaders(),
      body: jsonEncode({"messageId": messageId}),
    );
  }
}
