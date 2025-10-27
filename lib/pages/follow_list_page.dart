import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// プロフィールへ飛ぶ用
import 'profile_page.dart';

class FollowListPage extends StatefulWidget {
  /// "following" or "followers"
  final String type;
  final int userId;            // 取得対象ユーザーID（例：プロフィールの人）
  final String apiBaseUrl;     // 例: http://127.0.0.1:8765
  final String jwtToken;       // Bearer トークン

  const FollowListPage({
    super.key,
    required this.type,
    required this.userId,
    required this.apiBaseUrl,
    required this.jwtToken,
  });

  @override
  State<FollowListPage> createState() => _FollowListPageState();
}

class _FollowListPageState extends State<FollowListPage> {
  bool _loading = true;
  String _error = '';
  List<_FollowUser> _items = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final endpoint = widget.type == 'following'
        ? '/api/follows/followings/${widget.userId}.json'
        : '/api/follows/followers/${widget.userId}.json';

    final url = Uri.parse('${_trimSlash(_fixLocalhost(widget.apiBaseUrl))}$endpoint');

    try {
      final res = await http
          .get(
            url,
            headers: {
              'Authorization': 'Bearer ${widget.jwtToken}',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 20));

      // デバッグログ（開発時のみ適宜コメントアウトOK）
      final previewLen = res.body.length < 200 ? res.body.length : 200;
      debugPrint('[FollowList] GET $url -> ${res.statusCode}');
      debugPrint('[FollowList] content-type: ${res.headers['content-type']}');
      debugPrint('[FollowList] body(head): "${res.body.substring(0, previewLen)}"');

      if (!mounted) return;

      if (res.statusCode != 200) {
        setState(() {
          _error = 'サーバーエラー (${res.statusCode})';
          _loading = false;
        });
        return;
      }

      // 空ボディ対策
      if (res.body.isEmpty) {
        setState(() {
          _error = '空のレスポンスが返りました（body is empty）';
          _loading = false;
        });
        return;
      }

      // JSON以外（HTMLなど）対策
      final contentType = (res.headers['content-type'] ?? '').toLowerCase();
      if (!contentType.contains('application/json')) {
        setState(() {
          _error = 'JSON以外のレスポンスです: $contentType';
          _loading = false;
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
        });
        return;
      }

      final key = widget.type == 'following' ? 'followings' : 'followers';
      final raw = body[key];
      if (raw is! List) {
        setState(() {
          _error = '予期しないレスポンス形式です（"$key" が配列ではありません）';
          _loading = false;
        });
        return;
      }

      // APIのレスポンスを統一モデルへマッピング（安全キャスト）
      final items = <_FollowUser>[];
      for (final e in raw) {
        if (e is! Map) continue;
        final row = e.cast<String, dynamic>();

        final userMapAny = row['user'];
        if (userMapAny is! Map) continue;
        final userMap = userMapAny.cast<String, dynamic>();

        final id = userMap['id'];
        final name = userMap['name'];
        final iconPath = userMap['icon_path'];

        final apiSaysFollowed = (row['is_followed_by_me'] is bool)
            ? row['is_followed_by_me'] as bool
            : null;

        items.add(
          _FollowUser(
            userId: (id is int) ? id : int.tryParse('$id') ?? 0,
            username: (name is String) ? name : 'unknown',
            avatarUrl: _absUrl(
              (iconPath is String) ? iconPath : '',
              _fixLocalhost(widget.apiBaseUrl),
            ),
            // APIが返した値があればそれを使う、無ければ following 画面は true 仮定
            isFollowed: apiSaysFollowed ?? (widget.type == 'following'),
          ),
        );
      }

      setState(() {
        _items = items;
        _loading = false;
      });
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        _error = 'タイムアウトしました（サーバが応答しません）';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '通信エラー: $e';
        _loading = false;
      });
    }
  }

  Future<void> _onRefresh() async {
    await _fetch();
  }

  void _toggleFollowLocal(int index) {
    // まだトグルAPIを作っていない想定。UIだけ反映（後でAPIと接続）
    setState(() {
      _items[index] = _items[index].copyWith(
        isFollowed: !_items[index].isFollowed,
      );
    });
  }

  void _goProfile(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          // 他人のプロフィールとして開く
          viewUserId: userId,
          apiBaseUrl: _fixLocalhost(widget.apiBaseUrl),
          // トークンは null 許可の実装なら渡さなくてもOK。
          // ここでは持っているなら渡す。
          token: widget.jwtToken.isNotEmpty ? widget.jwtToken : null,
          // isLoggedIn はトークン有無で便宜上の表示切り替えに使える
          isLoggedIn: widget.jwtToken.isNotEmpty,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.type == 'following' ? 'フォロー中' : 'フォロワー';

    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
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
                        ElevatedButton(
                          onPressed: _fetch,
                          child: const Text('再読み込み'),
                        ),
                      ],
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _onRefresh,
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _items.length,
                    separatorBuilder: (_, __) => const Divider(height: 0),
                    itemBuilder: (context, index) {
                      final user = _items[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: user.avatarUrl.isNotEmpty
                              ? NetworkImage(user.avatarUrl)
                              : null,
                          radius: 25,
                          child: user.avatarUrl.isEmpty
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text('@${user.username}'),
                        trailing: ElevatedButton(
                          onPressed: () => _toggleFollowLocal(index),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: user.isFollowed
                                ? Colors.grey.shade300
                                : Colors.blueAccent,
                            foregroundColor: user.isFollowed
                                ? Colors.black87
                                : Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 6,
                            ),
                            textStyle: const TextStyle(fontSize: 13),
                          ),
                          child: Text(user.isFollowed ? 'フォロー中' : 'フォロー'),
                        ),
                        onTap: () => _goProfile(user.userId),
                      );
                    },
                  ),
                ),
    );
  }
}

/// 表示用のシンプルなモデル
class _FollowUser {
  final int userId;
  final String username;
  final String avatarUrl;
  final bool isFollowed;

  _FollowUser({
    required this.userId,
    required this.username,
    required this.avatarUrl,
    required this.isFollowed,
  });

  _FollowUser copyWith({
    int? userId,
    String? username,
    String? avatarUrl,
    bool? isFollowed,
  }) {
    return _FollowUser(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      isFollowed: isFollowed ?? this.isFollowed,
    );
  }
}

/// 相対パスを絶対URLへ
String _absUrl(String? path, String base) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('http://') || path.startsWith('https://')) return path;

  final fixedBase = _fixLocalhost(base);
  return '${_trimSlash(fixedBase)}$path';
}

String _trimSlash(String s) => s.endsWith('/') ? s.substring(0, s.length - 1) : s;

/// 実機でも安定させるため localhost → 127.0.0.1 に寄せる
String _fixLocalhost(String base) {
  try {
    final uri = Uri.parse(base);
    if (uri.host == 'localhost') {
      return uri.replace(host: '127.0.0.1').toString();
    }
    return base;
  } catch (_) {
    return base;
  }
}
