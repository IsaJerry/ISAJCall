import 'package:flutter/material.dart';
import '../auth/friends.dart';
import '../auth/auth_service.dart';
import '../auth/call_logs.dart';
import '../auth/ws_service.dart';
import 'contact_logs.dart';

class ContactsPage extends StatefulWidget {
  const ContactsPage({super.key});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  List contacts = [];
  int currentUserId = -1;
  bool loading = false;
  Map<int, int> unreadMap = {}; // contactId -> count
  Map<int, bool> onlineMap = {}; // contactId -> 在线状态

  @override
  void initState() {
    super.initState();
    loadContacts();
    loadUnread();

    WSService.addEventListener(onWsEvent);
  }

  @override
  void dispose() {
    WSService.removeEventListener(onWsEvent);
    super.dispose();
  }

  void onWsEvent(Map data) {
    if (!mounted) return;

    // 1. 实时消息
    if (data["type"] == "real-time-message") {
      final int fromId = data["from_id"];
      final int toId = data["to_id"];

      // 只处理别人发给我的消息
      if (toId == currentUserId && fromId != currentUserId) {
        // 更新小红点
        setState(() {
          unreadMap[fromId] = (unreadMap[fromId] ?? 0) + 1;
        });
      }
    }

    // 2. 好友在线状态变化
    if (data["type"] == "online-status" && data["targetUserId"] != null) {
      final id = int.parse(data["targetUserId"].toString());
      final online = data["isOnline"] == true;
      setState(() {
        onlineMap[id] = online;
      });
    }
  }

  Future<void> loadContacts() async {
    setState(() => loading = true);
    contacts = await FriendsService.getContacts();
    currentUserId = await AuthService.getCurrentUserId() ?? -1;

    // 初始化在线状态
    for (var c in contacts) {
      final id = c["id"];
      if (id != null) {
        // 优先用 WS 已知状态
        bool? online = WSService.friendsOnline[id];

        // 如果 WS 没有记录，则主动请求 HTTP
        if (online == null) {
          online = await WSService.queryOnline(id);
        }

        onlineMap[id] = online ?? false;
      }
    }

    setState(() => loading = false);
  }

  Future<void> loadUnread() async {
    //清空
    unreadMap.clear();

    final res = await CallLogsService.getUnreadMessages();
    if (res == null || res["unread_count"] == 0) return;

    for (var m in res["unread_list"]) {
      final fromId = m["sender_id"];
      unreadMap[fromId] = (unreadMap[fromId] ?? 0) + 1;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("联系人")),
      body: RefreshIndicator(
        onRefresh: loadContacts,
        child: loading
            ? Center(child: CircularProgressIndicator())
            : ListView.builder(
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final c = contacts[index];
                  final id = c["id"];
                  final isOnline = onlineMap[id] ?? false;
                  return ListTile(
                    title: Text(c["username"]),
                    subtitle: Text(
                      isOnline ? "在线" : "离线",
                      style: TextStyle(
                        fontSize: 12,
                        color: isOnline ? Colors.green : Colors.red,
                      ),
                    ),
                    trailing: unreadMap[id] != null
                        ? Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              unreadMap[id].toString(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          )
                        : null,
                    onTap: () async {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ContactLogsPage(
                            contact: c,
                            currentUserId: currentUserId,
                          ),
                        ),
                      ).then((_) {
                        //清除小红点
                        if (id != null) {
                          unreadMap.remove(id);
                          setState(() {});
                        }

                        // 返回后刷新未读
                        loadUnread();
                      });
                    },
                  );
                },
              ),
      ),
    );
  }
}
