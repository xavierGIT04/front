import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class ApiService {
  //  CORRECTION : URL selon l'environnement
  //  Émulateur Android → 10.0.2.2 pointe vers localhost du PC
  //static const String baseUrl = 'http://10.0.2.2:8081/api/v1';

  //  Simulateur iOS
   static const String baseUrl = 'http://localhost:8081/api/v1';

  //  Appareil physique → remplace par ton IP locale
  // Trouver ton IP : ipconfig (Windows) → cherche "Adresse IPv4"
  //static const String baseUrl = 'http://192.168.1.71:8081/api/v1';

  // ─── OTP ──────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> demanderOtp(String telephone) async {
    final uri = Uri.parse('$baseUrl/auth/demander-otp');

    //  CORRECTION : le backend Spring attend du JSON, pas du form-urlencoded
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'telephone': telephone}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Erreur ${response.statusCode}: ${response.body}');
  }

  static Future<Map<String, dynamic>> verifierOtp(
    String telephone,
    String code,
  ) async {
    final uri = Uri.parse('$baseUrl/auth/verifier-otp');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'telephone': telephone, 'codeSaisi': code}),
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    throw Exception('Code OTP invalide ou expiré');
  }

  // ─── INSCRIPTION ──────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>> registerPassager({
    required String telephone,
    required String nom,
    required String prenom,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final request = http.MultipartRequest('POST', uri);

    final data = {
      'username': telephone,
      'nom': nom,
      'prenom': prenom,
      'password': password,
      'profil': 'PASSAGER',
    };
    request.files.add(
      http.MultipartFile.fromString(
        'data',
        jsonEncode(data),
        contentType: MediaType('application', 'json'),
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    final body = _parseError(response.body);
    throw Exception(body);
  }

  static Future<Map<String, dynamic>> registerConducteur({
    required String telephone,
    required String nom,
    required String prenom,
    required String password,
    required String immatriculation,
    required String numeroPermis,
    required String typeVehicule, //  NOUVEAU — 'ZEM' ou 'TAXI'
    required File fileProfil,
    required File filePermis,
    required File fileCni,
    required File fileVehicule,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    final request = http.MultipartRequest('POST', uri);

    final data = {
      'username': telephone,
      'nom': nom,
      'prenom': prenom,
      'password': password,
      'profil': 'CONDUCTEUR',
      'immatriculation': immatriculation,
      'numero_permis': numeroPermis,
      'type_vehicule': typeVehicule, //  NOUVEAU
    };
    request.files.add(
      http.MultipartFile.fromString(
        'data',
        jsonEncode(data),
        contentType: MediaType('application', 'json'),
      ),
    );

    request.files
        .add(await http.MultipartFile.fromPath('fileProfil', fileProfil.path));
    request.files
        .add(await http.MultipartFile.fromPath('filePermis', filePermis.path));
    request.files
        .add(await http.MultipartFile.fromPath('fileCni', fileCni.path));
    request.files.add(
        await http.MultipartFile.fromPath('fileVehicule', fileVehicule.path));

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    }
    final body = _parseError(response.body);
    throw Exception(body);
  }

  // ─── CONNEXION ────────────────────────────────────────────────────────────

  /// Authentifie l'utilisateur.
  /// Lève [AccountDisabledException] si le compte n'est pas encore validé.
  static Future<Map<String, dynamic>> authenticate({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/authenticate');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    // Spring Security renvoie 401 avec "User is disabled" pour comptes inactifs
    final bodyStr = response.body.toLowerCase();
    if (response.statusCode == 401 &&
        (bodyStr.contains('disabled') || bodyStr.contains('inactif'))) {
      throw AccountDisabledException();
    }

    throw Exception('Numéro ou mot de passe incorrect');
  }

  // ─── Utilitaire privé ────────────────────────────────────────────────────

  static String _parseError(String body) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return json['message'] ?? json['error'] ?? 'Erreur inconnue';
    } catch (_) {
      return body.isNotEmpty ? body : 'Erreur inconnue';
    }
  }
}

/// Exception spéciale : compte existant mais pas encore validé par l'admin
class AccountDisabledException implements Exception {}
