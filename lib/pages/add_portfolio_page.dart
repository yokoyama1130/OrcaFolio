import 'package:flutter/material.dart';

class AddPortfolioPage extends StatelessWidget {
  const AddPortfolioPage({super.key});

  @override
  Widget build(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController descController = TextEditingController();

    return Scaffold(
      appBar: AppBar(title: const Text('New Portfolio')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'タイトル'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 5,
              decoration: const InputDecoration(labelText: '説明文'),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.upload),
                label: const Text('画像をアップロード'),
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                // CakePHP APIにPOSTする処理を後で追加
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('投稿する'),
            ),
          ],
        ),
      ),
    );
  }
}
