// lib/pages/search_page.dart
import 'package:flutter/material.dart';
import '../widgets/portfolio_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    this.apiBaseUrl = 'http://localhost:8765', // 実機は http://<MacのIP>:8765
  });

  /// 画像の相対パスを絶対URL化するための基底URL
  final String apiBaseUrl;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _controller = TextEditingController();

  // 仮データ（API置換前提）: id を追加しておく
  final List<Map<String, dynamic>> _allPortfolios = [
    {
      'id': 1,
      'username': 'yokoyama1130',
      'title': 'ロボットアーム開発記録',
      'imageUrl': 'https://picsum.photos/400/250?1',
      'likes': 48,
    },
    {
      'id': 2,
      'username': 'engineer_taro',
      'title': '3Dプリンタで自作ドローンを設計',
      'imageUrl': 'https://picsum.photos/400/250?2',
      'likes': 23,
    },
    {
      'id': 3,
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
        final q = query.toLowerCase();
        _filtered = _allPortfolios
            .where((p) =>
                (p['title'] as String).toLowerCase().contains(q) ||
                (p['username'] as String).toLowerCase().contains(q))
            .toList();
      }
    });
  }

  // ===== 画像URL補正ヘルパ（/uploads → /img/uploads, localhost→127.0.0.1）=====
  String _absUrl(String? input, {String fallback = 'https://picsum.photos/400/250'}) {
    if (input == null || input.isEmpty) return fallback;
    var raw = input.trim();

    // すでに http(s) の絶対URLなら最小補正だけ
    Uri? u;
    try {
      u = Uri.parse(raw);
    } catch (_) {}
    if (u != null && (u.scheme == 'http' || u.scheme == 'https')) {
      if (u.host == 'localhost') {
        u = u.replace(host: '127.0.0.1');
      }
      return u.replace(path: _normalizeUploadsPath(u.path)).toString();
    }

    // 相対パス → ベースURL前置
    final base = Uri.parse(widget.apiBaseUrl.replaceAll(RegExp(r'/$'), ''));
    final normalizedBase = base.host == 'localhost' ? base.replace(host: '127.0.0.1') : base;
    var path = raw.startsWith('/') ? raw : '/$raw';
    path = _normalizeUploadsPath(path);
    return '${normalizedBase.toString()}$path';
  }

  /// /uploads → /img/uploads、/img/img/uploads → /img/uploads に寄せる
  String _normalizeUploadsPath(String path) {
    var p = path.replaceFirst(RegExp(r'^//+'), '/');       // 先頭の // を /
    if (p.startsWith('/uploads/')) p = '/img$p';           // /uploads → /img/uploads
    p = p.replaceFirst('/img//uploads/', '/img/uploads/'); // /img//uploads → /img/uploads
    p = p.replaceFirst(RegExp(r'^/img/+img/'), '/img/');   // /img/img/ → /img/
    return p;
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

                      final rawImg = p['imageUrl'] ?? p['thumbnail'] ?? '';
                      final imgUrl = _absUrl(rawImg);

                      return PortfolioCard(
                        portfolioId: (p['id'] as num).toInt(), // ★ 必須
                        apiBaseUrl: widget.apiBaseUrl,         // ★ 必須
                        username: p['username'] ?? (p['user']?['name'] ?? 'User'),
                        title: p['title'] ?? '',
                        imageUrl: imgUrl,
                        likes: (p['likes'] ?? p['like_count'] ?? 0) as int,
                        initiallyLiked: false,
                        initiallyFollowed: false,
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}
