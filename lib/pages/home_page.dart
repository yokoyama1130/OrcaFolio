import 'package:flutter/material.dart';
import '../widgets/portfolio_card.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calcraft'),
        centerTitle: true,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: 8,
        itemBuilder: (context, index) {
          return PortfolioCard(
            portfolioId: -1,                       // ダミーID（詳細遷移しない想定なら -1 等）
            apiBaseUrl: 'http://127.0.0.1:8765',   // 実機なら Mac のIPに
            username: 'yokoyama1130',
            title: '3Dプリンタで作る自作ロボットアーム',
            imageUrl: 'https://picsum.photos/400/250',
            likes: 42,
          );
        },
      ),
    );
  }
}
