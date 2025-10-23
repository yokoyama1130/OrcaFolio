import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../pages/profile_page.dart';
import 'package:http/http.dart' as http;

import '../widgets/portfolio_card.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({
    super.key,
    this.apiBaseUrl = 'http://localhost:8765', // 実機は http://<MacのIP>:8765
  });

  final String apiBaseUrl;

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  List<Map<String, dynamic>> _portfolios = [];
  List<Map<String, dynamic>> _users = [];

  bool _loading = false;
  String _error = '';

  // ===== URL補正（localhost→127、/img/img/uploads潰し等） =====
  String _absUrl(String? input, {String fallback = ''}) {
    if (input == null || input.isEmpty) return fallback;
    final trimmed = input.trim();

    // 既に http(s)
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final u = Uri.parse(trimmed);
      final fixed = (u.host == 'localhost') ? u.replace(host: '127.0.0.1') : u;
      return fixed.replace(path: _normalizeUploadsPath(fixed.path)).toString();
    }

    // 相対
    final base = Uri.parse(widget.apiBaseUrl.replaceAll(RegExp(r'/$'), ''));
    final b = base.host == 'localhost' ? base.replace(host: '127.0.0.1') : base;

    String path = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    path = _normalizeUploadsPath(path);
    return '${b.toString()}$path';
  }

  String _normalizeUploadsPath(String path) {
    var p = path;
    p = p.replaceFirst(RegExp(r'^//+'), '/');
    // 本番は webroot/uploads/, webroot/img/icons/ などを想定
    // 画像アップロードの歴史的ゴミ掃除:
    p = p.replaceFirst('/img//uploads/', '/img/uploads/');
    p = p.replaceFirst(RegExp(r'^/img/+img/'), '/img/');
    return p;
  }

  // ===== API =====
  Future<void> _runSearch(String keyword) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      setState(() {
        _loading = true;
        _error = '';
      });

      final base = widget.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
      final uriBase = Uri.parse(base);
      final apiHostFixed =
          uriBase.host == 'localhost' ? uriBase.replace(host: '127.0.0.1') : uriBase;
      final root = apiHostFixed.toString();

      final qs = {'q': keyword};

      final portfoliosUri = Uri.parse('$root/api/portfolios/search.json')
          .replace(queryParameters: qs);
      final usersUri =
          Uri.parse('$root/api/users/search.json').replace(queryParameters: qs);

      try {
        final resP = await http.get(portfoliosUri).timeout(const Duration(seconds: 20));
        final resU = await http.get(usersUri).timeout(const Duration(seconds: 20));

        if (resP.statusCode != 200) {
          throw Exception('Portfolios ${resP.statusCode} ${resP.body}');
        }
        if (resU.statusCode != 200) {
          throw Exception('Users ${resU.statusCode} ${resU.body}');
        }

        final mp = json.decode(resP.body) as Map<String, dynamic>;
        final mu = json.decode(resU.body) as Map<String, dynamic>;

        final List itemsP = (mp['items'] ?? mp['portfolios'] ?? []) as List;
        final List itemsU = (mu['items'] ?? mu['users'] ?? []) as List;

        final portfolios = itemsP
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        final users = itemsU
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();

        setState(() {
          _portfolios = portfolios;
          _users = users;
        });
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
      } finally {
        if (mounted) {
          setState(() {
            _loading = false;
          });
        }
      }
    });
  }

  @override
  void initState() {
    super.initState();
    // 初回：空検索で最新を取得
    _runSearch('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabs = TabController(length: 2, vsync: this);

    return Scaffold(
      appBar: AppBar(
        title: const Text('検索'),
        centerTitle: true,
        bottom: TabBar(
          controller: tabs,
          tabs: const [
            Tab(text: '投稿'),
            Tab(text: 'ユーザー'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _controller,
              onChanged: _runSearch,
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
                          _runSearch('');
                        },
                      )
                    : null,
              ),
            ),
          ),
          if (_loading) const LinearProgressIndicator(minHeight: 2),
          if (_error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text('検索に失敗しました:\n$_error',
                  style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: TabBarView(
              controller: tabs,
              children: [
                // ---- 投稿 ----
                _portfolios.isEmpty
                    ? const Center(child: Text('投稿が見つかりません'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: _portfolios.length,
                        itemBuilder: (context, i) {
                          final p = Map<String, dynamic>.from(_portfolios[i]);
                          final Map<String, dynamic> user = (p['user'] is Map)
                              ? Map<String, dynamic>.from(p['user'] as Map)
                              : const <String, dynamic>{};

                          final id = ((p['id'] ?? p['portfolio_id']) as num).toInt();
                          final title = (p['title'] ?? '') as String;
                          final likes =
                              ((p['like_count'] ?? p['likes'] ?? 0) as num).toInt();
                          final liked = (p['liked_by_me'] ?? false) as bool;

                          final rawImg = (p['thumbnail'] ??
                                  p['imageUrl'] ??
                                  p['image_url'] ??
                                  p['img']) as String?;
                          final imgUrl = _absUrl(rawImg,
                              fallback: 'https://picsum.photos/400/250');

                          return PortfolioCard(
                            portfolioId: id,
                            apiBaseUrl: widget.apiBaseUrl,
                            username: (user['name'] ?? 'User') as String,
                            title: title,
                            imageUrl: imgUrl,
                            likes: likes,
                            initiallyLiked: liked,
                            initiallyFollowed: false,
                          );
                        },
                      ),

                // ---- ユーザー ----
                _users.isEmpty
                    ? const Center(child: Text('ユーザーが見つかりません'))
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        itemCount: _users.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final u = Map<String, dynamic>.from(_users[i]);
                          final iconRaw =
                              (u['icon_url'] ?? u['icon_path'] ?? '') as String;
                          // icon_path が 'icons/xxx.png' の場合は '/img/icons/xxx.png' にする
                          final iconPath = iconRaw.startsWith('icons/')
                              ? '/img/$iconRaw'
                              : iconRaw;
                          final iconUrl =
                              _absUrl(iconPath, fallback: 'https://picsum.photos/100');
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundImage: NetworkImage(iconUrl),
                            ),
                            title: Text((u['name'] ?? 'User') as String),
                            subtitle: (u['bio'] != null) ? Text(u['bio'] as String) : null,
                            onTap: () {
                              // Users APIのレスポンスからIDを取り出して遷移
                              final userId = (u['id'] as num).toInt();

                              final base = widget.apiBaseUrl.replaceFirst('localhost', '127.0.0.1');

                              // 直接ページをpush（Named Routeが無くても動く）
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ProfilePage(
                                    apiBaseUrl: base, // ← あなたのSearchPageにあるbaseを使う
                                    viewUserId: userId,            // ← 他人プロフィールとして表示
                                    isLoggedIn: false,             // （自分プロフィールでなく公開表示）
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
