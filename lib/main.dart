// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/add_portfolio_page.dart';
import 'pages/portfolio_detail_page.dart';
import 'pages/dm_list_page.dart';
import 'pages/search_page.dart';
import 'pages/follow_list_page.dart';

void main() {
  runApp(const CalcraftApp());
}

class CalcraftApp extends StatefulWidget {
  const CalcraftApp({super.key});

  @override
  State<CalcraftApp> createState() => _CalcraftAppState();
}

class _CalcraftAppState extends State<CalcraftApp> {
  // 実機デバッグ時は Mac のローカル IP に置き換えてね（例: 'http://192.168.1.10:8765'）
  static const String kApiBaseUrl = 'http://localhost:8765';

  final _storage = const FlutterSecureStorage();

  int _selectedIndex = 0;
  String? _jwt;               // 起動時に SecureStorage から読み込み
  bool _booting = true;       // 起動中インジケータ用

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final token = await _storage.read(key: 'jwt');
    if (!mounted) return;
    setState(() {
      _jwt = token;
      _booting = false;
    });
  }

  // 必要に応じて子画面から呼べるようにした再読込ヘルパ（使わなくてもOK）
  Future<void> refreshToken() async {
    final token = await _storage.read(key: 'jwt');
    if (!mounted) return;
    setState(() => _jwt = token);
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  List<Widget> _buildPages() {
    final loggedIn = (_jwt != null && _jwt!.isNotEmpty);

    return [
      const HomePage(),
      const SearchPage(),
      // ← 必須引数を渡す。const は付けない
      AddPortfolioPage(
        apiBaseUrl: kApiBaseUrl,
        token: _jwt ?? '',
      ),
      const DMListPage(),
      // ← Profile へも必須引数を渡す
      ProfilePage(
        isLoggedIn: loggedIn,
        apiBaseUrl: kApiBaseUrl,
        token: _jwt, // null でもOK（未ログイン扱いになる）
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
      routes: {
        '/detail': (context) => const PortfolioDetailPage(),
        '/followList': (context) => const FollowListPage(type: 'following'),
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
