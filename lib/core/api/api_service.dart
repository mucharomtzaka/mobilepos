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

  String get envUrl => dotenv.env['SERVER_URL'] ?? '';
  String get apiKey => dotenv.env['API_KEY'] ?? '';

  Future<String> get baseUrl async {
    if (_baseUrl != null) return _baseUrl!;
    _baseUrl = await _settingsDao.get('server_url');
    if (_baseUrl == null || _baseUrl!.isEmpty) _baseUrl = envUrl;
    if (_baseUrl != null && _baseUrl!.isNotEmpty) {
      if (!_baseUrl!.startsWith('http://') && !_baseUrl!.startsWith('https://')) {
        _baseUrl = 'http://$_baseUrl';
      }
      _baseUrl = _baseUrl!.replaceAll(RegExp(r'/+$'), '');
    }
    return _baseUrl ?? '';
  }

  bool get hasEnvConfig => envUrl.isNotEmpty && apiKey.isNotEmpty;

  Future<bool> isConfigured() async {
    final url = await baseUrl;
    return url.isNotEmpty;
  }

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (apiKey.isNotEmpty) 'x-api-key': apiKey,
      };

  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final url = await baseUrl;
    final response = await http
        .post(Uri.parse('$url$path'), headers: _headers, body: jsonEncode(body))
        .timeout(const Duration(seconds: 30));
    if (response.statusCode >= 400) {
      throw HttpException('${response.statusCode}: ${response.body}');
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
