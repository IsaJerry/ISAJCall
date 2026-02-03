import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/config.dart';
import 'auth_service.dart';

class FriendsService {
  /// 搜索用户（模糊搜索用户名，排除自己由后端处理）
  static Future<List> searchUsers(String username) async {
    final headers = await AuthService.authHeaders();

    final uri = Uri.parse(
      Config.baseUrl +
          Config.searchUserApi +
          "?username=${Uri.encodeComponent(username)}",
    );

    final res = await http.get(uri, headers: headers);

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  /// 发送好友申请
  static Future<String?> sendRequest(int userId) async {
    final res = await http.post(
      Uri.parse(Config.baseUrl + Config.contactRequestApi),
      headers: await AuthService.authHeaders(),
      body: jsonEncode({"userId": userId}),
    );

    if (res.statusCode == 200) {
      return null;
    }

    return jsonDecode(res.body)["error"];
  }

  /// 获取收到的好友申请
  static Future<List> getRequests() async {
    final res = await http.get(
      Uri.parse(Config.baseUrl + Config.contactRequestsApi),
      headers: await AuthService.authHeaders(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }

  /// 同意好友申请
  static Future<bool> accept(int requestId) async {
    final res = await http.post(
      Uri.parse(Config.baseUrl + Config.contactAcceptApi),
      headers: await AuthService.authHeaders(),
      body: jsonEncode({"requestId": requestId}),
    );

    return res.statusCode == 200;
  }

  /// 拒绝好友申请
  static Future<String?> reject(int requestId) async {
    final res = await http.post(
      Uri.parse(Config.baseUrl + Config.contactRejectApi),
      headers: await AuthService.authHeaders(),
      body: jsonEncode({"requestId": requestId}),
    );

    if (res.statusCode == 200) {
      return null; // 成功
    }

    // 403 或 400 都按后端返回 error 处理
    return jsonDecode(res.body)["error"];
  }

  /// 获取已通过的联系人列表
  static Future<List> getContacts() async {
    final res = await http.get(
      Uri.parse(Config.baseUrl + Config.contactsApi),
      headers: await AuthService.authHeaders(),
    );

    if (res.statusCode == 200) {
      return jsonDecode(res.body);
    }
    return [];
  }
}
