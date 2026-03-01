import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import 'passager_home_screen.dart';   // ← correct : retour vers home PASSAGER
import 'paiement_screen.dart';

/// Écran de SUIVI côté PASSAGER
/// Affiché quand la course est ACCEPTEE | EN_COURS | ARRIVEE
class SuiviCoursePassagerScreen extends StatefulWidget {
  final CourseModel course;
  const SuiviCoursePassagerScreen({super.key, required this.course});

  @override
  State<SuiviCoursePassagerScreen> createState() => _SuiviCoursePassagerScreenState();
}

class _SuiviCoursePassagerScreenState extends State<SuiviCoursePassagerScreen> {
  late CourseModel _course;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    // Polling toutes les 4s — appelle getCourseActive() côté PASSAGER
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final updated = await CourseApiService.getCourseActive(); // ← PASSAGER
      if (!mounted) return;

      if (updated == null || updated.annulee) {
        // Course annulée ou introuvable → retour accueil passager
        _pollingTimer?.cancel();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const PassagerHomeScreen()),
          (r) => false,
        );
        return;
      }

      setState(() => _course = updated);

      // Conducteur arrivé → afficher écran paiement
      if (updated.arrivee && mounted) {
        _pollingTimer?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => PaiementScreen(course: updated)),
        );
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Carte simulée ────────────────────────────────────────
            Expanded(
              child: Container(
                color: const Color(0xFFDDE8D8),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(Icons.map_rounded, size: 80,
                          color: Colors.grey.withOpacity(0.2)),
                    ),
                    const Center(
                      child: Icon(Icons.motorcycle_rounded, size: 48,
                          color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Panel info ───────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),

                  // Statut
                  _StatutBadge(statut: _course.statut),
                  const SizedBox(height: 20),

                  // Conducteur
                  if (_course.conducteur != null)
                    _ConducteurCard(conducteur: _course.conducteur!),

                  const SizedBox(height: 16),

                  // Trajet
                  Row(
                    children: [
                      Column(children: [
                        Container(width: 10, height: 10,
                            decoration: const BoxDecoration(
                                color: AppColors.success, shape: BoxShape.circle)),
                        Container(width: 2, height: 24, color: AppColors.border),
                        Container(width: 10, height: 10,
                            decoration: const BoxDecoration(
                                color: AppColors.primary, shape: BoxShape.circle)),
                      ]),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(_course.departAdresse ?? 'Départ',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textDark),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 16),
                            Text(_course.destinationAdresse ?? 'Destination',
                                style: const TextStyle(
                                    fontSize: 13, color: AppColors.textDark),
                                maxLines: 1, overflow: TextOverflow.ellipsis),
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

                  // Bouton annuler (uniquement si pas encore en cours)
                  if (_course.acceptee)
                    SizedBox(
                      width: double.infinity, height: 48,
                      child: OutlinedButton.icon(
                        onPressed: _annuler,
                        icon: const Icon(Icons.close, size: 18,
                            color: AppColors.error),
                        label: const Text('Annuler la course',
                            style: TextStyle(color: AppColors.error)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.error),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
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

  Future<void> _annuler() async {
    try {
      await CourseApiService.annulerCourse(_course.id);
      if (!mounted) return;
      _pollingTimer?.cancel();
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PassagerHomeScreen()),
        (r) => false,
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Impossible d\'annuler', error: true);
    }
  }
}

// ─── Badge statut ────────────────────────────────────────────────────────

class _StatutBadge extends StatelessWidget {
  final String statut;
  const _StatutBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    const config = {
      'ACCEPTEE': {
        'label': '🏍️ Conducteur en route vers vous',
        'color': Color(0xFF2196F3)
      },
      'EN_COURS': {
        'label': '🚀 Vous êtes en route !',
        'color': AppColors.success
      },
      'ARRIVEE': {
        'label': '🎯 Arrivé à destination — Paiement...',
        'color': AppColors.primary
      },
    };
    final cfg = config[statut] ??
        {'label': 'Recherche en cours...', 'color': AppColors.textLight};

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
            fontWeight: FontWeight.bold, color: cfg['color'] as Color),
      ),
    );
  }
}

// ─── Card conducteur ─────────────────────────────────────────────────────

class _ConducteurCard extends StatelessWidget {
  final ConducteurInfo conducteur;
  const _ConducteurCard({required this.conducteur});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Photo profil
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary.withOpacity(0.15),
            backgroundImage: conducteur.photoProfil != null
                ? NetworkImage(conducteur.photoProfil!)
                : null,
            child: conducteur.photoProfil == null
                ? Text(
                    conducteur.prenom.isNotEmpty
                        ? conducteur.prenom[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                        color: AppColors.primary, fontWeight: FontWeight.bold))
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(conducteur.nomComplet,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark)),
                Row(children: [
                  const Icon(Icons.star_rounded,
                      size: 14, color: Color(0xFFF39C12)),
                  const SizedBox(width: 4),
                  Text(
                    conducteur.noteMoyenne?.toStringAsFixed(1) ?? '—',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMedium),
                  ),
                  const SizedBox(width: 8),
                  Text(conducteur.immatriculation ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMedium)),
                ]),
              ],
            ),
          ),
          // Type véhicule
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              conducteur.typeVehicule == 'TAXI' ? '🚕 Taxi' : '🏍️ Zém',
              style: const TextStyle(fontSize: 11, color: AppColors.primary,
                  fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}

