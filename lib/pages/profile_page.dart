import 'package:flutter/material.dart';
import '../widgets/portfolio_card.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'follow_list_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const int followingCount = 128;
    const int followerCount = 212;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'プロフィール編集',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EditProfilePage()),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 50,
            backgroundImage: NetworkImage('https://picsum.photos/200'),
          ),
          const SizedBox(height: 12),
          const Text(
            'yokoyama1130',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            '機械系エンジニア × Web開発者\nロボット・CAD・アプリ開発やってます。',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // フォロー・フォロワー
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildFollowStat('フォロー', followingCount, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FollowListPage(type: 'following'),
                  ),
                );
              }),
              const SizedBox(width: 24),
              _buildFollowStat('フォロワー', followerCount, () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const FollowListPage(type: 'followers'),
                  ),
                );
              }),
            ],
          ),
          const Divider(height: 32),
          const Text('My Portfolios',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...List.generate(3, (index) {
            return const PortfolioCard(
              username: 'yokoyama1130',
              title: 'ロボットアーム製作プロジェクト',
              imageUrl: 'https://picsum.photos/400/200',
              likes: 27,
              initiallyLiked: false,
              initiallyFollowed: false,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFollowStat(String label, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          children: [
            Text(
              '$count',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }
}
