import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_storage.dart';
import '../services/course_api_service.dart';
import '../models/course_model.dart';
import '../utils/app_theme.dart';
import '../utils/widgets.dart';
import 'login_screen.dart';
import 'conducteur/suivi_course_conducteur_screen.dart';

class ConducteurHomeScreen extends StatefulWidget {
  const ConducteurHomeScreen({super.key});

  @override
  State<ConducteurHomeScreen> createState() => _ConducteurHomeScreenState();
}

class _ConducteurHomeScreenState extends State<ConducteurHomeScreen> {
  bool _enLigne = false;
  int _currentTab = 0;
  Timer? _pollingTimer;
  Timer? _gpsTimer;

  List<CourseModel> _coursesProches = [];
  bool _loadingCourses = false;
  Map<String, dynamic>? _stats;

  // Position simulée à Lomé
  double _lat = 6.1375;
  double _lng = 1.2123;

  @override
  void initState() {
    super.initState();
    _checkCourseActive();
    _loadStats();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  // ═══════════════════════════════════════════════════════════════════════
  // GESTION DE LA CONNEXION / POSITION GPS
  // ═══════════════════════════════════════════════════════════════════════

  void _toggleEnLigne() async {
    setState(() => _enLigne = !_enLigne);

    if (_enLigne) {
      // Envoyer la position GPS immédiatement
      await _updateGPS();

      // Démarrer le polling des courses proches toutes les 5 secondes
      _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadCoursesProches());

      // Mettre à jour le GPS toutes les 10 secondes
      _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateGPS());

      // Charger les courses immédiatement
      _loadCoursesProches();

      showSnack(context, '✅ Vous êtes maintenant EN LIGNE');
    } else {
      // Arrêter les timers
      _pollingTimer?.cancel();
      _gpsTimer?.cancel();
      setState(() => _coursesProches = []);
      showSnack(context, 'Vous êtes maintenant HORS LIGNE');
    }
  }

  Future<void> _updateGPS() async {
    try {
      // Simulation de variation de position (dans un rayon de ~100m)
      final random = DateTime.now().millisecondsSinceEpoch % 100;
      final latVar = (random - 50) * 0.0001;
      final lngVar = ((random + 25) % 100 - 50) * 0.0001;

      _lat = 6.1375 + latVar;
      _lng = 1.2123 + lngVar;

      await CourseApiService.updateLocalisation(_lat, _lng);
    } catch (e) {
      // Erreur silencieuse pour ne pas spammer l'utilisateur
      debugPrint('Erreur GPS: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // CHARGEMENT DES DONNÉES
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _checkCourseActive() async {
    try {
      final courseActive = await CourseApiService.getCourseActiveConducteur();
      if (courseActive != null && mounted) {
        // Rediriger vers l'écran de suivi
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuiviCourseConducteurScreen(course: courseActive),
          ),
        );
      }
    } catch (_) {
      // Pas de course active, on reste sur l'écran d'accueil
    }
  }

  Future<void> _loadCoursesProches() async {
    if (_loadingCourses || !_enLigne) return;

    setState(() => _loadingCourses = true);
    try {
      final courses = await CourseApiService.getCoursesProches();
      if (mounted) {
        setState(() {
          _coursesProches = courses;
          _loadingCourses = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingCourses = false);
      }
      debugPrint('Erreur chargement courses: $e');
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await CourseApiService.getStatsConducteur();
      if (mounted) {
        setState(() => _stats = stats);
      }
    } catch (_) {
      // Statistiques non disponibles
    }
  }

  Future<void> _accepterCourse(CourseModel course) async {
    try {
      final courseAcceptee = await CourseApiService.accepterCourse(course.id);
      if (!mounted) return;

      // Arrêter les timers
      _pollingTimer?.cancel();
      _gpsTimer?.cancel();

      // Rediriger vers l'écran de suivi
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SuiviCourseConducteurScreen(course: courseAcceptee),
        ),
      ).then((_) {
        // Quand on revient, recharger les stats et réactiver le polling si en ligne
        _loadStats();
        if (_enLigne) {
          _pollingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadCoursesProches());
          _gpsTimer = Timer.periodic(const Duration(seconds: 10), (_) => _updateGPS());
          _loadCoursesProches();
        }
      });
    } catch (e) {
      showSnack(context, e.toString().replaceAll('Exception: ', ''), error: true);
    }
  }

  Future<void> _deconnexion() async {
    await AuthStorage.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // UI
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top bar ─────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  // Menu
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.menu_rounded, color: AppColors.textDark),
                      onPressed: () {},
                    ),
                  ),
                  const Spacer(),

                  // Toggle EN LIGNE
                  GestureDetector(
                    onTap: _toggleEnLigne,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8,
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _enLigne ? 'EN LIGNE' : 'HORS LIGNE',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                              color: _enLigne ? AppColors.success : AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _enLigne ? AppColors.success : AppColors.textLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: _enLigne ? Alignment.centerRight : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // Notifications
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8,
                        )
                      ],
                    ),
                    child: Stack(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.notifications_outlined,
                            color: AppColors.textDark,
                          ),
                          onPressed: () {},
                        ),
                        if (_coursesProches.isNotEmpty)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ─── Gains du jour ────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.payments_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'GAINS DU JOUR',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textLight,
                              letterSpacing: 1,
                            ),
                          ),
                          Text(
                            '${_stats?['gains_du_jour'] ?? 0} FCFA',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.textDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Carte (placeholder) ──────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 0),
                color: const Color(0xFFDDE8D8),
                child: Center(
                  child: Icon(
                    Icons.motorcycle_rounded,
                    size: 60,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                ),
              ),
            ),

            // ─── Panel demandes proches ───────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Titre
                  Row(
                    children: [
                      const Text(
                        'Demandes proches',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDark,
                        ),
                      ),
                      const Spacer(),
                      if (_enLigne)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${_coursesProches.length} DISPO',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // État ou liste de courses
                  if (!_enLigne)
                    _MessageEtat(
                      icon: Icons.power_settings_new_rounded,
                      message: 'Passez EN LIGNE pour recevoir des demandes',
                      color: AppColors.textLight,
                    )
                  else if (_loadingCourses)
                    const _MessageEtat(
                      icon: Icons.search_rounded,
                      message: 'Recherche de courses...',
                      color: AppColors.primary,
                      showLoading: true,
                    )
                  else if (_coursesProches.isEmpty)
                      const _MessageEtat(
                        icon: Icons.location_searching_rounded,
                        message: 'Aucune demande à proximité pour le moment',
                        color: AppColors.textMedium,
                      )
                    else
                    // Liste des courses
                      SizedBox(
                        height: 280,
                        child: ListView.builder(
                          itemCount: _coursesProches.length,
                          itemBuilder: (context, index) {
                            final course = _coursesProches[index];
                            return _CourseCard(
                              course: course,
                              onAccepter: () => _accepterCourse(course),
                            );
                          },
                        ),
                      ),
                ],
              ),
            ),

            // ─── Bottom navigation ────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  )
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home_rounded,
                    label: 'ACCUEIL',
                    active: _currentTab == 0,
                    onTap: () => setState(() => _currentTab = 0),
                  ),
                  _NavItem(
                    icon: Icons.explore_outlined,
                    label: 'DEMANDES',
                    active: _currentTab == 1,
                    onTap: () => setState(() => _currentTab = 1),
                  ),
                  _NavItem(
                    icon: Icons.history_rounded,
                    label: 'HISTORIQUE',
                    active: _currentTab == 2,
                    onTap: () => setState(() => _currentTab = 2),
                  ),
                  _NavItem(
                    icon: Icons.person_outline_rounded,
                    label: 'PROFIL',
                    active: _currentTab == 3,
                    onTap: () {
                      setState(() => _currentTab = 3);
                      _deconnexion();
                    },
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

// ═══════════════════════════════════════════════════════════════════════
// WIDGETS INTERNES
// ═══════════════════════════════════════════════════════════════════════

class _CourseCard extends StatelessWidget {
  final CourseModel course;
  final VoidCallback onAccepter;

  const _CourseCard({required this.course, required this.onAccepter});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Info course
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, color: AppColors.textMedium),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nouveau passager',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: AppColors.textDark,
                      ),
                    ),
                    Row(
                      children: [
                        const Icon(Icons.route_rounded, color: AppColors.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${course.distanceKm?.toStringAsFixed(1) ?? "?"} km',
                          style: const TextStyle(
                            color: AppColors.textMedium,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${course.prixEstime?.toInt() ?? 0} F',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: AppColors.textDark,
                    ),
                  ),
                  Text(
                    course.modePaiement ?? 'ESPÈCES',
                    style: const TextStyle(fontSize: 10, color: AppColors.textMedium),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),

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
                  Container(width: 2, height: 20, color: AppColors.border),
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
                      course.departAdresse ?? 'Départ',
                      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      course.destinationAdresse ?? 'Destination',
                      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Bouton accepter
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onAccepter,
              child: const Text(
                'ACCEPTER LA COURSE',
                style: TextStyle(letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageEtat extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  final bool showLoading;

  const _MessageEtat({
    required this.icon,
    required this.message,
    required this.color,
    this.showLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (showLoading) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: color,
              ),
            ),
          ],
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

  const _NavItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: active ? AppColors.primary : AppColors.textLight,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: active ? FontWeight.bold : FontWeight.normal,
              color: active ? AppColors.primary : AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }
}