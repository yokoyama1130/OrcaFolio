import 'package:flutter/material.dart';
import 'chat_page.dart';

class DMListPage extends StatelessWidget {
  const DMListPage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dmList = [
      {
        'username': 'engineer_taro',
        'lastMessage': 'また新しいロボット作ってるの？',
        'time': '昨日',
        'avatar': 'https://picsum.photos/200?1',
      },
      {
        'username': 'student_ai',
        'lastMessage': 'ポートフォリオ拝見しました！素敵です！',
        'time': '2日前',
        'avatar': 'https://picsum.photos/200?2',
      },
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('メッセージ'),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: dmList.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final dm = dmList[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(dm['avatar']),
              radius: 26,
            ),
            title: Text(dm['username'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(dm['lastMessage'], maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: Text(dm['time'], style: const TextStyle(color: Colors.grey)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(username: dm['username'], avatarUrl: dm['avatar']),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
