import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyRoles = 'roles';
  static const _keyUserId = 'user_id';
  static const _keyUsername = 'username';

  static Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, data['access_token'] ?? '');
    await prefs.setString(_keyRefreshToken, data['refresh_token'] ?? '');
    await prefs.setString(_keyUserId, data['id'] ?? '');
    await prefs.setString(_keyUsername, data['username'] ?? '');

    // Rôles : liste d'objets [{"authority": "ROLE_CONDUCTEUR"}]
    final roles = (data['roles'] as List?)
            ?.map((r) => r['authority'] as String)
            .toList() ??
        [];
    await prefs.setString(_keyRoles, jsonEncode(roles));
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<List<String>> getRoles() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyRoles);
    if (raw == null) return [];
    return List<String>.from(jsonDecode(raw));
  }

  static Future<bool> isLoggedIn() async {
    final token = await getAccessToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
