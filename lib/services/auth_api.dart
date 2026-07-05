import '../core/api_client.dart';

class AuthApi {
  final ApiClient _client = ApiClient();

  /// Returns the JWT token on success; throws [ApiException] on failure.
  Future<String> login(String username, String password) async {
    final data = await _client.post('/auth/login', {
      'username': username,
      'password': password,
    }) as Map<String, dynamic>;
    return data['token'] as String;
  }

  Future<void> logout() => _client.post('/auth/logout', {});
}
