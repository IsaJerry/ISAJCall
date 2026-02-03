import 'package:flutter/services.dart';

class NativeCall {
  static const MethodChannel _channel = MethodChannel('call/native');

  /// 进入画中画（Android）
  static Future<void> enterPictureInPicture() async {
    try {
      await _channel.invokeMethod('enter_pip');
    } catch (e) {
      // 先不抛异常，避免影响通话流程
      print('enter_pip failed: $e');
    }
  }

  /// 预留：退出画中画
  static Future<void> exitPictureInPicture() async {
    try {
      await _channel.invokeMethod('exit_pip');
    } catch (_) {}
  }

  /// 预留：是否支持 PiP
  static Future<bool> isPiPSupported() async {
    try {
      final res = await _channel.invokeMethod<bool>('pip_supported');
      return res == true;
    } catch (_) {
      return false;
    }
  }
}
