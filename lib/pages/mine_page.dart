import 'package:flutter/material.dart';
import 'package:isajapp/pages/config_page.dart';
import '../auth/auth_service.dart';
import '../auth/ws_service.dart';
import '../auth/call_service.dart';
import 'login_page.dart';
import 'change_password.dart';

class MinePage extends StatefulWidget {
  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  String username = "";
  bool wsConnected = false;
  late final void Function(bool) _wsStatusListener;

  @override
  void initState() {
    super.initState();
    load();

    // 1. 先获取当前 WS 状态
    wsConnected = WSService.connected;
    // 绑定 WS 状态监听（避免覆盖全局单回调）
    _wsStatusListener = (connected) {
      if (!mounted) return;
      setState(() => wsConnected = connected);
    };
    WSService.addStatusListener(_wsStatusListener);

    // 注意：WS 仅在登录成功时连接，MinePage 不主动连接
  }

  @override
  void dispose() {
    WSService.removeStatusListener(_wsStatusListener);
    super.dispose();
    // 页面销毁不主动断开，退出登录或退出应用时再调用 WSService.disconnect()
  }

  load() async {
    final name = await AuthService.getUsername();
    if (!mounted) return; // 页面已销毁，直接返回
    setState(() => username = name ?? "UnLogin");
  }

  logout() async {
    await AuthService.logout();
    //CallService.dispose();
    WSService.disconnect();
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = wsConnected ? Colors.green : Colors.grey;
    return Scaffold(
      appBar: AppBar(title: Text("我的")),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "用户名：$username",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: statusColor, // 连接成功/未连接
              ),
            ),
            const SizedBox(height: 6),
            Text(
              wsConnected ? "WebSocket：已连接" : "WebSocket：未连接",
              style: TextStyle(fontSize: 12, color: statusColor),
            ),
            SizedBox(height: 20),

            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ChangePasswordPage()),
                );
              },
              child: Text("修改密码"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ConfigPage()),
                );
              },
              child: Text("设置和测试"),
            ),

            SizedBox(height: 10),

            ElevatedButton(onPressed: logout, child: Text("退出登录")),
          ],
        ),
      ),
    );
  }
}
