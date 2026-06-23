import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../database/settings_dao.dart';

class ApiService {
  static final ApiService instance = ApiService._();
  ApiService._();

  final _settingsDao = SettingsDao();
  String? _baseUrl;
  String? _token;

  static const _envUrlKey = 'SERVER_URL';

  String get envUrl => dotenv.env[_envUrlKey] ?? '';

  Future<String> get baseUrl async {
    if (_baseUrl != null) return _baseUrl!;
    _baseUrl = await _settingsDao.get('server_url');
    if (_baseUrl == null || _baseUrl!.isEmpty) {
      _baseUrl = envUrl;
    }
    return _baseUrl ?? '';
  }

  Future<String?> get token async {
    if (_token != null) return _token;
    _token = await _settingsDao.get('auth_token');
    return _token;
  }

  Future<bool> isConfigured() async {
    final url = await baseUrl;
    return url.isNotEmpty;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.endsWith('/') ? url.substring(0, url.length - 1) : url;
    await _settingsDao.set('server_url', _baseUrl!);
  }

  Future<void> setToken(String t) async {
    _token = t;
    await _settingsDao.set('auth_token', t);
  }

  Future<void> clearToken() async {
    _token = null;
    await _settingsDao.set('auth_token', '');
  }

  Map<String, String> _headers(bool auth) {
    final h = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (auth && _token != null) h['Authorization'] = 'Bearer $_token';
    return h;
  }

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body, {
    bool auth = true,
  }) async {
    final url = await baseUrl;
    final response = await http
        .post(Uri.parse('$url$path'), headers: _headers(auth), body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode >= 400) {
      throw HttpException('${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> get(String path, {bool auth = true}) async {
    final url = await baseUrl;
    final response = await http
        .get(Uri.parse('$url$path'), headers: _headers(auth))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode >= 400) {
      throw HttpException('${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
