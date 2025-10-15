import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  Map<String, List<String>> _fieldErrors = {};

  // ★ 開発環境に合わせて1つだけ有効化
  // Androidエミュ: 10.0.2.2 / iOSシミュ: localhost / 実機: 自分のPCのLAN IP
  static const String _apiBase = 'http://localhost:8765';
  static const String _endpoint = '$_apiBase/api/users/register.json';

  Future<void> _signup() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _fieldErrors = {};
    });

    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json', // ← HTMLが返らないよう明示
        },
        body: jsonEncode({
          'name': _name.text.trim(),
          'email': _email.text.trim(),
          'password': _password.text,
        }),
      );

      // まずはJSONか確認
      final contentType = res.headers['content-type'] ?? '';
      if (!contentType.contains('application/json')) {
        final head = res.body.length > 200 ? '${res.body.substring(0, 200)}...' : res.body;
        throw Exception('非JSONレスポンス: ${res.statusCode} ${res.request?.url}\n$head');
      }

      // 安全に Map<String, dynamic> 化
      final decoded = jsonDecode(res.body);
      if (decoded is! Map) {
        throw Exception('想定外のJSON形式（Mapではない）: $decoded');
      }
      final Map<String, dynamic> json = Map<String, dynamic>.from(decoded);

      if (res.statusCode == 200 && json['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(json['message'] ?? '登録しました。メールを確認してください。')),
        );
        // 成功後はログイン画面へ
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      } else {
        // バリデーションエラーなど
        final errorsRaw = json['errors'];
        Map<String, dynamic> errorsMap = {};
        if (errorsRaw is Map) {
          errorsMap = Map<String, dynamic>.from(errorsRaw);
        }
        setState(() {
          _fieldErrors = errorsMap.map((k, v) {
            if (v is Map) return MapEntry(k, v.values.map((e) => e.toString()).toList());
            if (v is List) return MapEntry(k, v.map((e) => e.toString()).toList());
            return MapEntry(k, [v.toString()]);
          });
        });

        if (!mounted) return;
        final msg = json['message'] ?? '登録に失敗しました。入力内容をご確認ください。';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('通信に失敗しました：$e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String? _errorTextFor(String field) {
    final errs = _fieldErrors[field];
    if (errs == null || errs.isEmpty) return null;
    return errs.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final submitEnabled = !_loading;

    return Scaffold(
      appBar: AppBar(title: const Text('新規登録')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: 'お名前',
              errorText: _errorTextFor('name'),
            ),
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _email,
            decoration: InputDecoration(
              labelText: 'メールアドレス',
              errorText: _errorTextFor('email'),
            ),
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            decoration: InputDecoration(
              labelText: 'パスワード',
              errorText: _errorTextFor('password'),
            ),
            obscureText: true,
            onSubmitted: (_) => submitEnabled ? _signup() : null,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: submitEnabled ? _signup : null,
            style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 48)),
            child: _loading
                ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2))
                : const Text('登録する'),
          ),
        ],
      ),
    );
  }
}
