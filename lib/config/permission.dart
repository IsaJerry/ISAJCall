import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionManager {
  PermissionManager._();

  /// ========================
  /// 检查是否已有通话所需权限
  /// ========================
  static Future<bool> hasCallPermissions() async {
    final mic = await Permission.microphone.status;
    final cam = await Permission.camera.status;

    return mic.isGranted && cam.isGranted;
  }

  /// ========================
  /// 申请通话权限（麦克风 + 摄像头）
  /// ========================
  static Future<bool> requestCallPermissions() async {
    final statuses = await [Permission.microphone, Permission.camera].request();

    return statuses[Permission.microphone]?.isGranted == true &&
        statuses[Permission.camera]?.isGranted == true;
  }

  /// ========================
  /// 确保权限可用（推荐 CallPage 用这个）
  /// ========================
  static Future<bool> ensureCallPermissions({BuildContext? context}) async {
    if (await hasCallPermissions()) return true;

    final granted = await requestCallPermissions();
    if (granted) return true;

    // 权限被永久拒绝
    if (context != null) {
      _showPermissionDialog(context);
    }

    return false;
  }

  /// ========================
  /// 引导用户去系统设置
  /// ========================
  static void _showPermissionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("需要权限"),
        content: const Text("通话需要摄像头和麦克风权限，请在系统设置中开启。"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("取消"),
          ),
          TextButton(
            onPressed: () {
              openAppSettings();
              Navigator.pop(context);
            },
            child: const Text("去设置"),
          ),
        ],
      ),
    );
  }
}
