import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const String _tokenKey = 'auth_token';

  Future<SharedPreferences> get _prefs async => SharedPreferences.getInstance();

  Future<void> saveToken(String token) async {
    final prefs = await _prefs;
    await prefs.setString(_tokenKey, token);
  }

  Future<String?> readToken() async {
    final prefs = await _prefs;
    return prefs.getString(_tokenKey);
  }

  Future<void> clear() async {
    final prefs = await _prefs;
    await prefs.remove(_tokenKey);
  }
}