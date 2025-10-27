// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Pages
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/add_portfolio_page.dart';
import 'pages/portfolio_detail_page.dart';
import 'pages/dm_list_page.dart';
import 'pages/search_page.dart';
import 'pages/follow_list_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CalcraftApp());
}

class CalcraftApp extends StatefulWidget {
  const CalcraftApp({super.key});

  @override
  State<CalcraftApp> createState() => _CalcraftAppState();
}

/// FollowList に渡すナビゲーション引数
class FollowListArgs {
  final String type; // 'following' or 'followers'
  final int userId;
  const FollowListArgs({required this.type, required this.userId});
}

class _CalcraftAppState extends State<CalcraftApp> {
  /// 💡 実機デバッグ時は Mac のローカル IP に置き換えてください。
  /// 例) 'http://192.168.1.15:8765'
  static const String kApiBaseUrl = 'http://127.0.0.1:8765';

  final _secure = const FlutterSecureStorage();

  int _selectedIndex = 0;
  String? _jwt;
  bool _booting = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// 起動時に JWT を読み込む
  Future<void> _bootstrap() async {
    // どちらかに保存している想定。優先順: jwt -> auth_token
    final jwt = await _secure.read(key: 'jwt') ??
        await _secure.read(key: 'auth_token');

    if (!mounted) return;
    setState(() {
      _jwt = jwt;
      _booting = false;
    });
  }

  /// ほかの画面からトークン更新したいとき用
  Future<void> refreshToken() async {
    final jwt = await _secure.read(key: 'jwt') ??
        await _secure.read(key: 'auth_token');
    if (!mounted) return;
    setState(() => _jwt = jwt);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  List<Widget> _buildPages() {
    final loggedIn = (_jwt != null && _jwt!.isNotEmpty);
    final token = _jwt ?? '';

    return [
      // Home はダミーでもOK。API使うようにしているなら apiBaseUrl を渡しても良い
      const HomePage(),

      // 🔎 検索ページにもベースURLを明示
      SearchPage(apiBaseUrl: kApiBaseUrl),

      // ➕ 投稿ページ（投稿成功時は Home タブへ戻す）
      AddPortfolioPage(
        apiBaseUrl: kApiBaseUrl,
        token: token,
        onPosted: () => setState(() => _selectedIndex = 0),
      ),

      // 💬 DM一覧は “要JWT”。必ず token を渡す
      DMListPage(
        apiBaseUrl: kApiBaseUrl,
        token: token,
        // （任意）トークン切れ時にログイン導線を出したい場合はコールバック用意して呼ぶ
        // onTokenExpired: () { ... },
      ),

      // 👤 プロフィール（自分／他人共通。自分用は isLoggedIn=true で表示切替）
      ProfilePage(
        isLoggedIn: loggedIn,
        apiBaseUrl: kApiBaseUrl,
        token: _jwt, // null でも動く実装ならそのまま
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final pages = _buildPages();

    return MaterialApp(
      title: 'Calcraft SNS Portfolio',
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // 画面遷移（必要に応じて追加）
      routes: {
        '/detail': (context) => const PortfolioDetailPage(),

        // ✅ 引数を ModalRoute.settings.arguments から受け取る
        '/followList': (context) {
          final args = ModalRoute.of(context)?.settings.arguments as FollowListArgs?;
          if (args == null) {
            // 引数が来てない場合のフォールバック（開発時に気付きやすくする）
            return const Scaffold(
              body: Center(child: Text('FollowList: 引数 FollowListArgs が必要です')),
            );
          }
          return FollowListPage(
            type: args.type,                 // 'following' or 'followers'
            userId: args.userId,            // 対象ユーザーID（プロフィールの人など）
            apiBaseUrl: _CalcraftAppState.kApiBaseUrl,
            jwtToken: _jwt ?? '',
          );
        },
        '/home': (_) => const HomePage(),
      },
      home: Scaffold(
        body: _booting
            ? const Center(child: CircularProgressIndicator())
            : pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
            NavigationDestination(icon: Icon(Icons.search_outlined), label: 'Search'),
            NavigationDestination(icon: Icon(Icons.add_box_outlined), label: 'Add'),
            NavigationDestination(icon: Icon(Icons.message_outlined), label: 'DM'),
            NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
