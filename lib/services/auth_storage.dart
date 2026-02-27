import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyRoles = 'roles';
  static const _keyUserId = 'user_id';
  static const _keyUsername = 'username';

  /// Sauvegarde la session après connexion.
  ///
  /// Le backend Spring Security renvoie les rôles sous deux formats possibles :
  /// Format 1 (liste d'objets) : [{"authority": "ROLE_CONDUCTEUR"}]
  /// Format 2 (liste de strings) : ["ROLE_CONDUCTEUR"]
  /// Cette méthode gère les deux cas.
  static Future<void> saveSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAccessToken, data['access_token'] ?? '');
    await prefs.setString(_keyRefreshToken, data['refresh_token'] ?? '');
    await prefs.setString(_keyUserId, (data['id'] ?? '').toString());
    await prefs.setString(_keyUsername, data['username'] ?? '');

    // ✅ CORRECTION : gestion des deux formats de rôles Spring Security
    final rawRoles = data['roles'];
    List<String> roles = [];

    if (rawRoles is List) {
      for (final r in rawRoles) {
        if (r is String) {
          // Format 2 : liste de strings directes
          roles.add(r);
        } else if (r is Map<String, dynamic>) {
          // Format 1 : liste d'objets {"authority": "ROLE_XXX"}
          final authority = r['authority'] as String?;
          if (authority != null) roles.add(authority);
        }
      }
    }

    await prefs.setString(_keyRoles, jsonEncode(roles));
  }

  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyAccessToken);
  }

  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyRefreshToken);
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
