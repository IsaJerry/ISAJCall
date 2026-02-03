import 'package:flutter_webrtc/flutter_webrtc.dart';

/// 通话生命周期状态
enum CallStatus {
  idle,
  calling, // 已发起，等待对方
  ringing, // 来电中
  connected, // 已接通
  ended,
}

class CallState {
  final String callId;
  final int selfId;
  final int peerId;

  RTCPeerConnection? pc;
  MediaStream? localStream;
  MediaStream? remoteStream;

  CallStatus status = CallStatus.idle;
  DateTime? startTime;

  CallState({required this.callId, required this.selfId, required this.peerId});

  /// 添加远端 ICE
  Future<void> addRemoteIce(Map<String, dynamic> c) async {
    if (pc == null) return;
    await pc!.addCandidate(
      RTCIceCandidate(c['candidate'], c['sdpMid'], c['sdpMLineIndex']),
    );
  }

  /// 统一释放资源
  Future<void> close() async {
    try {
      await pc?.close();
      await localStream?.dispose();
      await remoteStream?.dispose();
    } catch (_) {}
    status = CallStatus.ended;
  }
}
