import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class NominatimResult {
  final String displayName;
  final String shortName;
  final LatLng position;

  const NominatimResult({
    required this.displayName,
    required this.shortName,
    required this.position,
  });
}

class NominatimService {
  // ── Recherche d'adresse (autocomplétion destination) ──────────────────────
  static Future<List<NominatimResult>> search(String query) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query)}'
            '&format=json&addressdetails=1&limit=5'
            '&countrycodes=tg',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'TripApp/1.0 (contact@tripapp.tg)',
      }).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return [];

      final List data = jsonDecode(response.body) as List;
      return data.map((item) {
        final lat = double.tryParse(item['lat'] as String? ?? '0') ?? 0;
        final lon = double.tryParse(item['lon'] as String? ?? '0') ?? 0;
        final address = item['address'] as Map<String, dynamic>? ?? {};
        final name = address['road'] ??
            address['suburb'] ??
            address['neighbourhood'] ??
            address['city_district'] ??
            (item['display_name'] as String).split(',').first;
        return NominatimResult(
          displayName: item['display_name'] as String,
          shortName: name as String,
          position: LatLng(lat, lon),
        );
      }).toList();
    } catch (e) {
      debugPrint('Nominatim search error: $e');
      return [];
    }
  }

  // ── NOUVEAU : Géocodage inverse (coordonnées → adresse lisible) ───────────
  // Utilisé pour afficher l'adresse du point de départ (position GPS réelle)
  static Future<String?> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
            '?lat=$lat&lon=$lng'
            '&format=json&addressdetails=1',
      );
      final response = await http.get(uri, headers: {
        'User-Agent': 'TripApp/1.0 (contact@tripapp.tg)',
        'Accept-Language': 'fr',
      }).timeout(const Duration(seconds: 6));

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>? ?? {};

      // Construction d'une adresse courte et lisible
      final parts = <String>[];

      final road = address['road'] as String?;
      final suburb = address['suburb'] as String?;
      final neighbourhood = address['neighbourhood'] as String?;
      final quarter = address['quarter'] as String?;
      final cityDistrict = address['city_district'] as String?;
      final city = address['city'] as String? ??
          address['town'] as String? ??
          address['village'] as String?;

      if (road != null) parts.add(road);
      if (suburb != null) {
        parts.add(suburb);
      } else if (neighbourhood != null) {
        parts.add(neighbourhood);
      } else if (quarter != null) {
        parts.add(quarter);
      } else if (cityDistrict != null) {
        parts.add(cityDistrict);
      }
      if (city != null && !parts.contains(city)) parts.add(city);

      if (parts.isEmpty) {
        // Fallback : première partie du display_name
        final display = data['display_name'] as String?;
        return display?.split(',').first ?? 'Position actuelle';
      }

      return parts.join(', ');
    } catch (e) {
      debugPrint('Nominatim reverse error: $e');
      return null;
    }
  }
}