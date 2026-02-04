import 'package:flutter_webrtc/flutter_webrtc.dart';

/// 通话生命周期
enum CallStatus { idle, calling, ringing, connected, ended }

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

  /// 统一释放
  Future<void> close() async {
    try {
      await pc?.close();
      await localStream?.dispose();
      await remoteStream?.dispose();
    } catch (_) {}
    status = CallStatus.ended;
  }
}
