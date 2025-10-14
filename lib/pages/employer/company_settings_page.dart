import 'package:flutter/material.dart';
import 'payment_page.dart';

class CompanySettingsPage extends StatelessWidget {
  const CompanySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const currentPlan = 'Pro'; // 将来APIから取得

    return Scaffold(
      appBar: AppBar(title: const Text('会社設定')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('現在のプラン'),
            subtitle: Text(currentPlan),
          ),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('テーマ設定'),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {}, // TODO
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PaymentPage()),
                );
              },
              icon: const Icon(Icons.workspace_premium_outlined),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              label: const Text('プランを変更'),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('ログアウト',
                style: TextStyle(color: Colors.redAccent)),
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
