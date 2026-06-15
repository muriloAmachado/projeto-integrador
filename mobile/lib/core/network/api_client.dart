import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../error/app_exception.dart';

class ApiClient {
  ApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Uri _uri(String path) => Uri.parse('${ApiConfig.baseUrl}$path');

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    String? token,
  }) async {
    final response = await _client.post(
      _uri(path),
      headers: _headers(token),
      body: jsonEncode(body ?? const <String, dynamic>{}),
    );

    return _decode(response);
  }

  Map<String, String> _headers(String? token) => {
        'Content-Type': 'application/json',
        'Connection': 'close',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Map<String, dynamic> _decode(http.Response response) {
    final decodedBody = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decodedBody;
    }

    throw AppException(
      decodedBody['message']?.toString() ?? 'Falha ao comunicar com o backend',
    );
  }
}