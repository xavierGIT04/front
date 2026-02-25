import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import '../conducteur_home_screen.dart';

class SuiviCourseConducteurScreen extends StatefulWidget {
  final CourseModel course;
  const SuiviCourseConducteurScreen({super.key, required this.course});

  @override
  State<SuiviCourseConducteurScreen> createState() => _SuiviCourseConducteurScreenState();
}

class _SuiviCourseConducteurScreenState extends State<SuiviCourseConducteurScreen> {
  late CourseModel _course;
  Timer? _pollingTimer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final updated = await CourseApiService.getCourseActiveConducteur();
      if (!mounted) return;

      if (updated == null) {
        // Course terminée ou annulée
        _pollingTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConducteurHomeScreen()),
        );
        return;
      }

      // Si le paiement est confirmé, retour à l'accueil
      if (updated.paiementConfirme) {
        _pollingTimer?.cancel();
        showSnack(context, '✅ Paiement reçu ! Merci.');
        await Future.delayed(const Duration(seconds: 2));
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConducteurHomeScreen()),
        );
        return;
      }

      setState(() => _course = updated);
    } catch (_) {}
  }

  Future<void> _demarrer() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final updated = await CourseApiService.demarrerCourse(_course.id);
      setState(() {
        _course = updated;
        _loading = false;
      });
      showSnack(context, '🚀 Course démarrée !');
    } catch (e) {
      showSnack(context, e.toString().replaceAll('Exception: ', ''), error: true);
      setState(() => _loading = false);
    }
  }

  Future<void> _signalerArrivee() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final updated = await CourseApiService.signalerArrivee(_course.id);
      setState(() {
        _course = updated;
        _loading = false;
      });
      showSnack(context, '🎯 Arrivée signalée ! En attente du paiement...');
    } catch (e) {
      showSnack(context, e.toString().replaceAll('Exception: ', ''), error: true);
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Empêche le retour arrière pendant la course
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Text(
                      'Course en cours',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.success,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'ACTIF',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Carte simulée
              Expanded(
                child: Container(
                  color: const Color(0xFFDDE8D8),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          Icons.map_rounded,
                          size: 80,
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      const Center(
                        child: Icon(
                          Icons.my_location_rounded,
                          size: 48,
                          color: Color(0xFF2196F3),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Panel info
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Handle
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Statut
                    _StatutBadge(statut: _course.statut),
                    const SizedBox(height: 20),

                    // Trajet
                    _TrajetRow(
                      departAdresse: _course.departAdresse ?? 'Départ',
                      destAdresse: _course.destinationAdresse ?? 'Destination',
                      prix: _course.prixEstime?.toInt() ?? 0,
                      distance: _course.distanceKm,
                    ),
                    const SizedBox(height: 20),

                    // Boutons d'action
                    if (_course.acceptee && !_course.enCours)
                      PrimaryButton(
                        label: 'Démarrer la course',
                        onPressed: _demarrer,
                        isLoading: _loading,
                      )
                    else if (_course.enCours)
                      PrimaryButton(
                        label: 'Signaler l\'arrivée',
                        onPressed: _signalerArrivee,
                        isLoading: _loading,
                      )
                    else if (_course.arrivee)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withOpacity(0.3),
                            ),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.hourglass_top, color: AppColors.primary),
                              SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'En attente du paiement du passager...',
                                  style: TextStyle(
                                    color: AppColors.textDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatutBadge extends StatelessWidget {
  final String statut;
  const _StatutBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> config = {
      'ACCEPTEE': {
        'label': '🏍️ En route vers le passager',
        'color': const Color(0xFF2196F3)
      },
      'EN_COURS': {
        'label': '🚀 Course en cours',
        'color': AppColors.success
      },
      'ARRIVEE': {
        'label': '🎯 Arrivé ! En attente paiement',
        'color': AppColors.primary
      },
    };
    final cfg = config[statut] ?? {
      'label': 'En attente...',
      'color': AppColors.textLight
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: (cfg['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (cfg['color'] as Color).withOpacity(0.3)),
      ),
      child: Text(
        cfg['label'] as String,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: cfg['color'] as Color,
        ),
      ),
    );
  }
}

class _TrajetRow extends StatelessWidget {
  final String departAdresse;
  final String destAdresse;
  final int prix;
  final double? distance;

  const _TrajetRow({
    required this.departAdresse,
    required this.destAdresse,
    required this.prix,
    this.distance,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Info distance
        if (distance != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.route_rounded, size: 16, color: AppColors.textMedium),
              const SizedBox(width: 4),
              Text(
                '${distance!.toStringAsFixed(1)} km',
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textMedium,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        if (distance != null) const SizedBox(height: 12),

        // Trajet
        Row(
          children: [
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                Container(width: 2, height: 24, color: AppColors.border),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    departAdresse,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    destAdresse,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '$prix F',
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}