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
      debugPrint('Nominatim error: $e');
      return [];
    }
  }
}
