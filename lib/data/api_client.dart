// lib/data/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart'; // ← 画像選択の XFile 用
import 'models.dart'; // ← バレル（profile_user / portfolio_item / profile_response を全て export）

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

class ApiClient {
  ApiClient({required this.baseUrl, this.token});

  final String baseUrl;

  /// Authorization に乗せる JWT（無ければ未ログイン扱い）
  final String? token;

  Map<String, String> _headers({bool withAuth = true}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (withAuth && token != null && token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  // ---------------------------
  // Auth
  // ---------------------------

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

  // ---------------------------
  // Profile: fetch
  // ---------------------------

  /// 自分のプロフィール（要JWT）
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
      throw Exception('Unauthorized'); // UI 側で未ログインハンドリング
    }
    throw Exception(msg);
  }

  /// 公開プロフィール（誰でもOK）
  Future<ProfileResponse> fetchPublicProfile(int userId) async {
    final uri = Uri.parse('$baseUrl/api/users/view/$userId.json');
    final res = await http
        .get(uri, headers: _headers(withAuth: false)) // 公開なので Authorization なしでOK
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

  // ---------------------------
  // Profile: update (name / bio / icon)
  // ---------------------------

  /// プロフィール更新（いずれも任意：指定されたものだけ更新）
  /// サーバ側は POST /api/users/update.json を想定。
  /// フィールド:
  /// - name: string
  /// - bio: string
  /// - icon: file (multipart)
  Future<ProfileUser> updateProfile({
    String? name,
    String? bio,
    XFile? icon, // image_picker の XFile
  }) async {
    final uri = Uri.parse('$baseUrl/api/users/update.json');

    // MultipartRequest を使うので Content-Type はここでは付けない
    final req = http.MultipartRequest('POST', uri);
    if (token != null && token!.isNotEmpty) {
      req.headers['Authorization'] = 'Bearer $token';
    }

    if (name != null) req.fields['name'] = name;
    if (bio != null) req.fields['bio'] = bio;

    if (icon != null) {
      req.files.add(
        await http.MultipartFile.fromPath(
          'icon',           // ← サーバー側も 'icon' で受け取る実装にしてある
          icon.path,
          filename: icon.name,
          // contentType は省略でOK（サーバで受けられます）
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
}
