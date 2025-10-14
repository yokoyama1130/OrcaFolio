import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

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
            onTap: () {
              // TODO: ログアウト処理
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('ログアウトしました')));
            },
          ),
        ],
      ),
    );
  }
}
