import 'package:flutter/material.dart';
import '../auth/friends.dart';

class FriendsPage extends StatefulWidget {
  final Function(int) onRequestCountChange;
  FriendsPage({required this.onRequestCountChange});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage> {
  final ctrl = TextEditingController();
  List users = [];
  List requests = [];

  @override
  void initState() {
    super.initState();
    loadRequests();
  }

  search() async {
    users = await FriendsService.searchUsers(ctrl.text);
    setState(() {});
  }

  loadRequests() async {
    requests = await FriendsService.getRequests();
    widget.onRequestCountChange(requests.length);
    setState(() {});
  }

  sendRequest(int userId) async {
    final err = await FriendsService.sendRequest(userId);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(err ?? "好友申请已发送")));
  }

  accept(int requestId) async {
    await FriendsService.accept(requestId);
    loadRequests();
  }

  reject(int requestId) async {
    final err = await FriendsService.reject(requestId);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
    }
    loadRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("好友管理")),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    decoration: InputDecoration(hintText: "搜索用户名"),
                  ),
                ),
                IconButton(icon: Icon(Icons.search), onPressed: search),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              children: [
                ...users.map(
                  (u) => ListTile(
                    title: Text(u["username"]),
                    trailing: ElevatedButton(
                      child: Text("发送申请"),
                      onPressed: () =>
                          sendRequest(int.parse(u["id"].toString())),
                    ),
                  ),
                ),
                if (requests.isNotEmpty) Divider(),
                ...requests.map(
                  (r) => ListTile(
                    title: Text(r["username"]),
                    subtitle: Text("好友申请"),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.check, color: Colors.green),
                          onPressed: () => accept(r["id"]),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.red),
                          onPressed: () => reject(r["id"]),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
