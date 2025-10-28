import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../widgets/portfolio_card.dart';

class LikesPage extends StatefulWidget {
  final String apiBaseUrl;
  const LikesPage({super.key, required this.apiBaseUrl});

  @override
  State<LikesPage> createState() => _LikesPageState();
}

class _LikesPageState extends State<LikesPage> {
  static const _storage = FlutterSecureStorage();

  bool _loading = true;
  String _error = '';
  List<Map<String, dynamic>> _items = [];

  // HomePageと同等の「localhost→127.0.0.1」補正済みベースURL
  late final Uri _normalizedBase;

  @override
  void initState() {
    super.initState();
    final baseUri = Uri.parse(widget.apiBaseUrl.replaceAll(RegExp(r'/$'), ''));
    _normalizedBase =
        baseUri.host == 'localhost' ? baseUri.replace(host: '127.0.0.1') : baseUri;

    _fetchLikes();
  }

  Future<void> _fetchLikes() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final token = await _storage.read(key: 'jwt');
      if (token == null || token.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = 'ログインが必要です。';
          _loading = false;
          _items = [];
        });
        return;
      }

      final uri = Uri.parse('${_normalizedBase.toString()}/api/likes/favorites.json');
      final res = await http
          .get(
            uri,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        if (!mounted) return;
        setState(() {
          _error = 'サーバーエラー (${res.statusCode})';
          _loading = false;
          _items = [];
        });
        return;
      }

      if (res.body.isEmpty) {
        if (!mounted) return;
        setState(() {
          _error = '空のレスポンスが返りました（body is empty）';
          _loading = false;
          _items = [];
        });
        return;
      }

      final ctype = (res.headers['content-type'] ?? '').toLowerCase();
      if (!ctype.contains('application/json')) {
        if (!mounted) return;
        setState(() {
          _error = 'JSON以外のレスポンスです: $ctype';
          _loading = false;
          _items = [];
        });
        return;
      }

      final body = jsonDecode(res.body) as Map<String, dynamic>;
      final raw = body['portfolios'];
      if (raw is! List) {
        if (!mounted) return;
        setState(() {
          _error = '予期しないレスポンス形式（"portfolios" が配列ではありません）';
          _loading = false;
          _items = [];
        });
        return;
      }

      // サーバーから来た値を最小整形（アイコンとサムネの絶対URL化）
      final items = raw.map<Map<String, dynamic>>((e) {
        final m = Map<String, dynamic>.from(e as Map);

        // user.icon_path を正規化
        if (m['user'] is Map) {
          final u = Map<String, dynamic>.from(m['user'] as Map);
          u['icon_path'] = _absUrl((u['icon_path'] ?? '').toString());
          m['user'] = u;
        }

        // サムネは thumbnail 最優先、なければ候補を順に
        final thumb = (m['thumbnail'] ??
                       m['thumbnail_path'] ??
                       m['imageUrl'] ??
                       m['image_url'] ??
                       m['img'] ??
                       m['image_path'] ??
                       '') as String?;
        m['__thumb__'] = _absUrl(thumb ?? '');
        return m;
      }).toList();

      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'タイムアウトしました（サーバが応答しません）';
        _loading = false;
        _items = [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '通信エラー: $e';
        _loading = false;
        _items = [];
      });
    }
  }

  // ---- HomePage と同じ思想のURL正規化 ----
  String _absUrl(String? input) {
    if (input == null || input.isEmpty) return '';
    // すでに http(s)
    if (input.startsWith('http://') || input.startsWith('https://')) {
      final u = Uri.parse(input);
      final fixedHost = (u.host == 'localhost') ? u.replace(host: '127.0.0.1') : u;
      return fixedHost.replace(path: _normalizePublicPath(fixedHost.path)).toString();
    }
    // 相対
    String path = input.startsWith('/') ? input : '/$input';
    path = _normalizePublicPath(path);
    return '${_normalizedBase.toString()}$path';
  }

  /// /img/uploads → /uploads、/icons → /img/icons
  String _normalizePublicPath(String path) {
    var p = path;
    p = p.replaceFirst(RegExp(r'^//+'), '/');
    p = p.replaceFirst(RegExp(r'^/img/+img/'), '/img/');
    p = p.replaceFirst('/img//uploads/', '/img/uploads/');

    if (p.startsWith('/img/uploads/')) {
      p = p.replaceFirst('/img/uploads/', '/uploads/');
    }
    if (p.startsWith('/icons/')) {
      p = '/img$p'; // → /img/icons/...
    }
    p = p.replaceAll(RegExp(r'/{2,}'), '/');
    return p;
  }

  Future<void> _reload() async => _fetchLikes();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('いいね一覧'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? ListView(
                  children: [
                    const SizedBox(height: 60),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(_error, textAlign: TextAlign.center),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: _reload,
                            icon: const Icon(Icons.refresh),
                            label: const Text('再読み込み'),
                          ),
                        ],
                      ),
                    ),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _reload,
                  child: _items.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 60),
                            Center(child: Text('まだ「いいね」した投稿がありません')),
                          ],
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _items.length,
                          itemBuilder: (context, index) {
                            final p = Map<String, dynamic>.from(_items[index]);
                            final user = (p['user'] is Map)
                                ? Map<String, dynamic>.from(p['user'] as Map)
                                : const <String, dynamic>{};

                            final id    = (p['id'] as num).toInt();
                            final title = (p['title'] ?? '').toString();
                            final name  = (user['name'] ?? 'User').toString();

                            final imgUrl = (p['__thumb__'] as String?) ?? '';
                            final likes  = ((p['like_count'] ?? p['likes'] ?? 0) as num).toInt();

                            // いいね一覧は自分が「いいね」済みなので true
                            return PortfolioCard(
                              portfolioId: id,
                              apiBaseUrl: widget.apiBaseUrl,
                              username: name,
                              title: title,
                              imageUrl: imgUrl.isEmpty ? 'https://picsum.photos/400/250' : imgUrl,
                              likes: likes,
                              initiallyLiked: true,
                              initiallyFollowed: false,
                            );
                          },
                        ),
                ),
    );
  }
}
