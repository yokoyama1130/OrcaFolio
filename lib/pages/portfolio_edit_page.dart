import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PortfolioEditPage extends StatefulWidget {
  const PortfolioEditPage({super.key});

  @override
  State<PortfolioEditPage> createState() => _PortfolioEditPageState();
}

class _PortfolioEditPageState extends State<PortfolioEditPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _title;
  late TextEditingController _desc;
  bool _saving = false;
  String _error = '';

  Map<String, String> _authHeaders(String? token) {
    final h = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  @override
  void initState() {
    super.initState();
    // 初期値は引数の current から
    _title = TextEditingController();
    _desc  = TextEditingController();
  }

  @override
  void dispose() {
    _title.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _submit({
    required String baseUrl,
    required int id,
    required String? token,
  }) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() { _saving = true; _error = ''; });

    final base = baseUrl.replaceAll(RegExp(r'/$'), '');
    final uri  = Uri.parse('$base/api/portfolios/edit/$id.json');

    final body = json.encode({
      'title': _title.text.trim(),
      'description': _desc.text.trim(),
    });

    try {
      final res = await http
          .put(uri, headers: _authHeaders(token), body: body)
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        throw Exception('Failed: ${res.statusCode} - ${res.body}');
      }
      final map = json.decode(res.body) as Map<String, dynamic>;
      if (map['success'] == true) {
        if (mounted) Navigator.pop(context, true);
        return;
      }
      throw Exception(map['message']?.toString() ?? '更新に失敗しました');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final id = (args['id'] as num).toInt();
    final apiBaseUrl = args['apiBaseUrl'] as String;
    final token = args['token'] as String?;
    final current = (args['current'] as Map<String, dynamic>?) ?? const {};

    _title.text = current['title']?.toString() ?? '';
    _desc.text  = current['description']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('ポートフォリオを編集')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'タイトル'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'タイトルを入力してください' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _desc,
                  decoration: const InputDecoration(labelText: '説明'),
                  maxLines: 6,
                ),
                const SizedBox(height: 16),
                if (_error.isNotEmpty)
                  Container(
                    width: double.infinity,
                    color: Colors.red.shade50,
                    padding: const EdgeInsets.all(12),
                    child: Text(_error, style: const TextStyle(color: Colors.red)),
                  ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving ? null : () => _submit(baseUrl: apiBaseUrl, id: id, token: token),
                    icon: const Icon(Icons.save),
                    label: Text(_saving ? '保存中...' : '保存する'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
