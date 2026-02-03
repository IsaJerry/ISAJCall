import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../config/config.dart';

/// ICE 测试结果
enum IceTestStatus { idle, testing, success, failed }

class IceTestResult {
  final IceTestStatus status;
  final String message;
  final bool hasCandidate;

  const IceTestResult({
    required this.status,
    required this.message,
    this.hasCandidate = false,
  });
}

class IceTestService {
  IceTestService._(); // 禁止实例化

  /// ========= 对外唯一方法 =========
  static Future<IceTestResult> testIce() async {
    RTCPeerConnection? pc;
    bool gotCandidate = false;

    try {
      // 先 await 配置（这是关键）
      final turnUrl = await Config.turnUrl();
      final turnUser = await Config.turnUsername();
      final turnPass = await Config.turnPassword();

      pc = await createPeerConnection({
        "iceServers": [
          {"urls": turnUrl, "username": turnUser, "credential": turnPass},
        ],
        "iceTransportPolicy": "all",
      });

      pc.onIceCandidate = (RTCIceCandidate? candidate) {
        if (candidate != null) {
          gotCandidate = true;
          debugPrint("ICE candidate: ${candidate.candidate}");
        }
      };

      pc.onIceConnectionState = (state) {
        debugPrint("ICE state => $state");
      };

      final offer = await pc.createOffer();
      await pc.setLocalDescription(offer);

      await Future.delayed(const Duration(seconds: 5));

      if (gotCandidate) {
        return const IceTestResult(
          status: IceTestStatus.success,
          message: "ICE / TURN 连通成功",
          hasCandidate: true,
        );
      } else {
        return const IceTestResult(
          status: IceTestStatus.failed,
          message: "ICE 测试失败：未获取候选（TURN 不可用）",
        );
      }
    } catch (e) {
      return IceTestResult(
        status: IceTestStatus.failed,
        message: "ICE 测试异常：$e",
      );
    } finally {
      await pc?.close();
    }
  }
}
