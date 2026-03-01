import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class NotificationModel {
  final int id;
  final String type;
  final String titre;
  final String message;
  bool lu;
  final DateTime dateCreation;
  final int? courseId;

  NotificationModel({
    required this.id,
    required this.type,
    required this.titre,
    required this.message,
    required this.lu,
    required this.dateCreation,
    this.courseId,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: json['type'] ?? '',
      titre: json['titre'] ?? '',
      message: json['message'] ?? '',
      lu: json['lu'] ?? false,
      dateCreation: json['dateCreation'] != null
          ? DateTime.parse(json['dateCreation'])
          : DateTime.now(),
      courseId: json['courseId'],
    );
  }

  String get icone {
    switch (type) {
      case 'COURSE_ACCEPTEE':
        return '🏍️';
      case 'COURSE_DEMARREE':
        return '🚀';
      case 'COURSE_ARRIVEE':
        return '🎯';
      case 'COURSE_TERMINEE':
        return '✅';
      case 'COURSE_ANNULEE':
        return '❌';
      case 'PAIEMENT_CONFIRME':
        return '💰';
      case 'NOUVELLE_COURSE':
        return '🔔';
      default:
        return '📢';
    }
  }
}

class NotificationService {
  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token') ?? '';
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  /// Récupère la liste des notifications
  Future<List<NotificationModel>> getMesNotifications() async {
    final uri = Uri.parse('${ApiService.baseUrl}/notifications');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List)
          .map((j) => NotificationModel.fromJson(j))
          .toList();
    }
    return [];
  }

  /// Nombre de notifications non lues (pour badge)
  Future<int> getNonLues() async {
    final uri = Uri.parse('${ApiService.baseUrl}/notifications/badge');
    final response = await http.get(uri, headers: await _authHeaders());
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['non_lues'] ?? 0;
    }
    return 0;
  }

  /// Marque une notification comme lue
  Future<void> marquerLue(int id) async {
    final uri = Uri.parse('${ApiService.baseUrl}/notifications/$id/lire');
    await http.put(uri, headers: await _authHeaders());
  }

  /// Marque toutes les notifications comme lues
  Future<void> marquerToutesLues() async {
    final uri = Uri.parse('${ApiService.baseUrl}/notifications/tout-lire');
    await http.put(uri, headers: await _authHeaders());
  }
}
