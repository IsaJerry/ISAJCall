// import 'package:flutter/material.dart';
// import '../auth/call_service.dart';
// import 'call_page.dart';

// class CallAcceptPage extends StatefulWidget {
//   final int callerId;
//   final String callId;
//   final Map callerInfo; // 可包含昵称/头像等信息

//   const CallAcceptPage({
//     super.key,
//     required this.callerId,
//     required this.callId,
//     required this.callerInfo,
//   });

//   @override
//   State<CallAcceptPage> createState() => _CallAcceptPageState();
// }

// class _CallAcceptPageState extends State<CallAcceptPage>
//     with SingleTickerProviderStateMixin {
//   late AnimationController _controller;
//   late Animation<Offset> _slideAnimation;

//   @override
//   void initState() {
//     super.initState();

//     // 动画从顶部滑下
//     _controller = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 300),
//     );
//     _slideAnimation = Tween<Offset>(
//       begin: const Offset(0, -1),
//       end: Offset.zero,
//     ).animate(_controller);

//     _controller.forward();
//   }

//   @override
//   void dispose() {
//     _controller.dispose();
//     super.dispose();
//   }

//   void _acceptCall() async {
//     await CallService.acceptCall(
//       callId: widget.callId,
//       callerId: widget.callerId,
//       offerSdp: "", // offerSdp 会从 WS 推送中获得
//     );

//     // 跳转到 CallPage
//     if (mounted) {
//       Navigator.of(context).pushReplacement(
//         MaterialPageRoute(builder: (_) => CallPage(contact: widget.callerInfo)),
//       );
//     }
//   }

//   void _rejectCall() {
//     CallService.rejectCall();
//     if (mounted) Navigator.of(context).pop();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return SlideTransition(
//       position: _slideAnimation,
//       child: Material(
//         color: Colors.transparent,
//         child: Container(
//           width: double.infinity,
//           color: Colors.blueGrey.shade900.withOpacity(0.9),
//           padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//           child: Row(
//             children: [
//               CircleAvatar(
//                 radius: 28,
//                 backgroundImage: NetworkImage(
//                   widget.callerInfo['avatar'] ?? '',
//                 ),
//                 child: widget.callerInfo['avatar'] == null
//                     ? const Icon(Icons.person, size: 28)
//                     : null,
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       widget.callerInfo['name'] ?? '来电者',
//                       style: const TextStyle(
//                         color: Colors.white,
//                         fontSize: 18,
//                         fontWeight: FontWeight.bold,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     const Text(
//                       '正在呼叫…',
//                       style: TextStyle(color: Colors.white70, fontSize: 14),
//                     ),
//                   ],
//                 ),
//               ),
//               Row(
//                 children: [
//                   IconButton(
//                     onPressed: _rejectCall,
//                     icon: const Icon(Icons.call_end, color: Colors.red),
//                     iconSize: 36,
//                   ),
//                   const SizedBox(width: 8),
//                   IconButton(
//                     onPressed: _acceptCall,
//                     icon: const Icon(Icons.call, color: Colors.green),
//                     iconSize: 36,
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
