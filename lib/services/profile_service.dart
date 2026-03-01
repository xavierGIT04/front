import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class UserProfile {
  final String id;
  final String nom;
  final String prenom;
  final String telephone;
  final String? photoProfil;
  final String role;

  const UserProfile({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.telephone,
    this.photoProfil,
    required this.role,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final roles = json['roles'] as List? ?? [];
    String role = 'PASSAGER';
    for (final r in roles) {
      final authority = r is String ? r : (r['authority'] as String? ?? '');
      if (authority.contains('CONDUCTEUR')) {
        role = 'CONDUCTEUR';
        break;
      }
    }
    return UserProfile(
      id: (json['id'] ?? '').toString(),
      nom: json['nom'] ?? '',
      prenom: json['prenom'] ?? '',
      telephone: json['username'] ?? '',
      photoProfil: json['photoProfil'],
      role: role,
    );
  }

  String get nomComplet => '$prenom $nom';

  UserProfile copyWith({String? nom, String? prenom, String? photoProfil}) {
    return UserProfile(
      id: id,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      telephone: telephone,
      photoProfil: photoProfil ?? this.photoProfil,
      role: role,
    );
  }
}

class ProfileService {
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Récupère le profil de l'utilisateur connecté
  Future<UserProfile> getMonProfil() async {
    final uri = Uri.parse('${ApiService.baseUrl}/profil/me');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return UserProfile.fromJson(jsonDecode(response.body));
    }
    throw Exception('Impossible de charger le profil');
  }

  /// Met à jour le profil —
  Future<void> mettreAJourProfil(String nom, String prenom) async {
    final uri = Uri.parse('${ApiService.baseUrl}/profil/me/update');
    final response = await http.put(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({'nom': nom, 'prenom': prenom}),
    );
    if (response.statusCode != 200) {
      throw Exception('Erreur mise à jour profil');
    }
  }

  /// Upload une nouvelle photo de profil → retourne l'URL Cloudinary
  Future<String> uploadPhotoProfil(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';

    final uri = Uri.parse('${ApiService.baseUrl}/profil/me/photo');
    final request = http.MultipartRequest('POST', uri);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath(
      'photo',                             // ← nom du param backend
      file.path,
      contentType: MediaType('image', 'jpeg'),
    ));

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['photoProfil'] ?? '';
    }
    throw Exception('Erreur upload photo');
  }

  /// Sauvegarde le prénom localement pour l'affichage rapide dans le header
  Future<void> savePrenom(String prenom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_prenom', prenom);
  }

  static Future<String?> getPrenom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_prenom');
  }
}
