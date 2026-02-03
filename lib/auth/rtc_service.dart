// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'call_service.dart';
// import '../config/config.dart';

// typedef OnRemoteStream = void Function(MediaStream stream);

// class RTCService {
//   RTCService._();
//   static final RTCService instance = RTCService._();

//   RTCPeerConnection? _pc;
//   MediaStream? _localStream;
//   MediaStream? _remoteStream;

//   String? _callId;
//   int? _targetId;

//   /// 被 CallPage 绑定的远端回调
//   OnRemoteStream? onRemoteStream;

//   MediaStream? get localStream => _localStream;
//   MediaStream? get remoteStream => _remoteStream;

//   /// ========================
//   /// 初始化 PeerConnection（主叫/被叫通用）
//   /// ========================
//   Future<void> initPeer({required String callId, required int targetId}) async {
//     // 先释放旧连接
//     await close();

//     _callId = callId;
//     _targetId = targetId;

//     final config = {
//       "iceServers": [
//         {"urls": "stun:stun.l.google.com:19302"},
//         {
//           "urls": await Config.turnUrl(),
//           "username": await Config.turnUsername(),
//           "credential": await Config.turnPassword(),
//         },
//       ],
//       "sdpSemantics": "unified-plan",
//     };

//     _pc = await createPeerConnection(config);

//     // 获取本地媒体流
//     _localStream = await navigator.mediaDevices.getUserMedia({
//       "audio": true,
//       "video": {"facingMode": "user"},
//     });

//     for (final track in _localStream!.getTracks()) {
//       await _pc!.addTrack(track, _localStream!);
//     }

//     _pc!.onIceCandidate = (candidate) {
//       if (_callId == null || _targetId == null || candidate == null) return;

//       CallService.sendIceCandidate(
//         callId: _callId!,
//         targetId: _targetId!,
//         candidate: {
//           "candidate": candidate.candidate,
//           "sdpMid": candidate.sdpMid,
//           "sdpMLineIndex": candidate.sdpMLineIndex,
//         },
//       );
//     };

//     _pc!.onIceConnectionState = (state) {
//       if (state == RTCIceConnectionState.RTCIceConnectionStateConnected ||
//           state == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
//         CallService.onRtcConnected();
//       }
//     };

//     _pc!.onTrack = (event) {
//       if (event.streams.isNotEmpty) {
//         _remoteStream = event.streams.first;
//         if (onRemoteStream != null) onRemoteStream!(_remoteStream!);
//       }
//     };
//   }

//   /// ========================
//   /// 主叫：创建 Offer
//   /// ========================
//   Future<String> createOffer({
//     required String callId,
//     required int calleeId,
//   }) async {
//     await initPeer(callId: callId, targetId: calleeId);
//     final offer = await _pc!.createOffer();
//     await _pc!.setLocalDescription(offer);
//     return offer.sdp!;
//   }

//   /// ========================
//   /// 被叫：创建 Answer
//   /// ========================
//   Future<String> createAnswer({
//     required String callId,
//     required int callerId,
//     required String offerSdp,
//   }) async {
//     await initPeer(callId: callId, targetId: callerId);
//     await _pc!.setRemoteDescription(RTCSessionDescription(offerSdp, 'offer'));
//     final answer = await _pc!.createAnswer();
//     await _pc!.setLocalDescription(answer);
//     return answer.sdp!;
//   }

//   /// ========================
//   /// 设置远端 Answer
//   /// ========================
//   Future<void> setRemoteAnswer(String sdp) async {
//     if (_pc == null) return;
//     await _pc!.setRemoteDescription(RTCSessionDescription(sdp, 'answer'));
//   }

//   /// ========================
//   /// 添加 ICE candidate
//   /// ========================
//   Future<void> addIceCandidate(Map data) async {
//     if (_pc == null) return;

//     final candidate = RTCIceCandidate(
//       data["candidate"],
//       data["sdpMid"],
//       data["sdpMLineIndex"],
//     );

//     await _pc!.addCandidate(candidate);
//   }

//   /// ========================
//   /// 释放资源
//   /// ========================
//   Future<void> close() async {
//     try {
//       for (final track in _localStream?.getTracks() ?? []) {
//         track.stop();
//       }
//       await _pc?.close();
//     } catch (_) {}

//     _localStream?.dispose();
//     _remoteStream?.dispose();

//     _pc = null;
//     _localStream = null;
//     _remoteStream = null;
//     _callId = null;
//     _targetId = null;
//   }
// }
