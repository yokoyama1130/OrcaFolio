import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class PortfolioDetailPage extends StatelessWidget {
  const PortfolioDetailPage({super.key});

  // ---------------- URL 正規化（/uploads を正とする） ----------------
  String _absUrl(String base, String? input) {
    if (input == null || input.isEmpty) return '';
    final trimmedBase = base.replaceAll(RegExp(r'/$'), '');

    final baseUri = Uri.parse(trimmedBase);
    final normalizedBase =
        baseUri.host == 'localhost' ? baseUri.replace(host: '127.0.0.1') : baseUri;

    if (input.startsWith('http://') || input.startsWith('https://')) {
      final u = Uri.parse(input);
      final fixedHost = (u.host == 'localhost') ? u.replace(host: '127.0.0.1') : u;
      final cleaned = fixedHost.replace(path: _normalizeUploadsPath(fixedHost.path));
      return cleaned.toString();
    }

    String path = input.startsWith('/') ? input : '/$input';
    path = _normalizeUploadsPath(path);
    return '${normalizedBase.toString()}$path';
  }

  String _normalizeUploadsPath(String path) {
    var p = path;
    p = p.replaceFirst(RegExp(r'^//+'), '/');              // // → /
    p = p.replaceFirst(RegExp(r'^/img/+img/'), '/img/');   // /img/img → /img
    p = p.replaceFirst('/img//uploads/', '/img/uploads/'); // /img//uploads → /img/uploads
    if (p.startsWith('/img/uploads/')) {
      p = p.replaceFirst('/img/uploads/', '/uploads/');    // /img/uploads → /uploads に寄せる
    }
    return p;
  }

  // ---------------- API ----------------
  Future<Map<String, dynamic>> _fetchDetail({
    required String baseUrl,
    required int id,
  }) async {
    final base = baseUrl.replaceAll(RegExp(r'/$'), '');
    final uri = Uri.parse('$base/api/portfolios/view/$id.json');

    final res = await http.get(uri).timeout(const Duration(seconds: 20));

    if (res.statusCode != 200) {
      // ← ここを強化：本文も一緒に投げる
      throw Exception('Failed: ${res.statusCode} - ${res.body}');
    }

    final map = json.decode(res.body) as Map<String, dynamic>;
    if (map['success'] == true && map['portfolio'] is Map<String, dynamic>) {
      return map['portfolio'] as Map<String, dynamic>;
    }
    if (map['portfolio'] is Map<String, dynamic>) {
      return map['portfolio'] as Map<String, dynamic>;
    }
    if (map['id'] != null && map['title'] != null) {
      return map;
    }
    throw Exception(map['message']?.toString() ?? 'Invalid response');
  }

  // ---------------- UI ヘルパ ----------------
  String _strOf(Map<String, dynamic> m, String key) {
    final v = m[key];
    if (v == null) return '';
    if (v is String) return v;
    return v.toString();
  }

  Widget _section(String title, String body) {
    if (body.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(body, style: const TextStyle(height: 1.6)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final id = (args?['id'] as num?)?.toInt();
    final apiBaseUrl = (args?['apiBaseUrl'] as String?) ?? 'http://127.0.0.1:8765'; // 実機はMacのIP

    if (id == null) {
      return const Scaffold(
        body: SafeArea(child: Center(child: Text('不正な参照です（IDがありません）'))),
      );
    }

    return FutureBuilder<Map<String, dynamic>>(
      future: _fetchDetail(baseUrl: apiBaseUrl, id: id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        if (snap.hasError) {
          return Scaffold(
            appBar: AppBar(),
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: Text('読み込みに失敗しました:\n${snap.error}'),
            ),
          );
        }

        final p = snap.data!;
        final title = _strOf(p, 'title');
        final desc  = _strOf(p, 'description');

        final user  = (p['user'] ?? const {}) as Map<String, dynamic>;
        final username = _strOf(user, 'name').isNotEmpty
            ? _strOf(user, 'name')
            : (_strOf(p, 'author_name').isNotEmpty ? _strOf(p, 'author_name') : 'Unknown User');

        final likes = int.tryParse(_strOf(p, 'like_count')) ??
                      int.tryParse(_strOf(p, 'likes')) ?? 0;

        // 画像URL（thumbnail / imageUrl / image_url / img どれでも）
        final rawImage = p['thumbnail'] ?? p['imageUrl'] ?? p['image_url'] ?? p['img'];
        final imageUrl = _absUrl(apiBaseUrl, rawImage as String?);

        // カテゴリスラッグが来るなら拾う（なくてもOK）
        final category = (p['category'] ?? const {}) as Map<String, dynamic>;
        final slug     = _strOf(category, 'slug');

        // 機械系などの追加フィールド
        final purpose            = _strOf(p, 'purpose');
        final basicSpec          = _strOf(p, 'basic_spec');
        final designUrl          = _strOf(p, 'design_url');
        final designDescription  = _strOf(p, 'design_description');
        final partsList          = _strOf(p, 'parts_list');
        final processingMethod   = _strOf(p, 'processing_method');
        final processingNotes    = _strOf(p, 'processing_notes');
        final analysisMethod     = _strOf(p, 'analysis_method');
        final analysisResult     = _strOf(p, 'analysis_result');
        final developmentPeriod  = _strOf(p, 'development_period');
        final mechanicalNotes    = _strOf(p, 'mechanical_notes');
        final referenceLinks     = _strOf(p, 'reference_links');
        final toolUsed           = _strOf(p, 'tool_used');
        final materialUsed       = _strOf(p, 'material_used');

        // プログラミング／化学
        final githubUrl          = _strOf(p, 'github_url');
        final experimentSummary  = _strOf(p, 'experiment_summary');

        // PDF
        final drawingPdfPath     = _strOf(p, 'drawing_pdf_path'); // 例: files/portfolios/xx/p-..pdf
        final supplementPdfRaw   = p['supplement_pdf_paths'];
        final List<String> supplementPdfs = (() {
          if (supplementPdfRaw is String && supplementPdfRaw.trim().isNotEmpty) {
            try {
              final decoded = json.decode(supplementPdfRaw);
              if (decoded is List) {
                return decoded.map((e) => e.toString()).toList();
              }
            } catch (_) {}
          } else if (supplementPdfRaw is List) {
            return supplementPdfRaw.map((e) => e.toString()).toList();
          }
          return <String>[];
        })();

        return Scaffold(
          appBar: AppBar(title: Text(title.isEmpty ? 'Portfolio' : title)),
          body: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // サムネ（16:9）
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: Image.network(
                          imageUrl.isEmpty
                              ? 'https://picsum.photos/600/338'
                              : imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: Colors.grey.shade200,
                              alignment: Alignment.center,
                              child: const Icon(Icons.image, size: 48, color: Colors.black26),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade300,
                            alignment: Alignment.center,
                            child: const Text('画像を読み込めませんでした'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // タイトル / ユーザー / いいね
                    Text(
                      title.isEmpty ? '（タイトル未設定）' : title,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text('by @$username', style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.favorite, color: Colors.redAccent),
                        const SizedBox(width: 4),
                        Text('$likes likes'),
                        if (slug.isNotEmpty) ...[
                          const SizedBox(width: 12),
                          Chip(label: Text(slug)),
                        ],
                      ],
                    ),

                    const Divider(height: 32),

                    // 共通：説明
                    _section('プロジェクト概要', desc),

                    // 機械系など “あるものだけ” を順に表示
                    _section('目的・背景', purpose),
                    _section('基本仕様', basicSpec),
                    if (designUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const Icon(Icons.link, size: 18),
                            const SizedBox(width: 6),
                            Expanded(child: Text(designUrl, style: const TextStyle(decoration: TextDecoration.underline))),
                          ],
                        ),
                      ),
                    _section('設計の説明', designDescription),
                    _section('部品リスト（Markdown可）', partsList),
                    _section('加工方法', processingMethod),
                    _section('加工ノウハウ・注意点', processingNotes),
                    _section('解析手法', analysisMethod),
                    _section('解析結果・考察', analysisResult),
                    _section('開発期間', developmentPeriod),
                    _section('工夫点・反省', mechanicalNotes),
                    _section('参考資料・URL', referenceLinks),
                    _section('使用ツール', toolUsed),
                    _section('使用材料', materialUsed),

                    // プログラミング／化学
                    _section('GitHub URL', githubUrl),
                    _section('実験の概要', experimentSummary),

                    // PDF セクション
                    if (drawingPdfPath.isNotEmpty || supplementPdfs.isNotEmpty) ...[
                      const Divider(height: 32),
                      const Text('添付資料',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      if (drawingPdfPath.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('図面: ${_absUrl(apiBaseUrl, '/$drawingPdfPath')}'),
                        ),
                      for (final s in supplementPdfs)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('補足: ${_absUrl(apiBaseUrl, s.startsWith('/') ? s : '/$s')}'),
                        ),
                    ],

                    const Divider(height: 32),
                    const Text('コメント',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('（コメント機能は後でAPI接続）'),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
