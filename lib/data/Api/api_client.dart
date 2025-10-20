import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/index.dart'; // 方式Aならこれ。方式Bなら '../models.dart' に変える

class ApiClient {
  ApiClient({required this.baseUrl, this.token});
  final String baseUrl; // 例: http://localhost:8765
  final String? token;  // JWT など

  Map<String, String> _headers() {
    final h = {'Content-Type': 'application/json'};
    if (token != null && token!.isNotEmpty) {
      h['Authorization'] = 'Bearer $token';
    }
    return h;
  }

  Future<ProfileResponse> fetchMyProfile() async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/users/profile.json'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return ProfileResponse.fromJson(body);
    } else if (res.statusCode == 401) {
      throw const _Unauthorized();
    } else {
      throw Exception('Failed: ${res.statusCode} ${res.body}');
    }
  }

  Future<ProfileResponse> fetchPublicProfile(int userId) async {
    final res = await http.get(
      Uri.parse('$baseUrl/api/users/view/$userId.json'),
      headers: _headers(),
    );
    if (res.statusCode == 200) {
      final body = json.decode(res.body) as Map<String, dynamic>;
      return ProfileResponse.fromJson(body);
    } else {
      throw Exception('Failed: ${res.statusCode} ${res.body}');
    }
  }
}

class _Unauthorized implements Exception {
  const _Unauthorized();
}
