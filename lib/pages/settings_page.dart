// lib/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'employer/employer_shell.dart';

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
      // JWTを削除
      await _storage.delete(key: 'jwt');

      if (!mounted) return;

      // 親へ「logged_out」合図を返して閉じる
      Navigator.pop(context, 'logged_out');
      // ポイント: SnackBarは親側で出す方が安全。ここで出すなら pop 前に出す。
      // ScaffoldMessenger.of(context)
      //     .showSnackBar(const SnackBar(content: Text('ログアウトしました')));
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
          // 企業モードへ
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
