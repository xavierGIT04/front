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

  static Future<CourseModel> commanderCourse({
    required double departLat,
    required double departLng,
    required String departAdresse,
    required double destLat,
    required double destLng,
    required String destAdresse,
    required String modePaiement,
    String typeVehicule = 'ZEM', //  NOUVEAU — défaut ZEM
  }) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/commander');
    final response = await http.post(
      uri,
      headers: await _authHeaders(),
      body: jsonEncode({
        'depart_lat': departLat,
        'depart_lng': departLng,
        'depart_adresse': departAdresse,
        'destination_lat': destLat,
        'destination_lng': destLng,
        'destination_adresse': destAdresse,
        'mode_paiement': modePaiement,
        'type_vehicule': typeVehicule, //  NOUVEAU
      }),
    );
    if (response.statusCode == 200) {
      return CourseModel.fromJson(jsonDecode(response.body));
    }
    final body = jsonDecode(response.body);
    throw Exception(body['message'] ?? 'Erreur commande');
  }

  static Future<CourseModel?> getCourseActive() async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/active');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return CourseModel.fromJson(jsonDecode(response.body));
    return null;
  }

  static Future<void> annulerCourse(int courseId) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/$courseId/annuler');
    await http.delete(uri, headers: await _authHeaders());
  }

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

  static Future<List<CourseModel>> getHistoriquePassager() async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/historique');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((j) => CourseModel.fromJson(j))
          .toList();
    }
    throw Exception('Erreur chargement historique');
  }

  static Future<List<Map<String, dynamic>>> getConducteursActifs(double lat, double lng) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/conducteurs-actifs?lat=$lat&lng=$lng');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    return [];
  }

  static Future<void> updateLocalisation(double lat, double lng) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/localisation');
    await http.put(uri,
      headers: await _authHeaders(),
      body: jsonEncode({'latitude': lat, 'longitude': lng}),
    );
  }

  static Future<List<CourseModel>> getCoursesProches() async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/proches');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((j) => CourseModel.fromJson(j)).toList();
    }
    return [];
  }

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

  static Future<CourseModel> terminerCourse(int id) async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/$id/terminer');
    final response = await http.post(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return CourseModel.fromJson(jsonDecode(response.body));
    throw Exception('Erreur terminaison');
  }

  static Future<CourseModel?> getCourseActiveConducteur() async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/conducteur/active');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) return CourseModel.fromJson(jsonDecode(response.body));
    return null;
  }

  static Future<Map<String, dynamic>> getStatsConducteur() async {
    final uri = Uri.parse('${ApiService.baseUrl}/courses/conducteur/historique');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return Map<String, dynamic>.from(jsonDecode(response.body));
    }
    return {'gains_du_jour': 0, 'total_courses': 0, 'historique': []};
  }
}
