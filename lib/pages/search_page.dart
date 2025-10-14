import 'package:flutter/material.dart';
import '../widgets/portfolio_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  // 仮データ（後でAPIに置き換える）
  final List<Map<String, dynamic>> _allPortfolios = [
    {
      'username': 'yokoyama1130',
      'title': 'ロボットアーム開発記録',
      'imageUrl': 'https://picsum.photos/400/250?1',
      'likes': 48,
    },
    {
      'username': 'engineer_taro',
      'title': '3Dプリンタで自作ドローンを設計',
      'imageUrl': 'https://picsum.photos/400/250?2',
      'likes': 23,
    },
    {
      'username': 'student_ai',
      'title': 'AI画像解析システム構築メモ',
      'imageUrl': 'https://picsum.photos/400/250?3',
      'likes': 12,
    },
  ];

  List<Map<String, dynamic>> _filtered = [];

  @override
  void initState() {
    super.initState();
    _filtered = _allPortfolios;
  }

  void _search(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filtered = _allPortfolios;
      } else {
        _filtered = _allPortfolios
            .where((p) =>
                p['title'].toLowerCase().contains(query.toLowerCase()) ||
                p['username'].toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('検索'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: '投稿やユーザーを検索...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                suffixIcon: _controller.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _controller.clear();
                          _search('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const Center(child: Text('検索結果がありません'))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      final p = _filtered[index];
                      return PortfolioCard(
                        username: p['username'],
                        title: p['title'],
                        imageUrl: p['imageUrl'],
                        likes: p['likes'],
                        initiallyLiked: false,      // 初期状態（将来APIから取得）
                        initiallyFollowed: false, 
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
