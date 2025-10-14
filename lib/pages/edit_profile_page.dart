import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController =
      TextEditingController(text: 'yokoyama1130');
  final TextEditingController _bioController =
      TextEditingController(text: '機械系エンジニア × Web開発者\nロボット・CAD・アプリ開発やってます。');

  String avatarUrl = 'https://picsum.photos/200';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('プロフィール編集')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // アイコン画像
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: NetworkImage(avatarUrl),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: IconButton(
                      onPressed: () {
                      },
                      icon: const Icon(Icons.camera_alt, color: Colors.blueAccent),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 名前
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'ユーザー名'),
            ),
            const SizedBox(height: 12),

            // 自己紹介
            TextField(
              controller: _bioController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: '自己紹介'),
            ),
            const SizedBox(height: 20),

            // 保存ボタン
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('プロフィールを更新しました')),
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }
}
