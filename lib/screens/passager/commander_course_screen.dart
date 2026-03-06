import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../services/location_service.dart';
import '../../services/nominatim_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';

class CommanderCourseScreen extends StatefulWidget {
  final double departLat;
  final double departLng;
  final double? destLat;
  final double? destLng;
  final String? destAdresse;

  const CommanderCourseScreen({
    super.key,
    required this.departLat,
    required this.departLng,
    this.destLat,
    this.destLng,
    this.destAdresse,
  });

  @override
  State<CommanderCourseScreen> createState() => _CommanderCourseScreenState();
}

class _CommanderCourseScreenState extends State<CommanderCourseScreen> {
  final _destCtrl = TextEditingController();

  // ── CORRECTION 1 : modes alignés sur les enums backend ────────────────────
  // Backend : ESPECES | TMONEY | MOOV_MONEY  (pas de MOBILE_MONEY !)
  String _modePaiement = 'ESPECES';

  String _typeVehicule = 'ZEM';

  bool _loading = false;
  Map<String, dynamic>? _estimation;

  double? _destLat;
  double? _destLng;
  String? _destAdresse;

  // ── CORRECTION 2 : position de départ dynamique ───────────────────────────
  late double _departLat;
  late double _departLng;
  String _departAdresse = 'Chargement de votre position...';
  bool _loadingPosition = false;

  List<NominatimResult> _suggestions = [];
  bool _searching = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _departLat = widget.departLat;
    _departLng = widget.departLng;

    // Géocodage inverse pour afficher l'adresse lisible du départ
    _resolveAdresseDepart();

    if (widget.destLat != null &&
        widget.destLng != null &&
        widget.destAdresse != null) {
      _destLat = widget.destLat;
      _destLng = widget.destLng;
      _destAdresse = widget.destAdresse;
      _destCtrl.text = widget.destAdresse!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _estimerCourse());
    }
  }

  /// Géocodage inverse : coordonnées → adresse lisible
  Future<void> _resolveAdresseDepart() async {
    try {
      final adresse =
      await NominatimService.reverseGeocode(_departLat, _departLng);
      if (mounted) {
        setState(() =>
        _departAdresse = adresse ?? 'Votre position actuelle');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _departAdresse = 'Votre position actuelle');
      }
    }
  }

  /// Récupère la position GPS réelle et met à jour le point de départ
  Future<void> _rafraichirPosition() async {
    setState(() {
      _loadingPosition = true;
      _departAdresse = 'Localisation en cours...';
      _estimation = null;
    });
    try {
      final pos = await LocationService.getCurrentPosition();
      _departLat = pos.latitude;
      _departLng = pos.longitude;
      await _resolveAdresseDepart();
      if (_destLat != null) _estimerCourse();
    } catch (_) {
      if (mounted) setState(() => _departAdresse = 'Votre position actuelle');
    } finally {
      if (mounted) setState(() => _loadingPosition = false);
    }
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    if (_destLat != null) {
      setState(() {
        _destLat = null;
        _destLng = null;
        _destAdresse = null;
        _estimation = null;
      });
    }
    if (query.length < 3) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _searching = true);
      final results = await NominatimService.search(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _searching = false;
        });
      }
    });
  }

  void _selectSuggestion(NominatimResult result) {
    setState(() {
      _destLat = result.position.latitude;
      _destLng = result.position.longitude;
      _destAdresse = result.shortName;
      _destCtrl.text = result.shortName;
      _suggestions = [];
    });
    _estimerCourse();
  }

  Future<void> _estimerCourse() async {
    if (_destLat == null || _destLng == null) return;
    try {
      final est = await CourseApiService.estimerCourse(
        dLat: _departLat,
        dLng: _departLng,
        aLat: _destLat!,
        aLng: _destLng!,
        typeVehicule: _typeVehicule
      );
      if (mounted) setState(() => _estimation = est);
    } catch (_) {}
  }

  Future<void> _commander() async {
    if (_destLat == null || _destLng == null || _destAdresse == null) {
      showSnack(context, 'Veuillez sélectionner une destination',
          error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final course = await CourseApiService.commanderCourse(
        departLat: _departLat,
        departLng: _departLng,
        departAdresse: _departAdresse,
        destLat: _destLat!,
        destLng: _destLng!,
        destAdresse: _destAdresse!,
        modePaiement: _modePaiement, // ← ESPECES | TMONEY | MOOV_MONEY
        typeVehicule: _typeVehicule,
      );
      if (mounted) Navigator.pop(context, course);
    } catch (e) {
      if (mounted)
        showSnack(context, e.toString().replaceAll('Exception: ', ''),
            error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Commander une course',
            style: TextStyle(
                color: AppColors.textDark,
                fontWeight: FontWeight.bold,
                fontSize: 16)),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Départ — position réelle + bouton rafraîchir ──────
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _loadingPosition
                              ? const Row(children: [
                            SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary)),
                            SizedBox(width: 8),
                            Text('Localisation en cours...',
                                style: TextStyle(
                                    color: AppColors.textMedium,
                                    fontSize: 13)),
                          ])
                              : Text(
                            _departAdresse,
                            style: const TextStyle(
                                color: AppColors.textMedium,
                                fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Bouton pour rafraîchir la position GPS
                        GestureDetector(
                          onTap: _loadingPosition
                              ? null
                              : _rafraichirPosition,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.my_location_rounded,
                              color: _loadingPosition
                                  ? AppColors.textLight
                                  : AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Destination ────────────────────────────────────────
                  const Text('Destination',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _destCtrl,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une adresse...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppColors.primary),
                      suffixIcon: _searching
                          ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primary)),
                      )
                          : _destLat != null
                          ? const Icon(Icons.check_circle_rounded,
                          color: AppColors.success)
                          : null,
                    ),
                  ),

                  // ── Suggestions Nominatim ──────────────────────────────
                  if (_suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 8)
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _suggestions.length,
                        separatorBuilder: (_, __) =>
                        const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final s = _suggestions[i];
                          return ListTile(
                            dense: true,
                            leading: const Icon(Icons.location_on_rounded,
                                color: AppColors.primary, size: 18),
                            title: Text(s.shortName,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600)),
                            subtitle: Text(s.displayName,
                                style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMedium),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            onTap: () => _selectSuggestion(s),
                          );
                        },
                      ),
                    ),

                  // ── Estimation prix ────────────────────────────────────
                  if (_estimation != null) ...[
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.primary.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.route_rounded,
                              color: AppColors.primary),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Distance : ${(_estimation!['distance_km'] as num?)?.toStringAsFixed(1) ?? "?"} km',
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textMedium),
                              ),
                              Text(
                                'Prix estimé : ${(_estimation!['prix_estime'] as num?)?.toInt() ?? "?"} FCFA',
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],

                  // ── Type de véhicule ───────────────────────────────────
                  const SizedBox(height: 24),
                  const Text('Type de transport',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _VehiculeChip(
                        label: 'Zém',
                        sublabel: 'Moto-taxi',
                        selected: _typeVehicule == 'ZEM',
                        onTap: () {
                          setState(() {
                            _typeVehicule = 'ZEM';
                            _estimation = null; // Optionnel : efface l'ancien prix pendant le chargement
                          });
                          _estimerCourse(); // <── APPEL ICI
                        },
                      ),
                      const SizedBox(width: 12),
                      _VehiculeChip(
                        label: 'Taxi',
                        sublabel: 'Voiture',
                        selected: _typeVehicule == 'TAXI',
                        onTap: () {
                          setState(() {
                            _typeVehicule = 'TAXI';
                            _estimation = null; // Optionnel
                          });
                          _estimerCourse(); // <── APPEL ICI
                        },
                      ),
                    ],
                  ),
                  // ── CORRECTION 1 : Mode paiement (3 options) ──────────
                  const SizedBox(height: 20),
                  const Text('Mode de paiement',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                          fontSize: 14)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _PaiementChip(
                        label: 'Espèces',
                        icon: Icons.payments_rounded,
                        selected: _modePaiement == 'ESPECES',
                        onTap: () =>
                            setState(() => _modePaiement = 'ESPECES'),
                      ),
                      const SizedBox(width: 8),
                      _PaiementChip(
                        label: 'T-Money',
                        icon: Icons.phone_android_rounded,
                        selected: _modePaiement == 'TMONEY',
                        onTap: () =>
                            setState(() => _modePaiement = 'TMONEY'),
                      ),
                      const SizedBox(width: 8),
                      _PaiementChip(
                        label: 'Moov Money',
                        icon: Icons.account_balance_wallet_rounded,
                        selected: _modePaiement == 'MOOV_MONEY',
                        onTap: () =>
                            setState(() => _modePaiement = 'MOOV_MONEY'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Bouton commander ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(20),
            child: AppButton(
              label: _typeVehicule == 'ZEM'
                  ? 'COMMANDER UN ZÉM '
                  : 'COMMANDER UN TAXI ',
              onPressed: _destLat != null ? _commander : null,
              loading: _loading,
              color: _typeVehicule == 'ZEM'
                  ? AppColors.primary
                  : const Color(0xFF2196F3),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _destCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }
}

// ─── Chip type véhicule ──────────────────────────────────────────────────────

class _VehiculeChip extends StatelessWidget {

  final String label;
  final String sublabel;
  final bool selected;
  final VoidCallback onTap;

  const _VehiculeChip({

    required this.label,
    required this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
    label == 'Zém' ? AppColors.primary : const Color(0xFF2196F3);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: selected ? color.withOpacity(0.1) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? color : AppColors.border,
              width: selected ? 2.5 : 1,
            ),
            boxShadow: selected
                ? [
              BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3))
            ]
                : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 6),
              Text(label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: selected ? color : AppColors.textDark,
                  )),
              Text(sublabel,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMedium)),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Chip paiement ────────────────────────────────────────────────────────────

class _PaiementChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _PaiementChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primary.withOpacity(0.12)
                : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textMedium,
                  size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? AppColors.primary
                      : AppColors.textMedium,
                  fontWeight:
                  selected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}