import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/api_client.dart';
import 'profile_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.apiBaseUrl = 'http://localhost:8765'});
  final String apiBaseUrl;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _storage = const FlutterSecureStorage();
  bool _loading = false;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final api = ApiClient(baseUrl: widget.apiBaseUrl);
      final res = await api.login(_email.text.trim(), _password.text); // ← サーバからJWT取得
      await _storage.write(key: 'jwt', value: res.token);              // ← 保存

      if (!mounted) return;
      // Profileへトークンを渡して遷移（Unauthorized回避に必須）
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => ProfilePage(
            isLoggedIn: true,
            apiBaseUrl: widget.apiBaseUrl,
            token: res.token,
          ),
        ),
        (_) => false,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(controller: _email, decoration: const InputDecoration(labelText: 'メールアドレス')),
          const SizedBox(height: 12),
          TextField(controller: _password, decoration: const InputDecoration(labelText: 'パスワード'), obscureText: true),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _login,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: _loading ? const CircularProgressIndicator() : const Text('ログイン'),
          ),
        ],
      ),
    );
  }
}
