import 'dart:convert';
import 'dart:math';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/call_state.dart';
import '../auth/ws_service.dart';
import '../auth/ice_service.dart';

class CallService {
  static CallState? current;

  /// UI 回调
  static Function(Map msg)? onIncoming;
  static Function(Map msg)? onPending;
  static Function(Map msg)? onAccepted;
  static Function(Map msg)? onConnected;
  static Function(Map msg)? onHangup;
  static Function(Map msg)? onTimeout;
  static Function(Map msg)? onError;

  /// ================= 发起通话 =================
  static Future<CallState> startCall({
    required int selfId,
    required int calleeId,
  }) async {
    final pc = await IceService.createPeerConnection();
    final stream = await IceService.openUserMedia();

    for (final track in stream.getTracks()) {
      pc.addTrack(track, stream);
    }

    final offer = await pc.createOffer();
    await pc.setLocalDescription(offer);

    final callId = _genCallId();

    current = CallState(callId: callId, selfId: selfId, peerId: calleeId)
      ..pc = pc
      ..localStream = stream
      ..status = CallStatus.calling;

    pc.onIceCandidate = (c) {
      if (c.candidate == null) return;
      WsService.send({
        "type": "ice-candidate",
        "callId": callId,
        "targetId": calleeId,
        "candidate": {
          "candidate": c.candidate,
          "sdpMid": c.sdpMid,
          "sdpMLineIndex": c.sdpMLineIndex,
        },
      });
    };

    pc.onTrack = (e) {
      current?.remoteStream ??= e.streams.first;
    };

    WsService.send({
      "type": "call-request",
      "calleeId": calleeId,
      "sdp": offer.sdp,
      "callId": callId,
    });

    return current!;
  }

  /// ================= 接听 =================
  static Future<void> acceptCall({
    required CallState call,
    required String remoteSdp,
  }) async {
    await call.pc!.setRemoteDescription(
      RTCSessionDescription(remoteSdp, "offer"),
    );

    final answer = await call.pc!.createAnswer();
    await call.pc!.setLocalDescription(answer);

    WsService.send({
      "type": "call-accept",
      "callId": call.callId,
      "sdp": answer.sdp,
    });
  }

  /// ================= 挂断 =================
  static void hangup({String reason = "用户主动挂断"}) {
    if (current == null) return;

    WsService.send({
      "type": "call-hangup",
      "callId": current!.callId,
      "reason": reason,
    });

    current!.close();
    current = null;
  }

  /// ================= 信令入口 =================
  static void handleMessage(String raw) {
    final msg = jsonDecode(raw);
    final type = msg['type'];

    switch (type) {
      case 'call-incoming':
        onIncoming?.call(msg);
        break;

      case 'call-pending':
        onPending?.call(msg);
        break;

      case 'call-accepted':
        onAccepted?.call(msg);
        break;

      case 'call-connected':
        onConnected?.call(msg);
        break;

      case 'call-hangup':
        onHangup?.call(msg);
        current?.close();
        current = null;
        break;

      case 'call-timeout':
        onTimeout?.call(msg);
        current?.close();
        current = null;
        break;

      case 'call-error':
        onError?.call(msg);
        break;

      case 'ice-candidate':
        current?.addRemoteIce(msg['candidate']);
        break;
    }
  }

  static String _genCallId() {
    return 'call_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(999999)}';
  }
}
