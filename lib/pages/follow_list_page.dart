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

  // 連打ガード：いまトグル中の userId セット
  final Set<int> _mutating = {};

  // 低ノイズなスピナー表示（350ms 以上かかったときだけ出す）
  final Set<int> _spinVisible = {};                // 表示対象の userId
  final Map<int, Timer> _spinDelayTimers = {};     // 遅延表示タイマー

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    // 画面離脱時にタイマーを必ず停止
    for (final t in _spinDelayTimers.values) {
      t.cancel();
    }
    _spinDelayTimers.clear();
    super.dispose();
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

      if (!mounted) return;

      if (res.statusCode != 200) {
        setState(() {
          _error = 'サーバーエラー (${res.statusCode})';
          _loading = false;
        });
        return;
      }
      if (res.body.isEmpty) {
        setState(() {
          _error = '空のレスポンスが返りました（body is empty）';
          _loading = false;
        });
        return;
      }

      final contentType = (res.headers['content-type'] ?? '').toLowerCase();
      if (!contentType.contains('application/json')) {
        setState(() {
          _error = 'JSON以外のレスポンスです: $contentType';
          _loading = false;
        });
        return;
      }

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
            // APIが返した値があればそれ、無ければ following 画面は true 仮定
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

  Future<void> _onRefresh() async => _fetch();

  /// サーバーにフォロー/解除をトグル依頼（楽観更新＋失敗時ロールバック）
  Future<void> _toggleFollowServer(int index) async {
    final user = _items[index];
    if (_mutating.contains(user.userId)) return; // 連打ガード
    _mutating.add(user.userId);

    // 楽観更新（UIは即変わる）
    final prev = user.isFollowed;
    setState(() {
      _items[index] = user.copyWith(isFollowed: !prev);
    });

    // --- 350ms 遅延してからスピナー表示（それまでに終われば出さない） ---
    _spinDelayTimers[user.userId]?.cancel();
    _spinDelayTimers[user.userId] = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() {
        _spinVisible.add(user.userId);
      });
    });

    final url = Uri.parse(
      '${_trimSlash(_fixLocalhost(widget.apiBaseUrl))}/api/follows/toggle.json',
    );

    try {
      final res = await http
          .post(
            url,
            headers: {
              'Authorization': 'Bearer ${widget.jwtToken}',
              'Accept': 'application/json',
              'Content-Type': 'application/json',
            },
            body: jsonEncode({'target_user_id': user.userId}),
          )
          .timeout(const Duration(seconds: 8)); // 少し短めでもOK

      if (!mounted) return;

      if (res.statusCode == 401) {
        // 認証切れ等 → ロールバック
        setState(() {
          _items[index] = user.copyWith(isFollowed: prev);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ログインが必要です（401）')),
        );
        return;
      }
      if (res.statusCode != 200) {
        // エラー → ロールバック
        setState(() {
          _items[index] = user.copyWith(isFollowed: prev);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('フォロー更新に失敗しました（${res.statusCode}）')),
        );
        return;
      }

      // { success: true, following: bool } を想定
      bool ok = false;
      bool? nowFollowing;
      try {
        final map = jsonDecode(res.body) as Map<String, dynamic>;
        ok = (map['success'] == true);
        if (map.containsKey('following')) {
          nowFollowing = map['following'] as bool?;
        }
      } catch (_) {}

      if (!ok) {
        // 失敗 → ロールバック
        setState(() {
          _items[index] = user.copyWith(isFollowed: prev);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('フォロー更新に失敗しました')),
        );
        return;
      }

      // サーバー最終状態で上書き（任意）
      if (nowFollowing != null) {
        setState(() {
          _items[index] = user.copyWith(isFollowed: nowFollowing);
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      // タイムアウト → ロールバック
      setState(() {
        _items[index] = user.copyWith(isFollowed: prev);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('タイムアウトしました')),
      );
    } catch (e) {
      if (!mounted) return;
      // 例外 → ロールバック
      setState(() {
        _items[index] = user.copyWith(isFollowed: prev);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('通信エラー: $e')),
      );
    } finally {
      // スピナー遅延タイマー＆表示を必ず終了
      _spinDelayTimers[user.userId]?.cancel();
      _spinDelayTimers.remove(user.userId);
      if (mounted) {
        setState(() {
          _spinVisible.remove(user.userId);
        });
      }
      _mutating.remove(user.userId);
    }
  }

  void _goProfile(int userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ProfilePage(
          viewUserId: userId,                       // 他人プロフィールとして開く
          apiBaseUrl: _fixLocalhost(widget.apiBaseUrl),
          token: widget.jwtToken.isNotEmpty ? widget.jwtToken : null,
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
                      final busyVisual = _spinVisible.contains(user.userId); // ← 遅延表示のみ

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
                        trailing: _FollowButton(
                          isFollowing: user.isFollowed,
                          busy: busyVisual, // ← 350ms 以上のときだけ小スピナー
                          onPressed: () {
                            if (_mutating.contains(user.userId)) return; // 連打ガード
                            _toggleFollowServer(index);
                          },
                        ),
                        onTap: () => _goProfile(user.userId),
                      );
                    },
                  ),
                ),
    );
  }
}

/// ボタン：無効化はしない（色・ラベルは即時反映）。右に小スピナーを重ねる。
class _FollowButton extends StatelessWidget {
  final bool isFollowing;
  final bool busy;
  final VoidCallback onPressed;

  const _FollowButton({
    required this.isFollowing,
    required this.busy,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isFollowing ? Colors.grey.shade300 : Colors.blueAccent;
    final fg = isFollowing ? Colors.black87 : Colors.white;

    return ElevatedButton(
      onPressed: onPressed, // ← 無効化しない
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        textStyle: const TextStyle(fontSize: 13),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ラベルは常に表示（即時切替）
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 120),
            transitionBuilder: (child, anim) =>
                FadeTransition(opacity: anim, child: child),
            child: Text(
              isFollowing ? 'フォロー中' : 'フォロー',
              key: ValueKey(isFollowing),
            ),
          ),
          if (busy) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
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
  // 余分な // を吸収してから連結
  final p = '/${path.replaceFirst(RegExp(r"^/+"), "")}';
  return '${_trimSlash(fixedBase)}$p';
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
