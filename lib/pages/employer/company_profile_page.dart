import 'package:flutter/material.dart';

class CompanyProfilePage extends StatelessWidget {
  const CompanyProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 将来的にAPIで動的取得
    const companyName = 'Calcraft Robotics Inc.';
    const followers = 1024;
    const posts = 12;
    const about =
        '産業ロボットとエンジニア採用をつなぐプラットフォーム開発。\n機械設計・組込・画像処理の実績あり。';

    return Scaffold(
      appBar: AppBar(title: const Text('Company Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 44,
            backgroundImage: NetworkImage('https://picsum.photos/200?company'),
          ),
          const SizedBox(height: 12),
          Text(companyName, textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(about, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _stat('フォロワー', followers),
              const SizedBox(width: 24),
              _stat('投稿', posts),
            ],
          ),
          const Divider(height: 32),
          const Text('会社からのお知らせ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const ListTile(
            dense: true,
            leading: Icon(Icons.campaign_outlined),
            title: Text('秋のインターン募集中'),
            subtitle: Text('2025/10/10'),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, int count) => Column(
        children: [
          Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: Colors.grey)),
        ],
      );
}
