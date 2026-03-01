import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../services/auth_storage.dart';
import '../../services/location_service.dart';
import '../../services/notification_service.dart';
import '../../services/profile_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import '../../screens/login_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import 'commander_course_screen.dart';
import 'passager_historique_screen.dart';
import 'passager_map_view.dart';
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
  bool _pollingActive = true;

  int _badgeCount = 0;
  final _notifService = NotificationService();

  String _prenom = '';

  // ── CORRECTION : position GPS réelle (non codée en dur) ──────────────────
  double _lat = 6.1375; // valeur par défaut Lomé (remplacée dès init)
  double _lng = 1.2123;
  bool _positionChargee = false;

  @override
  void initState() {
    super.initState();
    _loadPrenom();
    _loadBadge();
    _chargerPositionGPS(); // ← Charge la vraie position au démarrage
    _checkCourseActive();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 4),
          (_) {
        if (_pollingActive) _checkCourseActive();
      },
    );
    Timer.periodic(const Duration(seconds: 30), (_) => _loadBadge());
  }

  /// Récupère la position GPS réelle de l'utilisateur
  Future<void> _chargerPositionGPS() async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _lat = pos.latitude;
          _lng = pos.longitude;
          _positionChargee = true;
        });
        // Met à jour la position sur le backend (pour que le passager
        // soit localisé correctement pour la recherche de conducteurs)
        CourseApiService.updateLocalisation(_lat, _lng).catchError((_) {});
      }
    } catch (e) {
      debugPrint('GPS error: $e');
      if (mounted) setState(() => _positionChargee = true);
    }
  }

  Future<void> _loadPrenom() async {
    final prenom = await ProfileService.getPrenom();
    if (mounted && prenom != null && prenom.isNotEmpty) {
      setState(() => _prenom = prenom);
    }
  }

  Future<void> _loadBadge() async {
    try {
      final count = await _notifService.getNonLues();
      if (mounted) setState(() => _badgeCount = count);
    } catch (_) {}
  }

  Future<void> _checkCourseActive() async {
    try {
      final course = await CourseApiService.getCourseActive();
      if (!mounted) return;

      if (course != null &&
          (course.acceptee || course.enCours || course.arrivee)) {
        _stopPolling();
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (_) => SuiviCoursePassagerScreen(course: course)),
          );
        }
      } else if (course != null && course.enAttente) {
        setState(() => _courseActive = course);
      } else {
        if (_courseActive != null) setState(() => _courseActive = null);
      }
    } catch (_) {
      if (mounted && _courseActive != null) {
        setState(() => _courseActive = null);
      }
    }
  }

  void _stopPolling() {
    _pollingActive = false;
    _pollingTimer?.cancel();
  }

  void _restartPolling() {
    _pollingActive = true;
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 4),
          (_) {
        if (_pollingActive) _checkCourseActive();
      },
    );
  }

  Future<void> _annulerCourse() async {
    if (_courseActive == null) return;
    _pollingActive = false;
    try {
      await CourseApiService.annulerCourse(_courseActive!.id);
      if (mounted) setState(() => _courseActive = null);
    } catch (_) {
      if (mounted) showSnack(context, 'Erreur annulation', error: true);
    } finally {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _pollingActive = true;
    }
  }

  void _openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
    _loadBadge();
  }

  void _openProfile() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
    _loadPrenom();
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
            // ─── Header ───────────────────────────────────────────────
            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _openProfile,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                       Text("Bonjour 👋",
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMedium)),
                      Text(
                        _prenom.isNotEmpty ? _prenom : 'Où allez-vous ?',
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Indicateur GPS en temps réel
                  if (!_positionChargee)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.primary)),
                          SizedBox(width: 6),
                          Text('GPS',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined,
                            color: AppColors.textDark),
                        onPressed: _openNotifications,
                      ),
                      if (_badgeCount > 0)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.error,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                                minWidth: 16, minHeight: 16),
                            child: Text(
                              _badgeCount > 9 ? '9+' : '$_badgeCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── Carte avec position réelle ────────────────────────────
            Expanded(
              child: _tab == 1
                  ? const HistoriqueScreen()
                  : PassagerMapView(
                lat: _lat,
                lng: _lng,
                courseActive: _courseActive,
                onAnnuler: _annulerCourse,
              ),
            ),

            // ─── Panel bas (onglet Accueil) ────────────────────────────
            if (_tab == 0)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, -4))
                  ],
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
                    if (_courseActive == null)
                      GestureDetector(
                        onTap: () async {
                          _stopPolling();
                          final result =
                          await Navigator.push<CourseModel>(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CommanderCourseScreen(
                                // ← Passe la VRAIE position GPS
                                departLat: _lat,
                                departLng: _lng,
                              ),
                            ),
                          );
                          _restartPolling();
                          if (result != null && mounted) {
                            setState(() => _courseActive = result);
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 18),
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
                                  color:
                                  AppColors.primary.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.search_rounded,
                                    color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text('Où voulez-vous aller ?',
                                  style: TextStyle(
                                      color: AppColors.textMedium,
                                      fontSize: 15)),
                            ],
                          ),
                        ),
                      ),

                  ],
                ),
              ),

            // ─── Bottom Nav ────────────────────────────────────────────
            _BottomNav(
              currentTab: _tab,
              onTabChanged: (i) async {
                if (i == 2) {
                  await AuthStorage.clearSession();
                  if (!context.mounted) return;
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                          (r) => false);
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

// ─── Widgets internes ─────────────────────────────────────────────────────────

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
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMedium)),
          ],
        ),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentTab;
  final Function(int) onTabChanged;
  const _BottomNav(
      {required this.currentTab, required this.onTabChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(
              icon: Icons.home_rounded,
              label: 'ACCUEIL',
              active: currentTab == 0,
              onTap: () => onTabChanged(0)),
          _NavItem(
              icon: Icons.history_rounded,
              label: 'HISTORIQUE',
              active: currentTab == 1,
              onTap: () => onTabChanged(1)),
          _NavItem(
              icon: Icons.logout_rounded,
              label: 'DECONNECTER',
              active: false,
              onTap: () => onTabChanged(2)),
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
  const _NavItem(
      {required this.icon,
        required this.label,
        required this.active,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              color: active ? AppColors.primary : AppColors.textLight,
              size: 24),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                  active ? FontWeight.bold : FontWeight.normal,
                  color:
                  active ? AppColors.primary : AppColors.textLight)),
        ],
      ),
    );
  }
}