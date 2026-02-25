import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../services/auth_storage.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import '../../screens/login_screen.dart';
import 'commander_course_screen.dart';
import 'suivi_course_screen.dart';

class PassagerHomeScreen extends StatefulWidget {
  const PassagerHomeScreen({super.key});

  @override
  State<PassagerHomeScreen> createState() => _PassagerHomeScreenState();
}

class _PassagerHomeScreenState extends State<PassagerHomeScreen> {
  int _tab = 0;
  CourseModel? _courseActive;
  Timer? _pollingTimer;

  // Position simulée à Lomé, Togo
  final double _lat = 6.1375;
  final double _lng = 1.2123;

  @override
  void initState() {
    super.initState();
    _checkCourseActive();
    // Polling toutes les 4 secondes
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (_) => _checkCourseActive());
  }

  Future<void> _checkCourseActive() async {
    try {
      final course = await CourseApiService.getCourseActive();
      if (!mounted) return;
      if (course != null && (course.acceptee || course.enCours || course.arrivee)) {
        // Rediriger vers suivi si course acceptée
        _pollingTimer?.cancel();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => SuiviCourseScreen(course: course)),
          );
        }
      } else {
        setState(() => _courseActive = course);
      }
    } catch (_) {
      setState(() => _courseActive = null);
    }
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
            // ─── Header ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bonjour 👋', style: TextStyle(fontSize: 12, color: AppColors.textMedium)),
                      Text('Où allez-vous ?', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                    ],
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textDark),
                    onPressed: () {},
                  ),
                ],
              ),
            ),

            // ─── Carte (simulée) ──────────────────────────────────────
            Expanded(
              child: Stack(
                children: [
                  // Fond carte simulé
                  Container(
                    width: double.infinity,
                    color: const Color(0xFFDDE8D8),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.map_rounded, size: 80, color: Colors.grey.withOpacity(0.25)),
                        const SizedBox(height: 8),
                        Text('Carte – Lomé, Togo',
                          style: TextStyle(color: Colors.grey.withOpacity(0.5), fontSize: 13)),
                        const SizedBox(height: 4),
                        Text('(Intégrer flutter_map + OpenStreetMap)',
                          style: TextStyle(color: Colors.grey.withOpacity(0.4), fontSize: 11)),
                      ],
                    ),
                  ),

                  // Marqueur position actuelle
                  const Center(
                    child: Icon(Icons.my_location_rounded, color: Color(0xFF2196F3), size: 36),
                  ),

                  // Course EN_ATTENTE badge
                  if (_courseActive != null && _courseActive!.enAttente)
                    Positioned(
                      top: 16, left: 16, right: 16,
                      child: _CourseEnAttenteBanner(
                        course: _courseActive!,
                        onAnnuler: () async {
                          await CourseApiService.annulerCourse(_courseActive!.id);
                          setState(() => _courseActive = null);
                        },
                      ),
                    ),
                ],
              ),
            ),

            // ─── Panel bas ────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -4))],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
                  ),
                  const SizedBox(height: 16),

                  // Bouton commander
                  if (_courseActive == null)
                    GestureDetector(
                      onTap: () async {
                        final result = await Navigator.push<CourseModel>(
                          context,
                          MaterialPageRoute(builder: (_) => CommanderCourseScreen(
                            departLat: _lat, departLng: _lng,
                          )),
                        );
                        if (result != null) setState(() => _courseActive = result);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text('Où voulez-vous aller ?',
                              style: TextStyle(color: AppColors.textMedium, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),

                  if (_courseActive != null && _courseActive!.enAttente)
                    const SizedBox(height: 0)
                  else if (_courseActive == null)
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        // Raccourcis rapides
                        Row(
                          children: [
                            _QuickDestination(icon: Icons.home_rounded, label: 'Maison'),
                            const SizedBox(width: 12),
                            _QuickDestination(icon: Icons.work_rounded, label: 'Bureau'),
                            const SizedBox(width: 12),
                            _QuickDestination(icon: Icons.local_hospital_rounded, label: 'Hôpital'),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),

            // ─── Bottom Nav ───────────────────────────────────────────
            _BottomNav(
              currentTab: _tab,
              onTabChanged: (i) async {
                if (i == 3) {
                  await AuthStorage.clearSession();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()), (r) => false);
                } else {
                  setState(() => _tab = i);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────

class _CourseEnAttenteBanner extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onAnnuler;
  const _CourseEnAttenteBanner({required this.course, required this.onAnnuler});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 12)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text('Recherche d\'un conducteur...', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: onAnnuler,
                child: const Text('Annuler', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.place, color: AppColors.success, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(course.departAdresse ?? 'Départ', style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.flag, color: AppColors.primary, size: 16),
              const SizedBox(width: 6),
              Expanded(child: Text(course.destinationAdresse ?? 'Destination', style: const TextStyle(fontSize: 12, color: AppColors.textMedium))),
              Text('${course.prixEstime?.toInt()} FCFA',
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickDestination extends StatelessWidget {
  final IconData icon;
  final String label;
  const _QuickDestination({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMedium)),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentTab;
  final Function(int) onTabChanged;
  const _BottomNav({required this.currentTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'ACCUEIL', active: currentTab == 0, onTap: () => onTabChanged(0)),
          _NavItem(icon: Icons.history_rounded, label: 'HISTORIQUE', active: currentTab == 1, onTap: () => onTabChanged(1)),
          _NavItem(icon: Icons.person_outline_rounded, label: 'PROFIL', active: currentTab == 3, onTap: () => onTabChanged(3)),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: active ? AppColors.primary : AppColors.textLight, size: 24),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: active ? FontWeight.bold : FontWeight.normal, color: active ? AppColors.primary : AppColors.textLight)),
        ],
      ),
    );
  }
}
