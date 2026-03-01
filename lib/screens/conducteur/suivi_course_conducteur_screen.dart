import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import 'conducteur_map_view.dart';
import '../conducteur_home_screen.dart';

/// Écran de SUIVI côté CONDUCTEUR
/// Affiché quand la course est ACCEPTEE | EN_COURS | ARRIVEE
class SuiviCourseConducteurScreen extends StatefulWidget {
  final CourseModel course;
  const SuiviCourseConducteurScreen({super.key, required this.course});

  @override
  State<SuiviCourseConducteurScreen> createState() =>
      _SuiviCourseConducteurScreenState();
}

class _SuiviCourseConducteurScreenState
    extends State<SuiviCourseConducteurScreen> {
  late CourseModel _course;
  Timer? _pollingTimer;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _pollingTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final updated =
      await CourseApiService.getCourseActiveConducteur();
      if (!mounted) return;
      if (updated == null) {
        _pollingTimer?.cancel();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (_) => const ConducteurHomeScreen()),
              (r) => false,
        );
        return;
      }
      if (mounted) setState(() => _course = updated);
    } catch (_) {}
  }

  Future<void> _actionPrincipale() async {
    setState(() => _loading = true);
    try {
      CourseModel updated;

      if (_course.acceptee) {
        updated = await CourseApiService.demarrerCourse(_course.id);
        if (mounted) setState(() => _course = updated);
      } else if (_course.enCours) {
        updated = await CourseApiService.signalerArrivee(_course.id);
        if (mounted) setState(() => _course = updated);
      } else if (_course.arrivee) {
        if (mounted)
          showSnack(context, 'En attente du paiement passager...');
        return;
      }
    } catch (e) {
      if (mounted)
        showSnack(context,
            e.toString().replaceAll('Exception: ', ''),
            error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  String get _btnLabel {
    if (_course.acceptee) return '▶ DÉMARRER LA COURSE';
    if (_course.enCours) return '📍 SIGNALER ARRIVÉE';
    if (_course.arrivee) return '⏳ ATTENTE PAIEMENT PASSAGER';
    return '';
  }

  bool get _btnEnabled =>
      !_loading && (_course.acceptee || _course.enCours);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Carte réelle CONDUCTEUR ─────────────────────────────
            Expanded(
              child: ConducteurMapView(     // ← REMPLACEMENT du placeholder
                lat: _course.departLat,
                lng: _course.departLng,
                enLigne: true,
              ),
            ),

            // ─── Panel info ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),

                  _StatutBadge(statut: _course.statut),
                  const SizedBox(height: 20),

                  // Trajet
                  Row(
                    children: [
                      Column(children: [
                        Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                color: AppColors.success,
                                shape: BoxShape.circle)),
                        Container(
                            width: 2,
                            height: 24,
                            color: AppColors.border),
                        Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle)),
                      ]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _course.departAdresse ?? 'Départ',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _course.destinationAdresse ??
                                  'Destination',
                              style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textDark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '${(_course.prixFinal ?? _course.prixEstime ?? 0).toInt()} F',
                        style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                            color: AppColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Bouton action
                  if (_btnLabel.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed:
                        _btnEnabled ? _actionPrincipale : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _course.arrivee
                              ? AppColors.textMedium
                              : AppColors.primary,
                        ),
                        child: _loading
                            ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white),
                        )
                            : Text(_btnLabel,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Badge statut ─────────────────────────────────────────────────────────

class _StatutBadge extends StatelessWidget {
  final String statut;
  const _StatutBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    const config = {
      'ACCEPTEE': {
        'label': '📍 En route vers le passager',
        'color': Color(0xFF2196F3)
      },
      'EN_COURS': {
        'label': '🚀 Course en cours',
        'color': AppColors.success
      },
      'ARRIVEE': {
        'label': '🎯 Arrivé — Attente paiement',
        'color': AppColors.primary
      },
      'TERMINEE': {
        'label': '✅ Course terminée',
        'color': AppColors.success
      },
    };
    final cfg = config[statut] ??
        {'label': 'En attente...', 'color': AppColors.textLight};

    return Container(
      width: double.infinity,
      padding:
      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: (cfg['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: (cfg['color'] as Color).withOpacity(0.3)),
      ),
      child: Text(
        cfg['label'] as String,
        textAlign: TextAlign.center,
        style: TextStyle(
            fontWeight: FontWeight.bold,
            color: cfg['color'] as Color),
      ),
    );
  }
}