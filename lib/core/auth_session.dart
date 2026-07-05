import 'package:flutter/foundation.dart';

/// Holds the current admin login state in memory for the life of the app run.
class AuthSession extends ChangeNotifier {
  AuthSession._();
  static final AuthSession instance = AuthSession._();

  String? _token;
  String? _username;

  bool get isLoggedIn => _token != null;
  String? get token => _token;
  String? get username => _username;

  void login(String token, String username) {
    _token = token;
    _username = username;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _username = null;
    notifyListeners();
  }
}
