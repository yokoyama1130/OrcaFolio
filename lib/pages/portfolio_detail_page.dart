import 'package:flutter/material.dart';

class PortfolioDetailPage extends StatelessWidget {
  const PortfolioDetailPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Navigatorで渡されたデータを受け取る
    final Map<String, dynamic>? args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final title = args?['title'] ?? '作品タイトル';
    final imageUrl = args?['imageUrl'] ?? 'https://picsum.photos/600/400';
    final username = args?['username'] ?? 'Unknown User';
    final likes = args?['likes'] ?? 0;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(imageUrl, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text('by @$username', style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.favorite, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  Text('$likes likes'),
                ],
              ),
              const Divider(height: 32),
              const Text(
                'プロジェクト概要',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'このプロジェクトでは、3Dプリンタとサーボモータを用いてロボットアームを製作しました。'
                'CAD設計から制御プログラムまでを一貫して担当し、'
                'モジュール構造によって自由な動作が可能なアームを実現しています。',
                style: TextStyle(height: 1.6),
              ),
              const Divider(height: 32),
              const Text(
                'コメント',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _CommentWidget(
                username: 'engineer_taro',
                comment: 'めちゃくちゃかっこいいです！構造も美しい！',
              ),
              _CommentWidget(
                username: 'student_ai',
                comment: '制御部分の詳細知りたいです！',
              ),
              const SizedBox(height: 40),
              TextField(
                decoration: InputDecoration(
                  hintText: 'コメントを入力...',
                  suffixIcon: IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.send),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CommentWidget extends StatelessWidget {
  final String username;
  final String comment;

  const _CommentWidget({required this.username, required this.comment});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            radius: 18,
            backgroundImage: NetworkImage('https://picsum.photos/100'),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('@$username', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(comment),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
