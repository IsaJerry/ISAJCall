import 'dart:async';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/call_state.dart';
import '../auth/ice_service.dart';
import '../config/config.dart';
import 'ws_service.dart';

class CallService {
  static CallState? current;

  static Timer? _callTimeoutTimer;

  /// UI 回调
  static void Function(Map msg)? onIncoming;
  static void Function(Map msg)? onAccepted;
  static void Function(Map msg)? onConnected;
  static void Function(Map msg)? onHangup;
  static void Function(Map msg)? onError;
  static void Function(Map msg)? onTimeout;

  /* ------------------------------------------------------------------ */
  /*                         内部统一初始化                               */
  /* ------------------------------------------------------------------ */

  static Future<void> _initPeerAndMedia(CallState call) async {
    call.pc ??= await _createPeerConnection();
    call.localStream ??= await _openUserMedia();
    call.remoteStream ??= await createLocalMediaStream('remote');

    for (final track in call.localStream!.getTracks()) {
      call.pc!.addTrack(track, call.localStream!);
    }

    call.pc!.onConnectionState = (state) {
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        call.status = CallStatus.connected;
        onConnected?.call({});
      }
    };

    call.pc!.onIceCandidate = (c) {
      if (c.candidate == null) return;
      WSService.send({
        "type": "ice-candidate",
        "callId": call.callId,
        "targetId": call.peerId,
        "candidate": {
          "candidate": c.candidate,
          "sdpMid": c.sdpMid,
          "sdpMLineIndex": c.sdpMLineIndex,
        },
      });
    };
  }

  /* ------------------------------------------------------------------ */
  /*                            发起通话                                  */
  /* ------------------------------------------------------------------ */

  static Future<CallState> startCall({
    required int selfId,
    required int peerId,
  }) async {
    /// ICE 自检（仅主叫需要）
    final iceResult = await IceTestService.testIce();
    if (iceResult.status != IceTestStatus.success) {
      throw Exception(iceResult.message);
    }

    final call = CallState(
      callId: 'call_${DateTime.now().millisecondsSinceEpoch}',
      selfId: selfId,
      peerId: peerId,
    );

    current = call;
    call.status = CallStatus.calling;

    _startCallTimeout();

    await _initPeerAndMedia(call);

    final offer = await call.pc!.createOffer();
    await call.pc!.setLocalDescription(offer);

    WSService.send({
      "type": "call-request",
      "callId": call.callId,
      "calleeId": peerId,
      "sdp": offer.sdp,
    });

    return call;
  }

  static void _startCallTimeout({
    Duration timeout = const Duration(seconds: 30),
  }) {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = Timer(timeout, () {
      if (current != null &&
          current!.status != CallStatus.connected &&
          current!.status != CallStatus.ended) {
        onTimeout?.call({});
        endCall();
      }
    });
  }

  /* ------------------------------------------------------------------ */
  /*                          来电预处理（不接听）                         */
  /* ------------------------------------------------------------------ */

  static Future<CallState> prepareIncomingCall({
    required int selfId,
    required Map incoming,
  }) async {
    final call = CallState(
      callId: incoming["callId"],
      selfId: selfId,
      peerId: int.parse(incoming["from"].toString()),
    );

    current = call;
    call.status = CallStatus.ringing;

    await _initPeerAndMedia(call);

    /// 只 set offer，不 answer
    await call.pc!.setRemoteDescription(
      RTCSessionDescription(incoming["sdp"], "offer"),
    );

    return call;
  }

  /* ------------------------------------------------------------------ */
  /*                             接听通话                                  */
  /* ------------------------------------------------------------------ */

  static Future<CallState> acceptCall({
    required Map msg,
    required int selfId,
  }) async {
    final call =
        current ??
        CallState(callId: msg['callId'], selfId: selfId, peerId: msg['from']);

    current = call;
    call.status = CallStatus.connected;

    _callTimeoutTimer?.cancel();

    await _initPeerAndMedia(call);

    /// 防止未经过 prepareIncomingCall 的情况
    // if (call.pc!.remoteDescription == null) {
    //   await call.pc!.setRemoteDescription(
    //     RTCSessionDescription(msg['sdp'], 'offer'),
    //   );
    // }

    final answer = await call.pc!.createAnswer();
    await call.pc!.setLocalDescription(answer);

    WSService.send({
      "type": "call-accept",
      "callId": call.callId,
      "sdp": answer.sdp,
      "targetId": call.peerId,
    });

    return call;
  }

  /* ------------------------------------------------------------------ */
  /*                           信令处理入口                                 */
  /* ------------------------------------------------------------------ */

  static void handleSignal(Map msg) {
    final type = msg['type'];

    switch (type) {
      case 'call-request':
      case 'call-incoming':
        onIncoming?.call(msg);
        break;

      case 'call-accepted':
        onAccepted?.call(msg);
        break;

      case 'call-connected':
        onConnected?.call(msg);
        break;

      case 'ice-candidate':
        current?.addRemoteIce(msg['candidate']);
        break;

      case 'call-timeout':
        onTimeout?.call(msg);
        endCall();
        break;

      case 'call-hangup':
        onHangup?.call(msg);
        endCall();
        break;

      case 'call-error':
        onError?.call(msg);
        endCall();
        break;
    }
  }

  /* ------------------------------------------------------------------ */
  /*                             挂断                                     */
  /* ------------------------------------------------------------------ */

  static void hangup() {
    if (current == null) return;
    WSService.send({
      "type": "call-hangup",
      "callId": current!.callId,
      "targetId": current!.peerId,
    });
    endCall();
  }

  static Future<void> endCall() async {
    await current?.close();
    current = null;
  }

  /* ------------------------------------------------------------------ */
  /*                          工具方法                                     */
  /* ------------------------------------------------------------------ */

  static Future<RTCPeerConnection> _createPeerConnection() async {
    final turnUrl = await Config.turnUrl();
    final turnUser = await Config.turnUsername();
    final turnPass = await Config.turnPassword();

    return await createPeerConnection({
      "iceServers": [
        {"urls": turnUrl, "username": turnUser, "credential": turnPass},
      ],
      "iceTransportPolicy": "all",
    });
  }

  static Future<MediaStream> _openUserMedia() async {
    return await navigator.mediaDevices.getUserMedia({
      "audio": true,
      "video": {"facingMode": "user"},
    });
  }

  static void cancelCallTimeout() {
    _callTimeoutTimer?.cancel();
    _callTimeoutTimer = null;
  }
}
