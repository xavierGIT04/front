import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  // Position par défaut : centre de Lomé
  static const LatLng defaultPosition = LatLng(6.1375, 1.2123);

  /// Demande la permission et retourne la position actuelle.
  /// Si refusée ou erreur → retourne Lomé par défaut.
  static Future<LatLng> getCurrentPosition() async {
    try {
      // 1. Vérifier si le GPS est activé sur l'appareil
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return defaultPosition;

      // 2. Vérifier l'état de la permission
      LocationPermission permission = await Geolocator.checkPermission();

      // 3. Si pas encore demandée → la demander maintenant
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return defaultPosition;
      }

      // 4. Si refusée définitivement → on ne peut plus rien faire
      if (permission == LocationPermission.deniedForever) return defaultPosition;

      // 5. Permission accordée → récupérer la position
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return defaultPosition;
    }
  }

  /// Écoute la position en temps réel (pour le suivi conducteur).
  static Stream<LatLng> positionStream() {
    return Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 10, // ne notifie que si déplacement > 10m
      ),
    ).map((pos) => LatLng(pos.latitude, pos.longitude));
  }
}
