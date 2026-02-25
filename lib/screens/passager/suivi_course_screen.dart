import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../utils/app_theme.dart';
import 'paiement_screen.dart';

class SuiviCourseScreen extends StatefulWidget {
  final CourseModel course;
  const SuiviCourseScreen({super.key, required this.course});

  @override
  State<SuiviCourseScreen> createState() => _SuiviCourseScreenState();
}

class _SuiviCourseScreenState extends State<SuiviCourseScreen> {
  late CourseModel _course;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (_) => _poll());
  }

  Future<void> _poll() async {
    try {
      final updated = await CourseApiService.getCourseActive();
      if (!mounted) return;
      if (updated == null) return;
      setState(() => _course = updated);

      // Conducteur arrivé → ouvrir paiement
      if (updated.arrivee) {
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
            // ─── Carte simulée ───────────────────────────────────────
            Expanded(
              child: Container(
                color: const Color(0xFFDDE8D8),
                child: Stack(
                  children: [
                    Center(child: Icon(Icons.map_rounded, size: 80, color: Colors.grey.withOpacity(0.2))),
                    // Icône conducteur
                    const Center(
                      child: Icon(Icons.motorcycle_rounded, size: 48, color: AppColors.primary),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Panel info conducteur ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 20),

                  // Statut
                  _StatutBadge(statut: _course.statut),
                  const SizedBox(height: 20),

                  // Infos conducteur
                  if (_course.conducteur != null) ...[
                    Row(
                      children: [
                        // Photo
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: AppColors.primary.withOpacity(0.15),
                          backgroundImage: _course.conducteur!.photoProfil != null
                              ? NetworkImage(_course.conducteur!.photoProfil!) : null,
                          child: _course.conducteur!.photoProfil == null
                              ? const Icon(Icons.person_rounded, color: AppColors.primary, size: 28) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_course.conducteur!.nomComplet,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                              Row(
                                children: [
                                  const Icon(Icons.star_rounded, color: AppColors.primary, size: 14),
                                  const SizedBox(width: 4),
                                  Text('${_course.conducteur!.noteMoyenne?.toStringAsFixed(1) ?? "-"}',
                                    style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                                ],
                              ),
                              if (_course.conducteur!.immatriculation != null)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Text(_course.conducteur!.immatriculation!,
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                        // Appel
                        Container(
                          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), shape: BoxShape.circle),
                          child: IconButton(
                            icon: const Icon(Icons.phone_rounded, color: AppColors.success),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 12),
                  ],

                  // Trajet
                  _TrajetRow(
                    departAdresse: _course.departAdresse ?? 'Départ',
                    destAdresse: _course.destinationAdresse ?? 'Destination',
                    prix: _course.prixEstime?.toInt() ?? 0,
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

class _StatutBadge extends StatelessWidget {
  final String statut;
  const _StatutBadge({required this.statut});

  @override
  Widget build(BuildContext context) {
    final Map<String, Map<String, dynamic>> config = {
      'ACCEPTEE': {'label': '🏍️ Conducteur en route vers vous', 'color': const Color(0xFF2196F3)},
      'EN_COURS': {'label': '🚀 Vous êtes en route !', 'color': AppColors.success},
      'ARRIVEE': {'label': '🎯 Arrivé à destination !', 'color': AppColors.primary},
    };
    final cfg = config[statut] ?? {'label': 'En attente...', 'color': AppColors.textLight};

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: (cfg['color'] as Color).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (cfg['color'] as Color).withOpacity(0.3)),
      ),
      child: Text(cfg['label'] as String,
        textAlign: TextAlign.center,
        style: TextStyle(fontWeight: FontWeight.bold, color: cfg['color'] as Color)),
    );
  }
}

class _TrajetRow extends StatelessWidget {
  final String departAdresse;
  final String destAdresse;
  final int prix;
  const _TrajetRow({required this.departAdresse, required this.destAdresse, required this.prix});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(children: [
          Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
          Container(width: 2, height: 24, color: AppColors.border),
          Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
        ]),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(departAdresse, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
              const SizedBox(height: 16),
              Text(destAdresse, style: const TextStyle(fontSize: 13, color: AppColors.textDark)),
            ],
          ),
        ),
        Text('$prix FCFA', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark)),
      ],
    );
  }
}
