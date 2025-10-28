import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

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

  @override
  void initState() {
    super.initState();
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
        setState(() {
          _error = 'ログインが必要です。';
          _loading = false;
          _items = [];
        });
        return;
      }

      final url = Uri.parse('${_trimSlash(widget.apiBaseUrl)}/api/likes/favorites.json');

      final res = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer $token',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));

      // ステータスコードチェック
      if (res.statusCode != 200) {
        setState(() {
          _error = 'サーバーエラー (${res.statusCode})';
          _loading = false;
          _items = [];
        });
        return;
      }

      // 空ボディ対策
      if (res.body.isEmpty) {
        setState(() {
          _error = '空のレスポンスが返りました（body is empty）';
          _loading = false;
          _items = [];
        });
        return;
      }

      // Content-Typeチェック（HTML混入時のガード）
      final ctype = (res.headers['content-type'] ?? '').toLowerCase();
      if (!ctype.contains('application/json')) {
        setState(() {
          _error = 'JSON以外のレスポンスです: $ctype';
          _loading = false;
          _items = [];
        });
        return;
      }

      // JSONパース
      Map<String, dynamic> body;
      try {
        body = jsonDecode(res.body) as Map<String, dynamic>;
      } on FormatException catch (fe) {
        setState(() {
          _error = 'JSON解析エラー: ${fe.message}';
          _loading = false;
          _items = [];
        });
        return;
      }

      final raw = body['portfolios'];
      if (raw is! List) {
        setState(() {
          _error = '予期しないレスポンス形式（"portfolios" が配列ではありません）';
          _loading = false;
          _items = [];
        });
        return;
      }

      final items = raw.cast<Map<String, dynamic>>();

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('いいね一覧'), centerTitle: true),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _fetchLikes,
                          icon: const Icon(Icons.refresh),
                          label: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _fetchLikes,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, i) {
                      final p = _items[i];

                      final title = (p['title'] ?? '(タイトルなし)').toString();
                      final likeCount = (p['like_count'] ?? 0).toString();

                      final user = (p['user'] as Map?) ?? const {};
                      final name = (user['name'] ?? '(不明ユーザー)').toString();
                      final icon = (user['icon_path'] ?? '').toString();

                      return ListTile(
                        leading: CircleAvatar(
                          radius: 24,
                          backgroundImage: icon.isNotEmpty ? NetworkImage(_absUrl(icon, widget.apiBaseUrl)) : null,
                          child: icon.isEmpty ? const Icon(Icons.person) : null,
                        ),
                        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('@$name', maxLines: 1, overflow: TextOverflow.ellipsis),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.favorite, color: Colors.pinkAccent, size: 18),
                            const SizedBox(width: 4),
                            Text(likeCount),
                          ],
                        ),
                        onTap: () {
                          // 投稿詳細へ（routesに /detail がある想定）
                          final id = p['id'];
                          if (id != null) {
                            Navigator.pushNamed(context, '/detail', arguments: id);
                          }
                        },
                      );
                    },
                  ),
                ),
    );
  }
}

// ---- helpers ----
String _trimSlash(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;

/// 相対パスを絶対URLに補正（/icons → /img/icons などの軽い互換を考慮）
String _absUrl(String path, String base) {
  final raw = path.trim();
  if (raw.startsWith('http://') || raw.startsWith('https://')) return raw;

  // /icons/* → /img/icons/* に寄せる（サーバ実体が /img/icons のとき）
  String p = raw.startsWith('/') ? raw : '/$raw';
  if (p.startsWith('/icons/')) {
    p = '/img$p'; // => /img/icons/...
  }
  // /img/uploads → /uploads 互換（必要なら）
  if (p.startsWith('/img/uploads/')) {
    p = p.replaceFirst('/img', ''); // => /uploads/...
  }

  final b = _trimSlash(base);
  return '$b$p';
}
