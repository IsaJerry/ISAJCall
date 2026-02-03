import 'package:flutter/material.dart';
import '../auth/auth_service.dart';
import 'login_page.dart';

class ChangePasswordPage extends StatefulWidget {
  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final oldCtrl = TextEditingController();
  final newCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  bool loading = false;

  submit() async {
    if (newCtrl.text != confirmCtrl.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("两次输入的新密码不一致")));
      return;
    }

    setState(() => loading = true);

    final err = await AuthService.changePassword(oldCtrl.text, newCtrl.text);

    setState(() => loading = false);

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    // 修改成功 → 强制退出重新登录
    await AuthService.logout();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部返回
            Container(
              height: 50,
              alignment: Alignment.centerLeft,
              child: IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
            ),

            // 中部内容
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: oldCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "原密码"),
                    ),
                    TextField(
                      controller: newCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "新密码"),
                    ),
                    TextField(
                      controller: confirmCtrl,
                      obscureText: true,
                      decoration: InputDecoration(labelText: "确认新密码"),
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: loading ? null : submit,
                      child: Text("确认修改"),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
