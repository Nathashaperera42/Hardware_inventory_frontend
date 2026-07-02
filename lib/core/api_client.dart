import 'dart:convert';
import 'package:http/http.dart' as http;
import 'constants.dart';

/// Thin wrapper over http that unwraps the backend's ApiResponse envelope
/// ({ success, message, data, errors }) and throws a readable error on failure.
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class ApiClient {
  final http.Client _client = http.Client();

  Uri _uri(String path, [Map<String, dynamic>? query]) =>
      Uri.parse('${ApiConfig.baseUrl}$path').replace(
        queryParameters: query?.map((k, v) => MapEntry(k, v.toString())),
      );

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) async {
    final res = await _client.get(_uri(path, query));
    return _handle(res);
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    final res = await _client.post(_uri(path),
        headers: _headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    final res = await _client.put(_uri(path),
        headers: _headers, body: jsonEncode(body));
    return _handle(res);
  }

  Future<dynamic> delete(String path) async {
    final res = await _client.delete(_uri(path), headers: _headers);
    return _handle(res);
  }

  static const _headers = {'Content-Type': 'application/json'};

  dynamic _handle(http.Response res) {
    Map<String, dynamic> body;
    try {
      body = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      throw ApiException('Server returned an unexpected response.');
    }

    final success = body['success'] == true;
    if (!success) {
      final errors = (body['errors'] as List?)?.cast<String>() ?? [];
      final msg = errors.isNotEmpty
          ? errors.join('\n')
          : (body['message'] ?? 'Request failed.');
      throw ApiException(msg.toString());
    }
    return body['data'];
  }
}
