import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' as http_parser; // pubspec.yaml に http_parser を追加
import 'package:image_picker/image_picker.dart';

import 'models.dart'; // ProfileResponse / ProfileUser などを export

import 'package:flutter/foundation.dart' show debugPrint;

/// ログイン結果
class LoginResult {
  final String token;
  final int userId;
  final String name;
  final String email;
  LoginResult({
    required this.token,
    required this.userId,
    required this.name,
    required this.email,
  });
}

/// FilePicker の bytes を Multipart に載せるための小ユーティリティ
class NamedBytesFile {
  final List<int> bytes;
  final String filename;
  const NamedBytesFile(this.bytes, this.filename);
}

class ApiClient {
  ApiClient({required this.baseUrl, this.token});

  /// API ベース URL（例: http://localhost:8765）
  final String baseUrl;

  /// Authorization に乗せる JWT（無ければ未ログイン扱い）
  final String? token;

  /// JSON 通信用ヘッダ（multipart では使わない）
  Map<String, String> _headers({bool withAuth = true}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (withAuth && token != null && token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ----------------------------------------------------------------
  // Auth
  // ----------------------------------------------------------------

  Future<LoginResult> login(String email, String password) async {
    final uri = Uri.parse('$baseUrl/api/users/login.json');
    final res = await http
        .post(
          uri,
          headers: _headers(withAuth: false),
          body: jsonEncode({'email': email, 'password': password}),
        )
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final m = json.decode(res.body) as Map<String, dynamic>;
      return LoginResult(
        token: m['token'] as String,
        userId: (m['user']['id'] as num).toInt(),
        name: (m['user']['name'] ?? '') as String,
        email: (m['user']['email'] ?? '') as String,
      );
    }

    String msg = 'Login failed (${res.statusCode})';
    try {
      final m = json.decode(res.body) as Map<String, dynamic>;
      if (m['message'] != null) msg = m['message'].toString();
    } catch (_) {}
    throw Exception(msg);
  }

  // ----------------------------------------------------------------
  // Profile: fetch
  // ----------------------------------------------------------------

  /// 自分のプロフィール（要 JWT）
  Future<ProfileResponse> fetchMyProfile() async {
    final uri = Uri.parse('$baseUrl/api/users/profile.json');
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return ProfileResponse.fromJson(body);
    }

    String msg = 'Failed: ${res.statusCode}';
    try {
      final m = json.decode(res.body) as Map<String, dynamic>;
      if (m['message'] != null) msg = m['message'].toString();
    } catch (_) {}
    if (res.statusCode == 401) {
      throw Exception('Unauthorized');
    }
    throw Exception(msg);
  }

  /// 他人の公開プロフィール（JWT 不要）
  Future<ProfileResponse> fetchPublicProfile(int userId) async {
    final uri = Uri.parse('$baseUrl/api/users/view/$userId.json');
    final res = await http
        .get(uri, headers: _headers(withAuth: false))
        .timeout(const Duration(seconds: 20));

    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return ProfileResponse.fromJson(body);
    }

    String msg = 'Failed: ${res.statusCode}';
    try {
      final m = json.decode(res.body) as Map<String, dynamic>;
      if (m['message'] != null) msg = m['message'].toString();
    } catch (_) {}
    throw Exception(msg);
  }

  // ----------------------------------------------------------------
  // Profile: update (name / bio / icon)
  // ----------------------------------------------------------------

  /// プロフィール更新（いずれも任意：指定されたものだけ更新）
  /// サーバ: POST /api/users/update.json
  /// フィールド:
  ///   - name: string
  ///   - bio : string
  ///   - icon: file (multipart, フィールド名 'icon')
  Future<ProfileUser> updateProfile({
    String? name,
    String? bio,
    XFile? icon, // image_picker の XFile
  }) async {
    final uri = Uri.parse('$baseUrl/api/users/update.json');

    final req = http.MultipartRequest('POST', uri);
    if (token != null && token!.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    if (name != null) req.fields['name'] = name;
    if (bio != null) req.fields['bio'] = bio;

    if (icon != null) {
      final ct = _guessImageContentType(icon.name);
      req.files.add(
        await http.MultipartFile.fromPath(
          'icon',
          icon.path,
          filename: icon.name,
          contentType: ct,
        ),
      );
    }

    final streamed = await req.send().timeout(const Duration(seconds: 30));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      final map = json.decode(res.body) as Map<String, dynamic>;
      if (map['success'] == true && map['user'] is Map) {
        return ProfileUser.fromJson(map['user'] as Map<String, dynamic>);
      }
      throw Exception(map['message']?.toString() ?? '更新に失敗しました');
    } else if (res.statusCode == 401) {
      throw Exception('Unauthorized');
    } else {
      String msg = 'Failed: ${res.statusCode}';
      try {
        final m = json.decode(res.body) as Map<String, dynamic>;
        if (m['message'] != null) msg = m['message'].toString();
      } catch (_) {}
      throw Exception(msg);
    }
  }

  // ----------------------------------------------------------------
  // Portfolio: create (multipart/form-data)
  // ----------------------------------------------------------------

  /// ポートフォリオ新規作成（JWT 必須）
  /// API: POST /api/portfolios/add.json（JSONで {success, id} を返す想定）
  Future<int> createPortfolio({
    required int categoryId,
    required String title,
    String? description,
    String? link,

    // サムネ画像（必須想定）
    File? thumbnailFile,

    // 機械系
    String? purpose,
    String? basicSpec,
    String? designUrl,
    String? designDescription,
    String? partsList,
    String? processingMethod,
    String? processingNotes,
    String? analysisMethod,
    String? analysisResult,
    String? developmentPeriod,
    String? mechanicalNotes,
    String? referenceLinks,
    String? toolUsed,
    String? materialUsed,

    // プログラミング
    String? githubUrl,

    // 化学
    String? experimentSummary,

    // PDF
    NamedBytesFile? drawingPdf,               // 図面PDF（1枚）
    List<NamedBytesFile>? supplementPdfs,     // 補足PDF（複数）
  }) async {
    if (token == null || token!.isEmpty) {
      throw Exception('Unauthorized');
    }

    final uri = Uri.parse('$baseUrl/api/portfolios/add.json');
    final req = http.MultipartRequest('POST', uri);
    req.headers['Authorization'] = 'Bearer $token';

    // ---- fields（サーバ必須の title/description は必ず入れる）----
    req.fields['category_id'] = categoryId.toString();
    req.fields['title'] = title;

    // description は PortfoliosTable で必須なので、空なら単一スペースで埋める
    final desc = (description ?? '').trim();
    req.fields['description'] = desc.isEmpty ? ' ' : desc;

    void put(String k, String? v) {
      if (v != null && v.trim().isNotEmpty) req.fields[k] = v.trim();
    }
    put('link', link);

    // 機械系
    put('purpose',              purpose);
    put('basic_spec',           basicSpec);
    put('design_url',           designUrl);
    put('design_description',   designDescription);
    put('parts_list',           partsList);
    put('processing_method',    processingMethod);
    put('processing_notes',     processingNotes);
    put('analysis_method',      analysisMethod);
    put('analysis_result',      analysisResult);
    put('development_period',   developmentPeriod);
    put('mechanical_notes',     mechanicalNotes);
    put('reference_links',      referenceLinks);
    put('tool_used',            toolUsed);
    put('material_used',        materialUsed);

    // プログラミング／化学
    put('github_url',           githubUrl);
    put('experiment_summary',   experimentSummary);

    // ---- files（サムネは thumbnail_file フィールド名で）----
    if (thumbnailFile != null) {
      final filename = _basename(thumbnailFile.path);
      final ct = _guessImageContentType(filename); // ★ 明示的に MIME 指定（HEIC ケア）
      req.files.add(
        await http.MultipartFile.fromPath(
          'thumbnail_file',        // ★ サーバと一致
          thumbnailFile.path,
          filename: filename,
          contentType: ct,         // ★ ここがポイント
        ),
      );
    }

    // PDF
    final pdfType = http_parser.MediaType('application', 'pdf');

    if (drawingPdf != null) {
      req.files.add(
        http.MultipartFile.fromBytes(
          'drawing_pdf',
          drawingPdf.bytes,
          filename: drawingPdf.filename,
          contentType: pdfType,
        ),
      );
    }

    if (supplementPdfs != null && supplementPdfs.isNotEmpty) {
      for (final f in supplementPdfs) {
        req.files.add(
          http.MultipartFile.fromBytes(
            'supplement_pdfs[]',
            f.bytes,
            filename: f.filename,
            contentType: pdfType,
          ),
        );
      }
    }

    // （必要ならデバッグ）
    // print('[createPortfolio] fields=${req.fields}');
    // print('[createPortfolio] files=${req.files.map((f)=>'${f.field}:${f.filename}').toList()}');

    // ⬇⬇⬇ 送信直前のデバッグ出力を追加 ⬇⬇⬇
    // fields と files の中身を確認（フィールド名が期待通りか、特に thumbnail_file があるか）
    debugPrint('[createPortfolio] fields=${req.fields}');
    debugPrint('[createPortfolio] files=${req.files.map((f) => '${f.field}:${f.filename}').toList()}');
    // ⬆⬆⬆ ここまで ⬆⬆⬆

    final streamed = await req.send().timeout(const Duration(seconds: 60));
    final res = await http.Response.fromStream(streamed);

    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      if (body['success'] == true) {
        return (body['id'] as num).toInt();
      }
      throw Exception(body['message']?.toString() ?? '投稿に失敗しました');
    }

    String msg = 'Failed: ${res.statusCode}';
    try {
      final m = json.decode(res.body) as Map<String, dynamic>;
      if (m['message'] != null) msg = m['message'].toString();
    } catch (_) {}
    throw Exception(msg);
  }

  // ----------------------------------------------------------------
  // ヘルパ
  // ----------------------------------------------------------------

  /// 画像ファイル名から contentType を推定（不明なら null）
  http_parser.MediaType? _guessImageContentType(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return http_parser.MediaType('image', 'jpeg');
      case 'png':
        return http_parser.MediaType('image', 'png');
      case 'webp':
        return http_parser.MediaType('image', 'webp');
      case 'heic':
        // iOS の HEIC を明示サポート
        return http_parser.MediaType('image', 'heic');
      default:
        return null; // 不明ならサーバ側で判定させる
    }
  }

  /// パスからファイル名だけを安全に抽出
  String _basename(String path) {
    // Windows/UNIX どちらでもOKなように
    final posix = path.split('/').last;
    return posix.split('\\').last;
  }
}
