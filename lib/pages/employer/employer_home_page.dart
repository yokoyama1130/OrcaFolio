import 'package:flutter/material.dart';

class EmployerHomePage extends StatelessWidget {
  const EmployerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> posts = [
      {'title': '機械設計インターン募集', 'likes': 32, 'date': '2025/10/01'},
      {'title': 'ロボ実装プロジェクトメンバー募集', 'likes': 18, 'date': '2025/09/20'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Employer Home'),
        centerTitle: true,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(12),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemCount: posts.length,
        itemBuilder: (_, i) {
          final p = posts[i];
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p['title'] as String,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.favorite, size: 18, color: Colors.redAccent),
                      const SizedBox(width: 4),
                      Text('${p['likes']}'),
                      const Spacer(),
                      Text(
                        p['date'] as String,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: 応募者一覧ページへ遷移
                          // Navigator.push(context, MaterialPageRoute(builder: (_) => ApplicantsPage(postId: ...)));
                        },
                        icon: const Icon(Icons.people_outline),
                        label: const Text('応募者を見る'),
                      ),
                      const SizedBox(width: 8),
                      TextButton.icon(
                        onPressed: () {
                          // TODO: 投稿編集へ
                        },
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('編集'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
