import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/app_theme.dart';

/// Carte réelle côté CONDUCTEUR — affiche la position GPS du conducteur.
class ConducteurMapView extends StatefulWidget {
  final double lat;
  final double lng;
  final bool enLigne;

  const ConducteurMapView({
    super.key,
    required this.lat,
    required this.lng,
    required this.enLigne,
  });

  @override
  State<ConducteurMapView> createState() => _ConducteurMapViewState();
}

class _ConducteurMapViewState extends State<ConducteurMapView> {
  final _mapController = MapController();

  @override
  void didUpdateWidget(ConducteurMapView old) {
    super.didUpdateWidget(old);
    // Recentre si la position a changé
    if (old.lat != widget.lat || old.lng != widget.lng) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(widget.lat, widget.lng), 15.0);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final position = LatLng(widget.lat, widget.lng);

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: position,
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate:
              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.tp.tripapp',
              maxZoom: 19,
            ),
            MarkerLayer(
              markers: [
                Marker(
                  point: position,
                  width: 56,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.enLigne
                          ? AppColors.primary
                          : AppColors.textMedium,
                      shape: BoxShape.circle,
                      border:
                      Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color: (widget.enLigne
                                ? AppColors.primary
                                : AppColors.textMedium)
                                .withOpacity(0.4),
                            blurRadius: 14,
                            spreadRadius: 2)
                      ],
                    ),
                    child: const Icon(Icons.motorcycle_rounded,
                        color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap',
                  style: TextStyle(fontSize: 10)),
            ),
          ],
        ),

        // Bouton recentrer
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => _mapController.move(position, 15.0),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 8)
                ],
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: AppColors.primary),
            ),
          ),
        ),

        // Badge statut en ligne / hors ligne
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.enLigne ? AppColors.success : Colors.grey,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                      color: Colors.white, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.enLigne ? 'EN LIGNE' : 'HORS LIGNE',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }
}