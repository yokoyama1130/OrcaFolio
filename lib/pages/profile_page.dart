import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../widgets/portfolio_card.dart';
import 'settings_page.dart';
import 'edit_profile_page.dart';
import 'follow_list_page.dart';
import 'login_page.dart';
import 'signup_page.dart';
import '../data/api_client.dart';
import '../data/models.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    this.isLoggedIn = false,
    this.apiBaseUrl = 'http://localhost:8765', // 実機は http://<MacのIP>:8765
    this.token,
    this.viewUserId,
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

  String? _token;                     // 実際に使うトークン（引数 or 保存済み）
  late ApiClient _api;                // _token が決まってから初期化
  Future<ProfileResponse>? _future;   // API呼び出し

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// 起動時に token を用意して Future を仕込む
  Future<void> _bootstrap() async {
    // 1) トークン準備（非同期は setState の外で）
    var t = widget.token ?? await const FlutterSecureStorage().read(key: 'jwt');
    _token = t;
    _api = ApiClient(baseUrl: widget.apiBaseUrl, token: _token);

    // 2) Future をセット（await しない）
    if (widget.isLoggedIn || widget.viewUserId != null) {
      _future = _load(); // ← ここは代入だけ（同期）
      if (!mounted) return;
      setState(() {});   // ← 再描画のトリガーだけを同期で実行
    }
  }


  Future<ProfileResponse> _load() {
    if (widget.viewUserId != null) {
      return _api.fetchPublicProfile(widget.viewUserId!);
    } else {
      return _api.fetchMyProfile();
    }
  }

  Future<void> _reload() async {
    setState(() {
      _future = _load();
    });
    try {
      await _future;
    } catch (_) {}
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    // _bootstrap 完了前（_future 未設定）はローディング
    if (_future == null && (widget.isLoggedIn || widget.viewUserId != null)) {
      return Scaffold(
        appBar: AppBar(title: const Text('My Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // 自分のプロフィールを開くのに未ログイン、かつ他人ID指定もない場合は未ログインUI
    if (!(widget.isLoggedIn || widget.viewUserId != null)) {
      return _buildLoggedOut(context);
    }

    return FutureBuilder<ProfileResponse>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('My Profile')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snap.hasError) {
          // ← ここを「token の有無」ではなく、_token の有無で判定
          final looksUnauthorized = (_token == null || (_token?.isEmpty ?? true));
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
                          // ログインへ遷移（成功時に token を返すようにしておく）
                          final token = await Navigator.push<String?>(
                            context,
                            MaterialPageRoute(builder: (_) => const LoginPage()),
                          );
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
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
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
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage())),
          ),
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'プロフィール編集',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const EditProfilePage())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reload,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: (user.iconUrl != null && user.iconUrl!.isNotEmpty)
                  ? NetworkImage(user.iconUrl!)
                  : const NetworkImage('https://picsum.photos/200'),
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

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildFollowStat('フォロー', followingCount, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowListPage(type: 'following')));
                }),
                const SizedBox(width: 24),
                _buildFollowStat('フォロワー', followerCount, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const FollowListPage(type: 'followers')));
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
                    imageUrl: p.imageUrl ?? 'https://picsum.photos/400/200',
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
