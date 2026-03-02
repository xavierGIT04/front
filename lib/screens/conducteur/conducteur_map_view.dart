import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../utils/app_theme.dart';

/// Carte réelle côté CONDUCTEUR — affiche la position GPS du conducteur.
class ConducteurMapView extends StatefulWidget {
  final double lat;
  final double lng;
  final bool enLigne;
  final String? typeVehicule; // 'ZEM' ou 'TAXI'

  const ConducteurMapView({
    super.key,
    required this.lat,
    required this.lng,
    required this.enLigne,
    this.typeVehicule,
  });

  @override
  State<ConducteurMapView> createState() => _ConducteurMapViewState();
}

class _ConducteurMapViewState extends State<ConducteurMapView> {
  final _mapController = MapController();

  @override
  void didUpdateWidget(ConducteurMapView old) {
    super.didUpdateWidget(old);
    if (old.lat != widget.lat || old.lng != widget.lng) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _mapController.move(LatLng(widget.lat, widget.lng), 15.0);
      });
    }
  }

  IconData get _vehiculeIcon {
    if (widget.typeVehicule == 'TAXI')
      return Icons.local_taxi_rounded;
    return Icons.motorcycle_rounded; // ZEM par défaut
  }

  Color get _vehiculeColor {
    if (!widget.enLigne) return AppColors.textMedium;
    if (widget.typeVehicule == 'TAXI') return const Color(0xFF2196F3);
    return AppColors.primary; // ZEM = orange
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
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                      color: _vehiculeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: _vehiculeColor.withOpacity(0.4),
                          blurRadius: 14,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(_vehiculeIcon, color: Colors.white, size: 26),
                  ),
                ),
              ],
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
                    blurRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.my_location_rounded,
                  color: AppColors.primary),
            ),
          ),
        ),

        // Badge statut EN LIGNE / HORS LIGNE
        Positioned(
          top: 12,
          left: 12,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: widget.enLigne ? AppColors.success : Colors.grey,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      widget.enLigne ? 'EN LIGNE' : 'HORS LIGNE',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Badge type de véhicule
              if (widget.typeVehicule != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: widget.typeVehicule == 'TAXI'
                        ? const Color(0xFF2196F3)
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_vehiculeIcon, color: Colors.white, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        widget.typeVehicule == 'TAXI' ? 'TAXI' : 'ZÉM',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
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
