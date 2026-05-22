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
  Future<Map<String, dynamic>> getTwoOctaveSongs() {
    debugPrint('[API] base=$defaultBaseUrl');
    debugPrint('[API] GET /two-octave-songs start');
    return _getJson('/two-octave-songs');
  }

  Future<Map<String, dynamic>> _getJson(String path) async {
    final uri = Uri.parse('$defaultBaseUrl$path');
    final response = await _httpClient
        .get(uri)
        .timeout(const Duration(seconds: 5));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException('Request failed with status ${response.statusCode} for $path');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw ApiException('Unexpected JSON shape for $path');
    }
    return decoded;
  }
}

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}
