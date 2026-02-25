import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../models/course_model.dart';

class CourseApiService {

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ─── Estimation ────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> estimerCourse({
    required double dLat, required double dLng,
    required double aLat, required double aLng,
  }) async {
    final uri = Uri.parse(
      '${ApiService.baseUrl}/courses/estimation?dLat=$dLat&dLng=$dLng&aLat=$aLat&aLng=$aLng',
    );
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return jsonDecode(response.body);
    throw Exception('Erreur estimation');
  }

  // ─── Commander ─────────────────────────────────────────────────────────
  static Future<CourseModel> commanderCourse({
    required double departLat, required double departLng,
    required String departAdresse,
    required double destLat, required double destLng,
    required String destAdresse,
    required String modePaiement,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/commander');
    final response = await http.post(uri,
      headers: await _authHeaders(),
      body: jsonEncode({
        'depart_lat': departLat, 'depart_lng': departLng,
        'depart_adresse': departAdresse,
        'destination_lat': destLat, 'destination_lng': destLng,
        'destination_adresse': destAdresse,
        'mode_paiement': modePaiement,
      }),
    );
    if (response.statusCode == 200) return CourseModel.fromJson(jsonDecode(response.body));
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Erreur commande');
  }

  // ─── Course active passager (polling) ──────────────────────────────────
  static Future<CourseModel?> getCourseActive() async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/active');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return CourseModel.fromJson(jsonDecode(response.body));
    return null;
  }

  // ─── Annuler ───────────────────────────────────────────────────────────
  static Future<void> annulerCourse(int courseId) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/$courseId/annuler');
    await http.delete(uri, headers: await _authHeaders());
  }

  // ─── Paiement ──────────────────────────────────────────────────────────
  static Future<CourseModel> payer({
    required int courseId, required String modePaiement, required String codePin,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/$courseId/payer');
    final response = await http.post(uri,
      headers: await _authHeaders(),
      body: jsonEncode({'mode_paiement': modePaiement, 'code_pin': codePin}),
    );
    if (response.statusCode == 200) return CourseModel.fromJson(jsonDecode(response.body));
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Erreur paiement');
  }

  // ─── Notation ──────────────────────────────────────────────────────────
  static Future<CourseModel> noter({
    required int courseId, required int note, String? commentaire,
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/$courseId/noter');
    final response = await http.post(uri,
      headers: await _authHeaders(),
      body: jsonEncode({'note': note, 'commentaire': commentaire ?? ''}),
    );
    if (response.statusCode == 200) return CourseModel.fromJson(jsonDecode(response.body));
    throw Exception('Erreur notation');
  }

  // ─── Conducteurs actifs (carte) ────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getConducteursActifs(double lat, double lng) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/conducteurs-actifs?lat=$lat&lng=$lng');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    return [];
  }

  // ─── Conducteur : GPS ─────────────────────────────────────────────────
  static Future<void> updateLocalisation(double lat, double lng) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/localisation');
    await http.put(uri,
      headers: await _authHeaders(),
      body: jsonEncode({'latitude': lat, 'longitude': lng}),
    );
  }

  // ─── Conducteur : courses proches ──────────────────────────────────────
  static Future<List<CourseModel>> getCoursesProches() async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/proches');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((j) => CourseModel.fromJson(j)).toList();
    }
    return [];
  }

  // ─── Conducteur : actions ─────────────────────────────────────────────
  static Future<CourseModel> accepterCourse(int id) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/$id/accepter');
    final response = await http.post(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return CourseModel.fromJson(jsonDecode(response.body));
    throw Exception('Erreur acceptation');
  }

  static Future<CourseModel> demarrerCourse(int id) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/$id/demarrer');
    final response = await http.post(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return CourseModel.fromJson(jsonDecode(response.body));
    throw Exception('Erreur démarrage');
  }

  static Future<CourseModel> signalerArrivee(int id) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/$id/arrivee');
    final response = await http.post(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return CourseModel.fromJson(jsonDecode(response.body));
    throw Exception('Erreur arrivée');
  }

  static Future<CourseModel?> getCourseActiveConducteur() async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/conducteur/active');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return CourseModel.fromJson(jsonDecode(response.body));
    return null;
  }
}
