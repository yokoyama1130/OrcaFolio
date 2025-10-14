import 'package:flutter/material.dart';
import '../widgets/portfolio_card.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://picsum.photos/200'),
          ),
          const SizedBox(height: 12),
          const Text('yokoyama1130', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text('機械系エンジニア × Web開発者\nロボット・CAD・アプリ開発やってます。', textAlign: TextAlign.center),
          const Divider(height: 32),
          const Text('My Portfolios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(3, (index) {
            return const PortfolioCard(
              username: 'yokoyama1130',
              title: 'ロボットアーム製作プロジェクト',
              imageUrl: 'https://picsum.photos/400/200',
              likes: 27,
            );
          }),
        ],
      ),
    );
  }
}
