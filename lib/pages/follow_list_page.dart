import 'package:flutter/material.dart';

class FollowListPage extends StatefulWidget {
  final String type; // "following" or "followers"

  const FollowListPage({super.key, required this.type});

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  // 仮データ（将来的にはCakePHP APIから取得）
  late List<Map<String, dynamic>> users;

  @override
  void initState() {
    super.initState();
    users = widget.type == 'following'
        ? [
            {
              'username': 'engineer_taro',
              'avatar': 'https://picsum.photos/200?1',
              'isFollowed': true,
            },
            {
              'username': 'student_ai',
              'avatar': 'https://picsum.photos/200?2',
              'isFollowed': true,
            },
          ]
        : [
            {
              'username': 'design_kana',
              'avatar': 'https://picsum.photos/200?3',
              'isFollowed': false,
            },
            {
              'username': 'cad_master',
              'avatar': 'https://picsum.photos/200?4',
              'isFollowed': true,
            },
          ];
  }

  void _toggleFollow(int index) {
    setState(() {
      users[index]['isFollowed'] = !users[index]['isFollowed'];
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'following' ? 'フォロー中' : 'フォロワー';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
      ),
      body: ListView.separated(
        itemCount: users.length,
        separatorBuilder: (_, __) => const Divider(height: 0),
        itemBuilder: (context, index) {
          final user = users[index];
          return ListTile(
            leading: CircleAvatar(
              backgroundImage: NetworkImage(user['avatar']),
              radius: 25,
            ),
            title: Text('@${user['username']}'),
            trailing: ElevatedButton(
              onPressed: () => _toggleFollow(index),
              style: ElevatedButton.styleFrom(
                backgroundColor: user['isFollowed']
                    ? Colors.grey.shade300
                    : Colors.blueAccent,
                foregroundColor:
                    user['isFollowed'] ? Colors.black87 : Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                textStyle: const TextStyle(fontSize: 13),
              ),
              child: Text(user['isFollowed'] ? 'フォロー中' : 'フォロー'),
            ),
            onTap: () {
              // Navigator.push(context, MaterialPageRoute(builder: (_) => ProfilePage(userId: ...)));
            },
          );
        },
      ),
    );
  }
}
