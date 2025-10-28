// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'employer/employer_shell.dart';
import 'likes_page.dart'; // ← 新規追加

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _storage = FlutterSecureStorage();
  bool _loggingOut = false;

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    try {
      await _storage.delete(key: 'jwt');
      if (!mounted) return;
      Navigator.pop(context, 'logged_out');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログアウトに失敗しました: $e')),
      );
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        children: [
          const ListTile(
            leading: Icon(Icons.notifications_outlined),
            title: Text('通知設定'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const ListTile(
            leading: Icon(Icons.palette_outlined),
            title: Text('テーマ設定'),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
          ),
          const Divider(),

          // ❤️ いいね一覧へ
          ListTile(
            leading: const Icon(Icons.favorite_outline, color: Colors.pinkAccent),
            title: const Text('いいね一覧を見る'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const LikesPage(
                    apiBaseUrl: 'http://127.0.0.1:8765',
                  ),
                ),
              );
            },
          ),

          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('ログアウト', style: TextStyle(color: Colors.redAccent)),
            onTap: _loggingOut ? null : _logout,
            trailing: _loggingOut
                ? const SizedBox(
                    height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                : null,
          ),
          const Divider(),
          TextButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const EmployerShell()),
              );
            },
            icon: const Icon(Icons.business_outlined),
            label: const Text('企業モードへ'),
          ),
        ],
      ),
    );
  }
}
