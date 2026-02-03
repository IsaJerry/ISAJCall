import 'package:flutter/material.dart';
import 'mine_page.dart';
import 'friends_page.dart';
import 'contacts_page.dart';
import '../auth/auth_service.dart';
import '../auth/call_service.dart';
import 'call_page.dart';

class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int index = 2;
  int requestCount = 0;
  bool _handlingIncoming = false;

  @override
  void initState() {
    super.initState();
    _bootstrapRealtime();
  }

  Future<void> _bootstrapRealtime() async {
    final uid = await AuthService.getCurrentUserId();
    if (!mounted || uid == null) return;

    // 全局来电：直接 push 到通话页面（用于学习/调试，后续可改成浮窗）
    CallService.onIncoming = (msg) {
      if (!mounted || _handlingIncoming) return;
      _handlingIncoming = true;

      final from =
          (msg["from"] ??
          msg["callerId"] ??
          msg["from_id"] ??
          msg["caller_id"]);
      final callerId = int.tryParse(from?.toString() ?? "") ?? -1;

      final contact = {
        "id": callerId,
        "username": msg["callerName"]?.toString() ?? "用户$callerId",
      };

      // Navigator.of(context)
      //     .push(
      //       MaterialPageRoute(
      //         builder: (_) => CallPage.incoming(
      //           contact: contact,
      //           currentUserId: uid,
      //           incomingPayload: msg,
      //         ),
      //       ),
      //     )
      //     .whenComplete(() {
      //   _handlingIncoming = false;
      // });
    };
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      ContactsPage(), // 新增联系人页
      FriendsPage(
        onRequestCountChange: (c) => setState(() => requestCount = c),
      ),
      MinePage(),
    ];

    return Scaffold(
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.contacts), label: "联系人"),
          BottomNavigationBarItem(
            icon: Stack(
              children: [
                Icon(Icons.group),
                if (requestCount > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: CircleAvatar(
                      radius: 8,
                      backgroundColor: Colors.red,
                      child: Text(
                        requestCount.toString(),
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ),
                  ),
              ],
            ),
            label: "管理",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "我的"),
        ],
      ),
    );
  }
}
