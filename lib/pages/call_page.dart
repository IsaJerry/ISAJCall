import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

import '../models/call_state.dart';
import '../auth/call_service.dart';
import '../native_call.dart';

enum CallUIStage { calling, ringing, connected }

class CallPage extends StatefulWidget {
  final CallState call;
  final bool isCaller;

  const CallPage({super.key, required this.call, required this.isCaller});

  @override
  State<CallPage> createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> {
  late CallUIStage stage;

  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();

  bool micOn = true;
  bool cameraOn = true;
  bool speakerOn = true;

  @override
  void initState() {
    super.initState();
    stage = widget.isCaller ? CallUIStage.calling : CallUIStage.ringing;
    _init();
    _bindSignals();
  }

  Future<void> _init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _localRenderer.srcObject = widget.call.localStream;
  }

  void _bindSignals() {
    CallService.onAccepted = (msg) async {
      CallService.cancelCallTimeout();
      await widget.call.pc!.setRemoteDescription(
        RTCSessionDescription(msg['sdp'], 'answer'),
      );
    };

    CallService.onConnected = (_) {
      setState(() => stage = CallUIStage.connected);
      _remoteRenderer.srcObject = widget.call.remoteStream;
    };

    CallService.onHangup = (_) => _exit();
    CallService.onTimeout = (_) => _exit();
    CallService.onError = (_) => _exit();
  }

  void _exit() {
    if (mounted) Navigator.pop(context);
  }

  void _hangup() {
    CallService.hangup();
    _exit();
  }

  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }

  // ================= UI =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          RTCVideoView(
            stage == CallUIStage.connected ? _remoteRenderer : _localRenderer,
            objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
          ),
          if (stage == CallUIStage.connected)
            Positioned(
              right: 16,
              bottom: 120,
              child: SizedBox(
                width: 120,
                height: 160,
                child: RTCVideoView(_localRenderer, mirror: true),
              ),
            ),
          Positioned(
            top: 40,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
              onPressed: NativeCall.enterPictureInPicture,
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [_btn(Icons.call_end, Colors.red, _hangup, 64)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _btn(IconData icon, Color color, VoidCallback onTap, double size) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black54,
        ),
        child: Icon(icon, color: color),
      ),
    );
  }
}
