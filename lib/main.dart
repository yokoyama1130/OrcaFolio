import 'package:flutter/material.dart';
import 'pages/home_page.dart';
import 'pages/profile_page.dart';
import 'pages/add_portfolio_page.dart';
import 'pages/portfolio_detail_page.dart';
import 'pages/dm_list_page.dart';
import 'pages/search_page.dart';

void main() {
  runApp(const CalcraftApp());
}

class CalcraftApp extends StatefulWidget {
  const CalcraftApp({super.key});

  @override
  State<CalcraftApp> createState() => _CalcraftAppState();
}

class _CalcraftAppState extends State<CalcraftApp> {
  int _selectedIndex = 0;
  final List<Widget> _pages = [
    const HomePage(),
    const SearchPage(),
    const AddPortfolioPage(),
    const DMListPage(),
    const ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calcraft SNS Portfolio',
      theme: ThemeData(
        fontFamily: 'Inter',
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // ✅ ルート設定を追加
      routes: {
        '/detail': (context) => const PortfolioDetailPage(),
      },
      home: Scaffold(
        body: _pages[_selectedIndex],
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
