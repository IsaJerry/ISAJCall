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
    _initRenderers();
    _bindSignals();
  }

  Future<void> _initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    _localRenderer.srcObject = widget.call.localStream;
  }

  void _bindSignals() {
    CallService.onAccepted = (msg) async {
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
    Navigator.pop(context);
  }

  void _toggleMic() {
    for (final t in widget.call.localStream!.getAudioTracks()) {
      t.enabled = !t.enabled;
    }
    setState(() => micOn = !micOn);
  }

  void _toggleCamera() {
    for (final t in widget.call.localStream!.getVideoTracks()) {
      t.enabled = !t.enabled;
    }
    setState(() => cameraOn = !cameraOn);
  }

  void _toggleSpeaker() {
    speakerOn = !speakerOn;
    setState(() {});
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
          _buildMainVideo(),
          if (stage == CallUIStage.connected) _buildLocalPreview(),
          _buildTopBar(),
          _buildBottomControls(),
        ],
      ),
    );
  }

  Widget _buildMainVideo() {
    return Positioned.fill(
      child: RTCVideoView(
        stage == CallUIStage.connected ? _remoteRenderer : _localRenderer,
        objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
      ),
    );
  }

  Widget _buildLocalPreview() {
    return Positioned(
      right: 16,
      bottom: 120,
      child: Container(
        width: 120,
        height: 160,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: RTCVideoView(
          _localRenderer,
          mirror: true,
          objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Positioned(
      top: 40,
      left: 16,
      child: IconButton(
        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
        onPressed: NativeCall.enterPictureInPicture,
      ),
    );
  }

  Widget _buildBottomControls() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 30,
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _circleButton(
              icon: micOn ? Icons.mic : Icons.mic_off,
              color: micOn ? Colors.white : Colors.red,
              onTap: _toggleMic,
            ),
            _circleButton(
              icon: cameraOn ? Icons.videocam : Icons.videocam_off,
              color: cameraOn ? Colors.white : Colors.red,
              onTap: _toggleCamera,
            ),
            _circleButton(
              icon: Icons.call_end,
              color: Colors.red,
              size: 64,
              onTap: _hangup,
            ),
            _circleButton(
              icon: speakerOn ? Icons.volume_up : Icons.hearing,
              color: Colors.white,
              onTap: _toggleSpeaker,
            ),
          ],
        ),
      ),
    );
  }

  Widget _circleButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double size = 48,
  }) {
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
