import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../widgets/portfolio_card.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.apiBaseUrl = 'http://127.0.0.1:8765', // 実機は http://<MacのIP>:8765 に変える
  });

  final String apiBaseUrl;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchTop();
  }

  Future<List<Map<String, dynamic>>> _fetchTop() async {
    // iOSシミュ対策: localhost → 127.0.0.1 に正規化
    final baseUri = Uri.parse(widget.apiBaseUrl.replaceAll(RegExp(r'/$'), ''));
    final normalizedBase =
        baseUri.host == 'localhost' ? baseUri.replace(host: '127.0.0.1') : baseUri;

    // JSONエンドポイント（下の②APIを入れると /api/top/index.json で返ります）
    final uri = Uri.parse('${normalizedBase.toString()}/api/top/index.json');

    final res = await http.get(uri).timeout(const Duration(seconds: 20));
    if (res.statusCode != 200) {
      // レスポンス本文にエラーがあるなら見える化
      String extra = '';
      try {
        extra = ' - ${res.body}';
      } catch (_) {}
      throw Exception('Failed: ${res.statusCode}$extra');
    }

    final map = json.decode(res.body) as Map<String, dynamic>;
    if (map['success'] == true && map['portfolios'] is List) {
      return (map['portfolios'] as List).cast<Map<String, dynamic>>();
    }
    // successを返さない実装でも portfolios があれば拾う
    if (map['portfolios'] is List) {
      return (map['portfolios'] as List).cast<Map<String, dynamic>>();
    }
    throw Exception(map['message']?.toString() ?? 'Invalid response');
  }

  // /uploads or /img/uploads を絶対URLへ
  String _absUrl(String? input) {
    if (input == null || input.isEmpty) return '';
    final baseUri = Uri.parse(widget.apiBaseUrl.replaceAll(RegExp(r'/$'), ''));
    final normalizedBase =
        baseUri.host == 'localhost' ? baseUri.replace(host: '127.0.0.1') : baseUri;

    // すでに http(s)
    if (input.startsWith('http://') || input.startsWith('https://')) {
      final u = Uri.parse(input);
      final fixedHost = (u.host == 'localhost') ? u.replace(host: '127.0.0.1') : u;
      return fixedHost.replace(path: _normalizeUploadsPath(fixedHost.path)).toString();
    }

    String path = input.startsWith('/') ? input : '/$input';
    path = _normalizeUploadsPath(path);
    return '${normalizedBase.toString()}$path';
  }

  // 実体が webroot/uploads のため、/img/uploads → /uploads に寄せる
  String _normalizeUploadsPath(String path) {
    var p = path;
    p = p.replaceFirst(RegExp(r'^//+'), '/');                 // //uploads → /uploads
    p = p.replaceFirst(RegExp(r'^/img/+img/'), '/img/');      // /img/img/uploads → /img/uploads
    p = p.replaceFirst('/img//uploads/', '/img/uploads/');    // /img//uploads → /img/uploads
    if (p.startsWith('/img/uploads/')) {
      p = p.replaceFirst('/img/uploads/', '/uploads/');
    }
    return p;
  }

  Future<void> _reload() async {
    setState(() {
      _future = _fetchTop();
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calcraft'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _future,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return ListView(
                children: [
                  const SizedBox(height: 60),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('読み込みに失敗しました:\n${snap.error}'),
                  ),
                ],
              );
            }

            final list = snap.data!;
            if (list.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 60),
                  Center(child: Text('公開中の投稿はまだありません')),
                ],
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: list.length,
              itemBuilder: (context, index) {
                // ★ list[index] をまず String,dynamic 化（想定外型でも落ちにくく）
                final Map<String, dynamic> p =
                    Map<String, dynamic>.from(list[index] as Map);

                // ★ user も安全に取り出す（const {} を as しない）
                final Map<String, dynamic> user = (p['user'] is Map)
                    ? Map<String, dynamic>.from(p['user'] as Map)
                    : const <String, dynamic>{};

                final id   = (p['id'] as num).toInt();
                final name = (user['name'] ?? 'User') as String;

                final rawImg = (p['thumbnail'] ??
                                p['imageUrl'] ??
                                p['image_url'] ??
                                p['img']) as String?;
                final imgUrl = _absUrl(rawImg);

                final likes = ((p['like_count'] ?? p['likes'] ?? 0) as num).toInt();
                final liked = (p['liked_by_me'] ?? false) as bool;

                return PortfolioCard(
                  portfolioId: id,
                  apiBaseUrl: widget.apiBaseUrl,
                  username: name,
                  title: (p['title'] ?? '') as String,
                  imageUrl: imgUrl.isEmpty ? 'https://picsum.photos/400/250' : imgUrl,
                  likes: likes,
                  initiallyLiked: liked,
                  initiallyFollowed: false,
                );
              },
            );
          },
        ),
      ),
    );
  }
}
