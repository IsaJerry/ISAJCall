import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/config.dart';

class AuthService {
  /// 注册
  static Future<String?> register(String username, String password) async {
    final res = await http.post(
      Uri.parse(Config.baseUrl + Config.registerApi),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (res.statusCode == 200) {
      return null; // 成功
    } else {
      return jsonDecode(res.body)["error"];
    }
  }

  /// 登录
  static Future<String?> login(String username, String password) async {
    final res = await http.post(
      Uri.parse(Config.baseUrl + Config.loginApi),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final sp = await SharedPreferences.getInstance();
      await sp.setString(Config.spToken, data["token"]);
      await sp.setInt(Config.spUserId, data["userId"]);
      await sp.setString(Config.spUsername, username);
      return null;
    } else {
      return jsonDecode(res.body)["error"];
    }
  }

  /// 是否已登录
  static Future<bool> isLoggedIn() async {
    final sp = await SharedPreferences.getInstance();
    return sp.containsKey(Config.spToken);
  }

  /// 获取用户名
  static Future<String?> getUsername() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(Config.spUsername);
  }

  static Future<int?> getCurrentUserId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getInt(Config.spUserId);
  }

  /// 获取 JWT
  static Future<String?> getToken() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(Config.spToken);
  }

  /// 退出登录
  static Future<void> logout() async {
    final sp = await SharedPreferences.getInstance();
    await sp.clear();
  }

  /// 修改密码
  static Future<String?> changePassword(
    String oldPassword,
    String newPassword,
  ) async {
    final res = await http.post(
      Uri.parse(Config.baseUrl + Config.changePasswordApi),
      headers: await authHeaders(),
      body: jsonEncode({
        "oldPassword": oldPassword,
        "newPassword": newPassword,
      }),
    );

    if (res.statusCode == 200) {
      return null; // 成功
    }

    return jsonDecode(res.body)["error"];
  }

  static Future<Map<String, String>> authHeaders() async {
    final sp = await SharedPreferences.getInstance();
    final token = sp.getString(Config.spToken);

    return {
      "Content-Type": "application/json",
      "Authorization": "Bearer $token",
    };
  }
}
