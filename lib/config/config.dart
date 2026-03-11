import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static const String baseUrl = "https://isajcall.159357.best";

  static const String wsUrl = "wss://isajcall.159357.best";

  static const String _defaultTurnUrl = "turn:38.165.17.30:3478";
  static const String _defaultTurnUsername = "isaj";
  static const String _defaultTurnPassword = "isajerry";

  static const String loginApi = "/api/login";
  static const String registerApi = "/api/register";
  static const String changePasswordApi = "/api/change-password";

  // SharedPreferences keys
  static const String spToken = "token";
  static const String spUserId = "userId";
  static const String spUsername = "username";

  static const String spBaseUrl = "config_base_url";
  static const String spWsUrl = "config_ws_url";
  static const String spTurnUrl = "config_turn_url";
  static const String spTurnUser = "config_turn_user";
  static const String spTurnPass = "config_turn_pass";

  // ===== Friends APIs =====
  static const String searchUserApi = "/api/search";
  static const String contactRequestApi = "/api/contact-request";
  static const String contactRequestsApi = "/api/contact-requests";
  static const String contactAcceptApi = "/api/contact-accept";
  static const String contactRejectApi = "/api/contact-reject";
  static const String userOnlineApi = "/api/user-online";
  // 获取好友列表
  static const String contactsApi = "/api/contacts";
  // 通话记录模块
  static const String callLogsApi = "/api/call-logs";

  /// ========= 消息 =========
  static const String sendMessageApi = "/api/messages";
  static const String chatHistoryApi = "/api/chat-history";
  static const String unreadMessageApi = "/api/unread-messages";
  static const String messageReadApi = "/api/messages/read";

  // ========= 动态读取 =========

  static Future<String> setbaseUrl() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(spBaseUrl) ?? baseUrl;
  }

  static Future<String> setwsUrl() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(spWsUrl) ?? wsUrl;
  }

  static Future<String> turnUrl() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(spTurnUrl) ?? _defaultTurnUrl;
  }

  static Future<String> turnUsername() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(spTurnUser) ?? _defaultTurnUsername;
  }

  static Future<String> turnPassword() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(spTurnPass) ?? _defaultTurnPassword;
  }
}

/// ========= WebSocket 消息类型 =========
class WSMessageType {
  static const String callRequest = "call-request";
  static const String callIncoming = "call-incoming";
  static const String callPending = "call-pending";
  static const String callAccept = "call-accept";
  static const String callAccepted = "call-accepted";
  static const String callConnected = "call-connected";
  static const String callHangup = "call-hangup";
  static const String callHangupConfirm = "call-hangup-confirm";
  static const String callTimeout = "call-timeout";
  static const String iceCandidate = "ice-candidate";
  static const String callError = "call-error";

  static const String callCancel = "call-cancel";
  static const String callReject = "call-reject";
}
