import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  ApiClient({http.Client? httpClient}) : _httpClient = httpClient ?? http.Client();

  static const String defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.dolasol.com/api',
  );

  final http.Client _httpClient;

  Future<Map<String, dynamic>> getHealth() => _getJson('/health');
  Future<Map<String, dynamic>> getAppConfig() => _getJson('/app-config');
  Future<Map<String, dynamic>> getSongs() => _getJson('/songs');
  Future<Map<String, dynamic>> getLessons() => _getJson('/lessons');
  Future<dynamic> getTwoOctaveSongs() {
    debugPrint('[API] base=$defaultBaseUrl');
    debugPrint('[API] GET /two-octave-songs start');
    return _getDecoded('/two-octave-songs');
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final decoded = await _getDecoded(path);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Unexpected JSON shape for $path');
    }
    return decoded;
  }

  Future<dynamic> _getDecoded(String path) async {
    final uri = Uri.parse('$defaultBaseUrl$path');
    final response = await _httpClient
        .get(uri)
        .timeout(const Duration(seconds: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Request failed with status ${response.statusCode} for $path');
    }

    return jsonDecode(response.body);
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
