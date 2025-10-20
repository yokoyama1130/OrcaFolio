// lib/data/api_client.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models.dart'; // ← バレル（profile_user / portfolio_item / profile_response を全てexport）

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

  /// 例: http://localhost:8765  (実機は http://<MacのIP>:8765)
  final String baseUrl;

  /// Authorization に乗せる JWT（無ければ未ログイン扱い）
  final String? token;

  Map<String, String> _headers({bool withAuth = true}) {
    final h = <String, String>{'Content-Type': 'application/json'};
    if (withAuth && token != null && token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    // デバッグ：邪魔なら消してOK
    // print('[ApiClient] headers=$h');
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

    // print('[ApiClient] POST $uri -> ${res.statusCode} ${res.body}');

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
  // Profile
  // ---------------------------

  /// 自分のプロフィール（要JWT）
  Future<ProfileResponse> fetchMyProfile() async {
    final uri = Uri.parse('$baseUrl/api/users/profile.json');
    final res = await http
        .get(uri, headers: _headers())
        .timeout(const Duration(seconds: 20));

    // print('[ApiClient] GET $uri -> ${res.statusCode}');

    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return ProfileResponse.fromJson(body);
    }

    // エラーメッセージを整形
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

    // print('[ApiClient] GET $uri -> ${res.statusCode}');

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
}
