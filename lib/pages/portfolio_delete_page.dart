import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PortfolioDeletePage extends StatefulWidget {
  const PortfolioDeletePage({super.key});

  @override
  State<PortfolioDeletePage> createState() => _PortfolioDeletePageState();
}

class _PortfolioDeletePageState extends State<PortfolioDeletePage> {
  bool _deleting = false;
  String _error = '';

  Map<String, String> _authHeaders(String? token) {
    final h = <String, String>{
      'Accept': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    };
    if (token != null && token.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<void> _delete({
    required String baseUrl,
    required int id,
    required String? token,
  }) async {
    setState(() { _deleting = true; _error = ''; });

    final base = baseUrl.replaceAll(RegExp(r'/$'), '');
    final uri  = Uri.parse('$base/api/portfolios/delete/$id.json');

    try {
      final res = await http
          .delete(uri, headers: _authHeaders(token))
          .timeout(const Duration(seconds: 20));

      if (res.statusCode != 200) {
        throw Exception('Failed: ${res.statusCode} - ${res.body}');
      }
      final map = json.decode(res.body) as Map<String, dynamic>;
      if (map['success'] == true) {
        if (mounted) Navigator.pop(context, true);
        return;
      }
      throw Exception(map['message']?.toString() ?? '削除に失敗しました');
    } catch (e) {
      setState(() { _error = e.toString(); });
    } finally {
      if (mounted) setState(() { _deleting = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final id = (args['id'] as num).toInt();
    final apiBaseUrl = args['apiBaseUrl'] as String;
    final token = args['token'] as String?;

    return Scaffold(
      appBar: AppBar(title: const Text('削除の確認')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('このポートフォリオを削除します。よろしいですか？',
                  style: TextStyle(fontSize: 16)),
              const SizedBox(height: 12),
              if (_error.isNotEmpty)
                Container(
                  width: double.infinity,
                  color: Colors.red.shade50,
                  padding: const EdgeInsets.all(12),
                  child: Text(_error, style: const TextStyle(color: Colors.red)),
                ),
              const Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _deleting ? null : () => Navigator.pop(context, false),
                      child: const Text('キャンセル'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      onPressed: _deleting ? null : () => _delete(baseUrl: apiBaseUrl, id: id, token: token),
                      icon: const Icon(Icons.delete),
                      label: Text(_deleting ? '削除中...' : '削除する'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
