import 'package:flutter/material.dart';
import '../auth/call_logs.dart';
import '../auth/call_service.dart';
import '../auth/ws_service.dart';
import 'call_page.dart';

class ContactLogsPage extends StatefulWidget {
  final Map contact;
  final int currentUserId;

  const ContactLogsPage({
    super.key,
    required this.contact,
    required this.currentUserId,
  });

  @override
  State<ContactLogsPage> createState() => _ContactLogsPageState();
}

class _ContactLogsPageState extends State<ContactLogsPage>
    with WidgetsBindingObserver {
  List logs = [];
  final msgCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool? contactWsConnected;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    loadLogs();
    _initContactOnlineStatus();

    // 添加 WS 事件监听
    WSService.addEventListener(onWsEvent);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WSService.removeEventListener(onWsEvent);
    msgCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 监听键盘弹出
  @override
  void didChangeMetrics() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  // 应用前后台切换
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 注意：WS 是全局连接，不应该由某个聊天页面在前后台切换时随意断开/重连。
    // 全局生命周期（例如在 HomePage/MyApp）统一管理更安全。
  }

  void _initContactOnlineStatus() async {
    final targetId = int.parse(widget.contact["id"].toString());
    bool? online = WSService.friendsOnline[targetId];

    if (online == null) {
      online = await WSService.queryOnline(targetId);
    }

    setState(() {
      contactWsConnected = online;
    });
  }

  void _scrollToBottom({bool animated = true}) {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.maxScrollExtent;
      if (animated) {
        _scrollController.animateTo(
          position,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scrollController.jumpTo(position);
      }
    }
  }

  Future<void> loadLogs() async {
    setState(() => loading = true);

    logs = await CallLogsService.getChatHistory(
      int.parse(widget.contact["id"].toString()),
    );

    logs = logs.reversed.toList();

    // 标记所有未读消息为已读
    for (var r in logs) {
      if (r["type"] == "message" &&
          r["is_read"] == 0 &&
          r["to_id"] == widget.currentUserId) {
        await CallLogsService.markMessageRead(r["id"]);
        r["is_read"] = 1; // 本地也更新
      }
    }

    setState(() => loading = false);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom(animated: false);
    });
  }

  Future<void> _startCall(BuildContext context) async {
    final calleeId = int.parse(widget.contact["id"].toString());

    try {
      final call = await CallService.startCall(
        selfId: widget.currentUserId,
        peerId: calleeId,
      );

      if (!context.mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => CallPage(call: call, isCaller: true)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("发起通话失败：$e")));
    }
  }

  void sendMessage() async {
    final text = msgCtrl.text.trim();
    if (text.isEmpty) return;

    final recipientId = int.parse(widget.contact["id"].toString());

    final err = await CallLogsService.sendMessage(
      recipientId: recipientId,
      content: text,
    );

    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    // 本地渲染（临时显示，稍后服务器会推送 real-time-message 更新状态）
    final message = {
      "type": "message",
      "messageId": DateTime.now().millisecondsSinceEpoch,
      "from_id": widget.currentUserId,
      "to_id": recipientId,
      "data": text,
      "created_at": DateTime.now().toIso8601String(),
      "is_read": 1,
    };
    setState(() => logs.add(message));
    msgCtrl.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    // 不再发送 WebSocket 消息
  }

  void onWsEvent(Map data) {
    if (!mounted) return;

    final targetId = int.parse(widget.contact["id"].toString());

    // 在线状态更新
    if (data["type"] == "online-status" &&
        data["targetUserId"].toString() == targetId.toString()) {
      setState(() {
        contactWsConnected = data["isOnline"] == true;
      });
    }

    // 实时消息
    if (data["type"] == "real-time-message") {
      onRealtimeMessage(data);
    }
  }

  void onRealtimeMessage(Map data) {
    if (data["type"] != "real-time-message") return;

    final int fromId = data["from_id"];
    final int toId = data["to_id"];
    final int contactId = int.parse(widget.contact["id"].toString());

    final bool isCurrentChat =
        (fromId == contactId && toId == widget.currentUserId) ||
        (fromId == widget.currentUserId && toId == contactId);

    if (!isCurrentChat) return;

    // 更新本地 logs
    setState(() {
      logs.add({
        "id": data["messageId"],
        "type": "message",
        "from_id": fromId,
        "to_id": toId,
        "data": data["content"],
        "created_at": data["created_at"],
        "is_read": toId == widget.currentUserId ? 1 : data["is_read"],
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });

    // 标记已读
    if (toId == widget.currentUserId) {
      CallLogsService.markMessageRead(data["messageId"]);
    }
  }

  Color getContactColor() {
    if (contactWsConnected == true) return Colors.lightBlue;
    if (contactWsConnected == false) return Colors.red;
    return Colors.black;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // 顶部栏
            Container(
              height: 50,
              alignment: Alignment.center,
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () =>
                          Navigator.pop(context, widget.contact["id"]),
                    ),
                  ),
                  Center(
                    child: Text(
                      widget.contact["username"],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: getContactColor(),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: const Icon(Icons.call, color: Colors.green),
                      onPressed: () => _startCall(context),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // 消息列表
            Expanded(
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: logs.length,
                  itemBuilder: (context, index) {
                    final r = logs[index];

                    if (r["type"] == "message") {
                      final isMe = r["from_id"] == widget.currentUserId;
                      return Align(
                        alignment: isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.all(6),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.green[100] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(r["data"]),
                        ),
                      );
                    }

                    // 通话记录
                    return ListTile(
                      title: const Text("📞 通话记录"),
                      subtitle: Text(r["status"] ?? ""),
                    );
                  },
                ),
              ),
            ),
            // 输入框
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              color: Colors.grey[100],
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: msgCtrl,
                      onTap: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _scrollToBottom();
                        });
                      },
                      decoration: const InputDecoration(
                        hintText: "请输入消息",
                        border: OutlineInputBorder(),
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: sendMessage,
                    child: const Text("发送"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
