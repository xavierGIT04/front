import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget carte réutilisable basé sur OpenStreetMap.
/// Paramètres :
/// - [center] : position initiale de la caméra
/// - [markers] : liste de marqueurs à afficher
/// - [mapController] : contrôleur externe (optionnel) pour animer la caméra
/// - [onTap] : callback quand l'utilisateur tape sur la carte (pour pointer une destination)
class MapWidget extends StatelessWidget {
  final LatLng center;
  final List<Marker> markers;
  final MapController? mapController;
  final void Function(LatLng)? onTap;

  const MapWidget({
    super.key,
    required this.center,
    this.markers = const [],
    this.mapController,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        initialCenter: center,
        initialZoom: 15,
        onTap: onTap != null ? (_, latLng) => onTap!(latLng) : null,
      ),
      children: [
        // Tuiles OpenStreetMap (gratuites, pas de clé API)
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.tp.tripapp',
          maxZoom: 19,
        ),
        // Marqueurs
        if (markers.isNotEmpty)
          MarkerLayer(markers: markers),
        // Attribution obligatoire OSM
        const SimpleAttributionWidget(
          source: Text('© OpenStreetMap contributors'),
        ),
      ],
    );
  }
}

/// Helpers pour créer des marqueurs standardisés
class AppMarkers {
  /// Marqueur position actuelle (bleu)
  static Marker currentLocation(LatLng position) => Marker(
    point: position,
    width: 40,
    height: 40,
    child: const Icon(Icons.my_location_rounded, color: Color(0xFF2196F3), size: 36),
  );

  /// Marqueur départ (vert)
  static Marker depart(LatLng position) => Marker(
    point: position,
    width: 40,
    height: 50,
    child: const Column(
      children: [
        Icon(Icons.location_on, color: Color(0xFF4CAF50), size: 36),
      ],
    ),
  );

  /// Marqueur destination (rouge/primary)
  static Marker destination(LatLng position, Color color) => Marker(
    point: position,
    width: 40,
    height: 50,
    child: Icon(Icons.location_on, color: color, size: 36),
  );
}
