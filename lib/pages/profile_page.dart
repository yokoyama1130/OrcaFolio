import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../widgets/portfolio_card.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'follow_list_page.dart';
import 'login_page.dart';
import 'signup_page.dart';

import '../data/api_client.dart';
import '../data/models.dart'; // ProfileResponse / ProfileUser / PortfolioItem

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.isLoggedIn = false,
    this.apiBaseUrl = 'http://localhost:8765', // 実機は http://<MacのIP>:8765
    this.token,            // 親から明示的に渡す場合
    this.viewUserId,       // 他人のプロフィールを閲覧するとき
  });

  final bool isLoggedIn;
  final String apiBaseUrl;
  final String? token;
  final int? viewUserId;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _storage = FlutterSecureStorage();

  String? _token;                   // 実際に使うJWT（引数 or 保存）
  late ApiClient _api;              // _tokenが決まったら初期化
  Future<ProfileResponse>? _future; // API呼び出しFuture

  // ==== 相対パスを絶対URLに直すヘルパ ====
  // ==== 相対/絶対どちらでも安全に正規化して 127.0.0.1 に向ける ====
  String _absUrl(String? input, {String fallback = 'https://picsum.photos/400/200'}) {
    if (input == null || input.isEmpty) return fallback;
    String raw = input.trim();

    // --- 絶対URLなら localhost→127.0.0.1 のみ置換して返す ---
    Uri? asUri;
    try { asUri = Uri.parse(raw); } catch (_) {}
    if (asUri != null && asUri.hasScheme && (asUri.scheme == 'http' || asUri.scheme == 'https')) {
      if (asUri.host == 'localhost') {
        return asUri.replace(host: '127.0.0.1').toString();
      }
      // 念のため /img/img/uploads を潰す
      final fixed = asUri.replace(
        path: _normalizeUploadsPath(asUri.path),
      ).toString();
      return fixed;
    }

    // --- 相対パス（例: /img/uploads/.. or /uploads/.. or img/uploads/..）---
    // 1) ベースURLも localhost → 127.0.0.1 に正規化
    final baseUri = Uri.parse(widget.apiBaseUrl.replaceAll(RegExp(r'/$'), ''));
    final normalizedBase = baseUri.host == 'localhost'
        ? baseUri.replace(host: '127.0.0.1')
        : baseUri;

    // 2) 先頭スラッシュを必ず付ける
    String path = raw.startsWith('/') ? raw : '/$raw';

    // 3) /uploads → /img/uploads に寄せ、二重 /img を除去
    path = _normalizeUploadsPath(path);

    return '${normalizedBase.toString()}$path';
  }

  // /uploads → /img/uploads に寄せ、/img/img/uploads を /img/uploads に潰す
  String _normalizeUploadsPath(String path) {
    var p = path;

    // //uploads → /uploads などの二重スラッシュ軽減（先頭付近）
    p = p.replaceFirst(RegExp(r'^//+'), '/');

    // /uploads/... を /img/uploads/... に寄せる
    if (p.startsWith('/uploads/')) {
      p = '/img$p'; // → /img/uploads/...
    }

    // /img//uploads → /img/uploads に寄せる
    p = p.replaceFirst('/img//uploads/', '/img/uploads/');

    // /img/img/uploads → /img/uploads に寄せる（重複 /img を1つに）
    p = p.replaceFirst(RegExp(r'^/img/+img/'), '/img/');

    return p;
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// 起動時：tokenを用意して、必要ならロードを仕込む
  Future<void> _bootstrap() async {
    // 1) token 準備（引数優先 → secure storage）
    final t = widget.token ?? await _storage.read(key: 'jwt');
    _token = t;
    _api = ApiClient(baseUrl: widget.apiBaseUrl, token: _token);

    // 2) 読み込み条件：
    //    - 自分のプロフィール: token がある もしくは isLoggedIn == true
    //    - 他人のプロフィール: viewUserId がある（token不要）
    final shouldLoad =
        (_token != null && _token!.isNotEmpty) || widget.isLoggedIn || widget.viewUserId != null;

    if (shouldLoad) {
      _future = _load(); // await しない（FutureBuilder に渡す用）
      if (!mounted) return;
      setState(() {});   // 再描画だけ同期で
    }
  }

  /// プロフィール取得（自分 or 他人）
  Future<ProfileResponse> _load() {
    if (widget.viewUserId != null) {
      return _api.fetchPublicProfile(widget.viewUserId!);
    } else {
      return _api.fetchMyProfile();
    }
  }

  /// Pull-to-Refresh
  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    try {
      await _future;
    } catch (_) {
      // 例外表示はビルド内のエラーハンドリングに任せる
    }
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    // “ログイン扱い”の判定：tokenがある or isLoggedIn or viewUserIdがある
    final logged = (_token != null && _token!.isNotEmpty) || widget.isLoggedIn || widget.viewUserId != null;

    // _bootstrap完了前（shouldLoad=true だが _future まだ）のローダー
    if (_future == null && logged) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 自分のプロフィールで token も isLoggedIn も false、かつ viewUserId も無い → 未ログインUI
    if (!logged) {
      return _buildLoggedOut(context);
    }

    return FutureBuilder<ProfileResponse>(
      future: _future,
      builder: (context, snap) {
        // ローディング
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        // エラー
        if (snap.hasError) {
          final looksUnauthorized =
              (_token == null || (_token?.isEmpty ?? true)) && widget.viewUserId == null;
          return Scaffold(
            appBar: AppBar(title: const Text('My Profile')),
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 12),
                  Text('エラーが発生しました:\n${snap.error}', textAlign: TextAlign.center),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _reload,
                      icon: const Icon(Icons.refresh),
                      label: const Text('再読み込み'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (looksUnauthorized)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // LoginPageは token を返して閉じる（Navigator.pop(token)）
                          final token = await Navigator.push<String?>(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
                          if (!mounted) return;
                          if (token != null && token.isNotEmpty) {
                            await _storage.write(key: 'jwt', value: token);
                            setState(() {
                              _token = token;
                              _api = ApiClient(baseUrl: widget.apiBaseUrl, token: _token);
                              _future = _load();
                            });
                          }
                        },
                        icon: const Icon(Icons.login),
                        label: const Text('ログインへ'),
                      ),
                    ),
                ],
              ),
            ),
          );
        }

        // データなし（稀）→ フォールバック
        if (!snap.hasData) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Profile')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('表示できるプロフィールがありません。'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _reload,
                    icon: const Icon(Icons.refresh),
                    label: const Text('再読み込み'),
                  ),
                ],
              ),
            ),
          );
        }

        final data = snap.data!;
        return _buildLoggedIn(context, data);
      },
    );
  }

  // ------------------ 未ログインUI ------------------
  Widget _buildLoggedOut(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Profile')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 12),
              const Text('プロフィールを表示するにはログインしてください。', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final token = await Navigator.push<String?>(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                    if (!mounted) return;
                    if (token != null && token.isNotEmpty) {
                      await _storage.write(key: 'jwt', value: token);
                      setState(() {
                        _token = token;
                        _api = ApiClient(baseUrl: widget.apiBaseUrl, token: _token);
                        _future = _load();
                      });
                    }
                  },
                  icon: const Icon(Icons.login),
                  label: const Text('ログイン'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SignUpPage()));
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('新規登録'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------ ログイン済みUI ------------------
  Widget _buildLoggedIn(BuildContext context, ProfileResponse res) {
    final user = res.user;
    final followingCount = res.followings;
    final followerCount  = res.followers;

    return Scaffold(
      appBar: AppBar(
        title: Text(user.name.isEmpty ? 'Profile' : user.name),
        actions: [
          // 設定
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsPage()),
              );
              if (!mounted) return;
              if (result == 'logged_out') {
                await _storage.delete(key: 'jwt');
                setState(() {
                  _token = null;
                  _api   = ApiClient(baseUrl: widget.apiBaseUrl, token: _token);
                  _future = null;
                });
                messenger.showSnackBar(const SnackBar(content: Text('ログアウトしました')));
              }
            },
          ),
          // プロフィール編集
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'プロフィール編集',
            onPressed: () async {
              final updated = await Navigator.push<ProfileUser?>(
                context,
                MaterialPageRoute(
                  builder: (_) => EditProfilePage(
                    apiBaseUrl: widget.apiBaseUrl,
                    token: _token,                // JWT
                    initialName: user.name,
                    initialBio: user.bio,
                    initialIconUrl: user.iconUrl,
                  ),
                ),
              );
              if (updated != null) {
                await _reload(); // サーバ値を再取得して整合させる
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            // プロフアイコンも相対→絶対に補正
            CircleAvatar(
              radius: 50,
              backgroundImage: NetworkImage(
                _absUrl(user.iconUrl, fallback: 'https://picsum.photos/200'),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.name.isEmpty ? 'ユーザー' : user.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            if (user.bio.isNotEmpty) Text(user.bio, textAlign: TextAlign.center),
            const SizedBox(height: 16),

            // フォロー・フォロワー
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFollowStat('フォロー', followingCount, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FollowListPage(type: 'following')),
                  );
                }),
                const SizedBox(width: 24),
                _buildFollowStat('フォロワー', followerCount, () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FollowListPage(type: 'followers')),
                  );
                }),
              ],
            ),
            const Divider(height: 32),

            const Text('My Portfolios', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            if (res.portfolios.isEmpty)
              const Text('まだポートフォリオがありません。', textAlign: TextAlign.center)
            else
              ...res.portfolios.map(
                (p) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PortfolioCard(
                    username: user.name,
                    title: p.title,
                    // ← ここで絶対URLに補正してから渡す！
                    imageUrl: _absUrl(p.imageUrl),
                    likes: p.likes,
                    initiallyLiked: false,
                    initiallyFollowed: false,
                  ),
                ),
              ),
          ],
        ),
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
            Text('$count', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
