import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/config.dart';
import '../auth/ws_service.dart';
import '../auth/ice_service.dart';

class ConfigPage extends StatefulWidget {
  const ConfigPage({super.key});

  @override
  State<ConfigPage> createState() => _ConfigPageState();
}

class _ConfigPageState extends State<ConfigPage> {
  final baseCtrl = TextEditingController();
  final wsCtrl = TextEditingController();
  final turnCtrl = TextEditingController();
  final turnUserCtrl = TextEditingController();
  final turnPassCtrl = TextEditingController();

  String testResult = "";
  bool testingIce = false;

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  /// 加载本地配置
  Future<void> _loadConfig() async {
    baseCtrl.text = await Config.setbaseUrl();
    wsCtrl.text = await Config.setwsUrl();
    turnCtrl.text = await Config.turnUrl();
    turnUserCtrl.text = await Config.turnUsername();
    turnPassCtrl.text = await Config.turnPassword();
    if (mounted) setState(() {});
  }

  /// 保存配置
  Future<void> _saveConfig() async {
    final sp = await SharedPreferences.getInstance();

    await sp.setString(Config.spBaseUrl, baseCtrl.text.trim());
    await sp.setString(Config.spWsUrl, wsCtrl.text.trim());
    await sp.setString(Config.spTurnUrl, turnCtrl.text.trim());
    await sp.setString(Config.spTurnUser, turnUserCtrl.text.trim());
    await sp.setString(Config.spTurnPass, turnPassCtrl.text.trim());

    setState(() {
      testResult = "配置已保存 ✅";
    });
  }

  /// 测试 WebSocket 状态
  void _testWs() {
    setState(() {
      testResult = WSService.connected ? "WebSocket 连接成功 ✅" : "WebSocket 未连接 ❌";
    });
  }

  /// 测试 ICE / TURN
  Future<void> _testIce() async {
    if (testingIce) return;

    setState(() {
      testingIce = true;
      testResult = "正在测试 ICE / TURN 服务器...";
    });

    final result = await IceTestService.testIce();

    if (!mounted) return;

    setState(() {
      testingIce = false;
      testResult = result.message;
    });
  }

  Color _resultColor() {
    if (testResult.contains("成功")) return Colors.green;
    if (testResult.contains("失败") || testResult.contains("异常")) {
      return Colors.red;
    }
    return Colors.black87;
  }

  Widget _field(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("服务器设置与测试")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _field("Base URL", baseCtrl),
            _field("WebSocket URL", wsCtrl),
            _field("TURN URL", turnCtrl),
            _field("TURN 用户名", turnUserCtrl),
            _field("TURN 密码", turnPassCtrl),

            const SizedBox(height: 12),

            ElevatedButton(onPressed: _saveConfig, child: const Text("保存配置")),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: _testWs,
              child: const Text("测试 WebSocket 连接"),
            ),

            const SizedBox(height: 8),

            ElevatedButton(
              onPressed: testingIce ? null : _testIce,
              child: const Text("测试 ICE / TURN"),
            ),

            const SizedBox(height: 16),

            Text(
              testResult,
              style: TextStyle(color: _resultColor(), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
