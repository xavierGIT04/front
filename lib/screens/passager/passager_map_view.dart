import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../models/course_model.dart';
import '../../utils/app_theme.dart';

/// Carte réelle côté PASSAGER — affiche la position actuelle et les
/// informations de course active.
class PassagerMapView extends StatefulWidget {
  final double lat;
  final double lng;
  final CourseModel? courseActive;
  final VoidCallback onAnnuler;

  const PassagerMapView({
    super.key,
    required this.lat,
    required this.lng,
    this.courseActive,
    required this.onAnnuler,
  });

  @override
  State<PassagerMapView> createState() => _PassagerMapViewState();
}

class _PassagerMapViewState extends State<PassagerMapView> {
  final _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.lat, widget.lng);

    return Stack(
      children: [
        // ── Carte OSM ────────────────────────────────────────────────
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: center,
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
                // Marqueur position actuelle
                Marker(
                  point: center,
                  width: 48,
                  height: 48,
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      shape: BoxShape.circle,
                      border:
                      Border.all(color: Colors.white, width: 3),
                      boxShadow: [
                        BoxShadow(
                            color:
                            const Color(0xFF2196F3).withOpacity(0.4),
                            blurRadius: 12,
                            spreadRadius: 2)
                      ],
                    ),
                    child: const Icon(Icons.person_pin_rounded,
                        color: Colors.white, size: 24),
                  ),
                ),
                // Marqueur destination (si course active)
                if (widget.courseActive != null) ...[
                  Marker(
                    point: LatLng(widget.courseActive!.destinationLat,
                        widget.courseActive!.destinationLng),
                    width: 48,
                    height: 48,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border:
                        Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                              color:
                              AppColors.primary.withOpacity(0.4),
                              blurRadius: 12,
                              spreadRadius: 2)
                        ],
                      ),
                      child: const Icon(Icons.flag_rounded,
                          color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ],
            ),
            const SimpleAttributionWidget(
              source: Text('© OpenStreetMap',
                  style: TextStyle(fontSize: 10)),
            ),
          ],
        ),

        // ── Bouton recentrer ─────────────────────────────────────────
        Positioned(
          top: 12,
          right: 12,
          child: GestureDetector(
            onTap: () => _mapController.move(center, 15.0),
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

        // ── Banner course en attente ──────────────────────────────────
        if (widget.courseActive != null && widget.courseActive!.enAttente)
          Positioned(
            top: 16,
            left: 16,
            right: 64,
            child: _CourseEnAttenteBanner(
              course: widget.courseActive!,
              onAnnuler: widget.onAnnuler,
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

// ─── Banner course en attente ─────────────────────────────────────────────

class _CourseEnAttenteBanner extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onAnnuler;
  const _CourseEnAttenteBanner(
      {required this.course, required this.onAnnuler});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1), blurRadius: 12)
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Recherche d\'un conducteur...',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: onAnnuler,
                child: const Text('Annuler',
                    style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place, color: AppColors.success, size: 16),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(course.departAdresse ?? 'Départ',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMedium))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.flag, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(
                      course.destinationAdresse ?? 'Destination',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMedium))),
              Text('${course.prixEstime?.toInt()} FCFA',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }
}