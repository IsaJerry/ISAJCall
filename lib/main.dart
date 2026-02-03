import 'package:flutter/material.dart';
import 'auth/auth_service.dart';
import 'auth/ws_service.dart';
import 'auth/call_service.dart';
import 'pages/login_page.dart';
import 'pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  late final Future<bool> _startupFuture;

  @override
  void initState() {
    super.initState();
    _startupFuture = _bootstrap();
  }

  Future<bool> _bootstrap() async {
    final loggedIn = await AuthService.isLoggedIn();
    if (loggedIn) {
      final userId = await AuthService.getCurrentUserId();
      if (userId != null) {
        // 应用重启后的“自动登录”场景：在进入 HomePage 前恢复 WS/信令监听
        CallService.init(currentUserId: userId);
        await WSService.connect();
      }
    }
    return loggedIn;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ISAJ',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      builder: (context, child) {
        // 在应用最外层包裹 Overlay
        return Stack(
          children: [
            child!,
            // CallAcceptPage 浮窗将在这里动态插入
          ],
        );
      },
      home: FutureBuilder<bool>(
        future: _startupFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          final home = snapshot.data! ? HomePage() : LoginPage();

          // 监听 CallService 全局来电
          // CallService.state.stream.listen((_) {
          //   final state = CallService.state;
          //   if (state.isIncoming) {
          //     final callerId = state.remoteUserId!;
          //     final callId = state.callId!;
          //     final callerInfo = {
          //       "name": "用户$callerId",
          //       "avatar": "", // 可从好友列表获取头像
          //     };

          //     // 弹出浮窗
          //     navigatorKey.currentState?.overlay?.insert(
          //       OverlayEntry(
          //         builder: (_) => CallAcceptPage(
          //           callerId: callerId,
          //           callId: callId,
          //           callerInfo: callerInfo,
          //         ),
          //       ),
          //     );
          //   }
          // });

          return home;
        },
      ),
    );
  }
}
