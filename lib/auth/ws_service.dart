import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'auth_service.dart';
import '../config/config.dart';

typedef OnMessageCallback = void Function(Map data);
typedef OnStatusChange = void Function(bool connected);
typedef OnRealtimeMessage = void Function(Map message);

typedef OnWsEvent = void Function(Map data);

class WSService {
  static WebSocketChannel? _channel;
  static bool _connected = false;

  static OnMessageCallback? onMessage;
  // 兼容旧代码：仍保留单回调，但推荐用 addStatusListener()
  static OnStatusChange? onStatusChange;

  // 保存好友在线状态 {userId: true/false}
  static Map<int, bool> friendsOnline = {};

  static final List<OnWsEvent> _eventListeners = [];
  static final List<OnStatusChange> _statusListeners = [];

  static void addEventListener(OnWsEvent cb) => _eventListeners.add(cb);
  static void removeEventListener(OnWsEvent cb) => _eventListeners.remove(cb);

  static void addStatusListener(OnStatusChange cb) => _statusListeners.add(cb);
  static void removeStatusListener(OnStatusChange cb) =>
      _statusListeners.remove(cb);

  static void _notifyStatus(bool connected) {
    onStatusChange?.call(connected);
    for (final cb in List<OnStatusChange>.from(_statusListeners)) {
      cb(connected);
    }
  }

  /// 建立 WebSocket 连接
  static Future<void> connect() async {
    if (_channel != null) return; // 已经连接

    final token = await AuthService.getToken();
    if (token == null) {
      _connected = false;
      _notifyStatus(false);
      return;
    }

    try {
      // 使用动态配置（ConfigPage 可修改），而不是硬编码常量
      final wsBase = await Config.setwsUrl();
      final baseUri = Uri.parse(wsBase);
      final qp = <String, String>{...baseUri.queryParameters, "token": token};
      final wsUri = baseUri.replace(queryParameters: qp);

      _channel = WebSocketChannel.connect(wsUri);

      _connected = true;
      _notifyStatus(true);

      // 监听服务器消息
      _channel!.stream.listen(
        (message) {
          final data = jsonDecode(message);

          print("[WS Receive] ${data["type"]}");

          // 处理好友在线状态推送
          if (data["type"] == "online-status" && data["targetUserId"] != null) {
            final id = int.parse(data["targetUserId"].toString());
            final isOnline = data["isOnline"] == true;
            friendsOnline[id] = isOnline;
            onMessage?.call(data); // 通知页面刷新 UI
          } else {
            // 普通信令消息
            onMessage?.call(data);
          }

          // 调用页面所有监听
          for (final cb in _eventListeners) {
            cb(data);
          }
        },
        onDone: () {
          _connected = false;
          _notifyStatus(false);
          _channel = null;
        },
        onError: (error) {
          _connected = false;
          _notifyStatus(false);
          _channel = null;
        },
      );
    } catch (e) {
      _connected = false;
      _notifyStatus(false);
      _channel = null;
    }
  }

  /// 退出 WebSocket
  static void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _connected = false;
    _notifyStatus(false);
  }

  /// 发送信令消息
  static void send(Map data) {
    if (_connected && _channel != null) {
      _channel!.sink.add(jsonEncode(data));
      print(jsonEncode(data));
    }
  }

  /// 获取当前连接状态
  static bool get connected => _connected;

  /// 查询目标用户在线状态（HTTP GET）
  static Future<bool?> queryOnline(int targetUserId) async {
    if (targetUserId <= 0) return null;

    final token = await AuthService.getToken();
    if (token == null) return null;

    final uri = Uri.parse(
      "${Config.baseUrl}${Config.userOnlineApi}?targetUserId=$targetUserId",
    );
    final res = await http.get(uri, headers: await AuthService.authHeaders());

    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final online = data["isOnline"] == true;
      friendsOnline[targetUserId] = online;
      return online;
    }
    return null;
  }
}
