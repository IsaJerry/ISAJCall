import 'package:flutter/material.dart';
import 'package:isajapp/pages/config_page.dart';
import '../auth/auth_service.dart';
import '../auth/ws_service.dart';
import '../auth/call_service.dart';
import 'home_page.dart';

class LoginPage extends StatefulWidget {
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  bool isRegister = false;
  bool loading = false;

  submit() async {
    setState(() => loading = true);

    String? error;
    if (isRegister) {
      error = await AuthService.register(usernameCtrl.text, passwordCtrl.text);
      if (error == null) {
        usernameCtrl.clear();
        passwordCtrl.clear();
        setState(() => isRegister = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("注册成功，请登录")));
      }
    } else {
      error = await AuthService.login(usernameCtrl.text, passwordCtrl.text);
      if (error == null) {
        // 登录成功：只在这里连接 WS（全项目唯一连接点）
        final userId = await AuthService.getCurrentUserId();
        if (userId != null) {
          // 先绑定消息分发，再连 WS，避免竞态漏消息
          CallService.init(currentUserId: userId);
          await WSService.connect();
        }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => HomePage()),
        );
      }
    }

    if (error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isRegister ? "注册" : "登录")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: usernameCtrl,
              decoration: InputDecoration(labelText: "用户名"),
            ),
            TextField(
              controller: passwordCtrl,
              decoration: InputDecoration(labelText: "密码"),
              obscureText: true,
            ),
            SizedBox(height: 20),
            GestureDetector(
              onLongPress: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ConfigPage()),
                );
              },
              child: ElevatedButton(
                onPressed: loading ? null : submit,
                child: Text(isRegister ? "注册" : "登录"),
              ),
            ),

            TextButton(
              onPressed: () {
                setState(() => isRegister = !isRegister);
              },
              child: Text(isRegister ? "已有账号？去登录" : "没有账号？去注册"),
            ),
          ],
        ),
      ),
    );
  }
}
