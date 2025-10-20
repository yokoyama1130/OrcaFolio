// lib/pages/login_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../data/api_client.dart';

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
  bool _obscure = true;

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    try {
      final api = ApiClient(baseUrl: widget.apiBaseUrl);
      final res = await api.login(_email.text.trim(), _password.text);

      // 永続化（任意だが、次回起動時も自動ログインしたいなら保存しておく）
      await _storage.write(key: 'jwt', value: res.token);

      if (!mounted) return;

      // ✅ 親へ token を返して、この画面を閉じる（BottomNavigationBar を保持）
      Navigator.pop(context, res.token);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ログイン')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.username, AutofillHints.email],
            decoration: const InputDecoration(
              labelText: 'メールアドレス',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: _obscure,
            autofillHints: const [AutofillHints.password],
            onSubmitted: (_) => _loading ? null : _login(),
            decoration: InputDecoration(
              labelText: 'パスワード',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                onPressed: () => setState(() => _obscure = !_obscure),
                icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loading ? null : _login,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: _loading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('ログイン'),
          ),
        ],
      ),
    );
  }
}
