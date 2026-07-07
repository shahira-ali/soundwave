import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/app_constants.dart';

class ApiService {
  static const _storage = FlutterSecureStorage();
  static const String _baseUrl = AppConstants.baseUrl;

  static Future<String?> _getToken() async {
    return await _storage.read(key: AppConstants.authToken);
  }

  static Future<Map<String, String>> _getHeaders({bool withAuth = false}) async {
    final headers = {'Content-Type': 'application/json'};
    if (withAuth) {
      final token = await _getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ── Auth ──────────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final res = await http.post(
      Uri.parse('$_baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getMe() async {
    final headers = await _getHeaders(withAuth: true);
    final res = await http.get(Uri.parse('$_baseUrl/auth/me'), headers: headers);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Recognition ───────────────────────────────────────
  static Future<Map<String, dynamic>> recognizeSong(File audioFile) async {
    final token = await _getToken();
    final request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/recognize'));

    if (token != null) request.headers['Authorization'] = 'Bearer $token';

    request.files.add(await http.MultipartFile.fromPath(
      'audio',
      audioFile.path,
      // ignore: deprecated_member_use
    ));

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── History ───────────────────────────────────────────
  static Future<Map<String, dynamic>> getHistory({int page = 1, int limit = 20}) async {
    final headers = await _getHeaders(withAuth: true);
    final res = await http.get(
      Uri.parse('$_baseUrl/recognize/history?page=$page&limit=$limit'),
      headers: headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> deleteHistoryItem(String id) async {
    final headers = await _getHeaders(withAuth: true);
    final res = await http.delete(
      Uri.parse('$_baseUrl/recognize/history/$id'),
      headers: headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  // ── Songs ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> searchSongs(String query) async {
    final headers = await _getHeaders();
    final res = await http.get(
      Uri.parse('$_baseUrl/songs/search?q=${Uri.encodeComponent(query)}'),
      headers: headers,
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getTrending() async {
    final headers = await _getHeaders();
    final res = await http.get(Uri.parse('$_baseUrl/songs/trending'), headers: headers);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getFavorites() async {
    final headers = await _getHeaders(withAuth: true);
    final res = await http.get(Uri.parse('$_baseUrl/songs/favorites'), headers: headers);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> addFavorite(String songId) async {
    final headers = await _getHeaders(withAuth: true);
    final res = await http.post(Uri.parse('$_baseUrl/songs/$songId/favorite'), headers: headers);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> removeFavorite(String songId) async {
    final headers = await _getHeaders(withAuth: true);
    final res = await http.delete(Uri.parse('$_baseUrl/songs/$songId/favorite'), headers: headers);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
