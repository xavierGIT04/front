import 'dart:async';
import 'package:flutter/material.dart';
import '../services/auth_storage.dart';
import '../services/course_api_service.dart';
import '../services/notification_service.dart';
import '../services/profile_service.dart';
import '../models/course_model.dart';
import '../utils/app_theme.dart';
import '../utils/widgets.dart';
import 'login_screen.dart';
import 'conducteur/conducteur_map_view.dart';
import 'conducteur/suivi_course_conducteur_screen.dart';
import 'notifications/notifications_screen.dart';
import 'profile/profile_screen.dart';
import '../services/location_service.dart';

class ConducteurHomeScreen extends StatefulWidget {
  const ConducteurHomeScreen({super.key});

  @override
  State<ConducteurHomeScreen> createState() =>
      _ConducteurHomeScreenState();
}

class _ConducteurHomeScreenState extends State<ConducteurHomeScreen> {
  bool _enLigne = false;
  int _currentTab = 0;
  Timer? _pollingTimer;
  Timer? _gpsTimer;

  List<CourseModel> _coursesProches = [];
  bool _loadingCourses = false;
  Map<String, dynamic>? _stats;

  int _badgeCount = 0;
  final _notifService = NotificationService();

  String _prenom = '';

  double _lat = 6.1375;
  double _lng = 1.2123;

  // ── Validation & type véhicule ───────────────────────────────────────────
  bool _estValide = true;
  bool _loadingValidation = false;
  String? _typeVehicule; // 'ZEM' ou 'TAXI'

  @override
  void initState() {
    super.initState();
    _loadPrenom();
    _loadBadge();
    _checkCourseActive();
    _loadStats();
    _loadTypeVehicule();
    _loadStatutValidation();
    Timer.periodic(const Duration(seconds: 30), (_) => _loadBadge());
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _gpsTimer?.cancel();
    super.dispose();
  }

  /// Charge le type de véhicule depuis le stockage local
  Future<void> _loadTypeVehicule() async {
    final type = await AuthStorage.getTypeVehicule();
    if (mounted && type != null) {
      setState(() => _typeVehicule = type);
    }
  }

  /// Vérifie si le compte conducteur est validé par le régulateur
  Future<void> _loadStatutValidation() async {
    setState(() => _loadingValidation = true);
    try {
      await CourseApiService.checkValidationConducteur();
      if (mounted) setState(() => _estValide = true);
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('validé') ||
          msg.contains('valide') ||
          msg.contains('régulateur') ||
          msg.contains('regulateur') ||
          msg.contains('admin')) {
        if (mounted) setState(() => _estValide = false);
      } else {
        if (mounted) setState(() => _estValide = true);
      }
    } finally {
      if (mounted) setState(() => _loadingValidation = false);
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

  void _toggleEnLigne() async {
    // Bloquer si compte non validé
    if (!_estValide) {
      showSnack(
        context,
        'Votre compte n\'est pas encore validé par le régulateur.',
        error: true,
      );
      return;
    }

    setState(() => _enLigne = !_enLigne);
    if (_enLigne) {
      await _updateGPS();
      _pollingTimer = Timer.periodic(
          const Duration(seconds: 5), (_) => _loadCoursesProches());
      _gpsTimer = Timer.periodic(
          const Duration(seconds: 10), (_) => _updateGPS());
      _loadCoursesProches();
      if (mounted) showSnack(context, ' Vous êtes maintenant EN LIGNE');
    } else {
      _pollingTimer?.cancel();
      _gpsTimer?.cancel();
      setState(() => _coursesProches = []);
      if (mounted) showSnack(context, 'Vous êtes maintenant HORS LIGNE');
    }
  }

  Future<void> _updateGPS() async {
    try {
      // Utiliser la vraie position GPS
      final pos = await LocationService.getCurrentPosition();
      _lat = pos.latitude;
      _lng = pos.longitude;
      await CourseApiService.updateLocalisation(_lat, _lng);
      if (mounted) setState(() {}); // rafraîchit la carte
      debugPrint('GPS mis à jour : lat=$_lat lng=$_lng');
    } catch (e) {
      debugPrint('Erreur GPS: $e');
    }
  }

  Future<void> _checkCourseActive() async {
    try {
      final courseActive =
      await CourseApiService.getCourseActiveConducteur();
      if (courseActive != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (_) =>
                  SuiviCourseConducteurScreen(course: courseActive)),
        );
      }
    } catch (_) {}
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
      if (mounted) setState(() => _loadingCourses = false);
    }
  }

  Future<void> _loadStats() async {
    try {
      final stats = await CourseApiService.getStatsConducteur();
      if (mounted) setState(() => _stats = stats);
    } catch (_) {}
  }

  Future<void> _accepterCourse(CourseModel course) async {
    try {
      final courseAcceptee =
      await CourseApiService.accepterCourse(course.id);
      if (!mounted) return;
      _pollingTimer?.cancel();
      _gpsTimer?.cancel();
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) =>
                SuiviCourseConducteurScreen(course: courseAcceptee)),
      ).then((_) {
        _loadStats();
        if (_enLigne) {
          _pollingTimer = Timer.periodic(
              const Duration(seconds: 5), (_) => _loadCoursesProches());
          _gpsTimer = Timer.periodic(
              const Duration(seconds: 10), (_) => _updateGPS());
          _loadCoursesProches();
        }
      });
    } catch (e) {
      if (mounted)
        showSnack(context, e.toString().replaceAll('Exception: ', ''),
            error: true);
    }
  }

  Future<void> _deconnexion() async {
    _pollingTimer?.cancel();
    _gpsTimer?.cancel();
    await AuthStorage.clearSession();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (r) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Top bar ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: _openProfile,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Icon(Icons.person_rounded,
                          color: AppColors.textDark),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _toggleEnLigne,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.06),
                              blurRadius: 8)
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
                              color: !_estValide
                                  ? AppColors.textLight
                                  : _enLigne
                                  ? AppColors.success
                                  : AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(width: 8),
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 44,
                            height: 24,
                            decoration: BoxDecoration(
                              color: !_estValide
                                  ? AppColors.textLight
                                  : _enLigne
                                  ? AppColors.success
                                  : AppColors.textLight,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: AnimatedAlign(
                              duration: const Duration(milliseconds: 200),
                              alignment: _enLigne
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Container(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 2),
                                width: 20,
                                height: 20,
                                decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 8)
                      ],
                    ),
                    child: Stack(
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
                  ),
                ],
              ),
            ),

            // ─── Gains du jour ─────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            shape: BoxShape.circle),
                        child: const Icon(Icons.payments_outlined,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('GAINS DU JOUR',
                              style: TextStyle(
                                  fontSize: 10,
                                  color: AppColors.textLight,
                                  letterSpacing: 1)),
                          Text(
                            '${_stats?['gains_du_jour'] ?? 0} FCFA',
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: AppColors.textDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ─── Contenu principal ─────────────────────────────────────
            Expanded(
              child: _currentTab == 2
                  ? _HistoriqueConducteur(stats: _stats)
                  : _loadingValidation
                  ? const Center(
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              )
                  : !_estValide
                  ? const _ValidationEnAttenteWidget()
                  : ConducteurMapView(
                lat: _lat,
                lng: _lng,
                enLigne: _enLigne,
                typeVehicule: _typeVehicule,
              ),
            ),

            // ─── Panel demandes proches (uniquement si validé) ─────────
            if (_currentTab != 2 && _estValide && !_loadingValidation)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Demandes proches',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark)),
                        const Spacer(),
                        if (_enLigne)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                                '${_coursesProches.length} DISPO',
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (!_enLigne)
                      _MessageEtat(
                          icon: Icons.power_settings_new_rounded,
                          message:
                          'Passez EN LIGNE pour recevoir des demandes',
                          color: AppColors.textLight)
                    else if (_loadingCourses)
                      const _MessageEtat(
                          icon: Icons.search_rounded,
                          message: 'Recherche de courses...',
                          color: AppColors.primary,
                          showLoading: true)
                    else if (_coursesProches.isEmpty)
                        const _MessageEtat(
                            icon: Icons.location_searching_rounded,
                            message:
                            'Aucune demande à proximité pour le moment',
                            color: AppColors.textMedium)
                      else
                        SizedBox(
                          height: 280,
                          child: ListView.builder(
                            itemCount: _coursesProches.length,
                            itemBuilder: (context, index) {
                              final course = _coursesProches[index];
                              return _CourseCard(
                                  course: course,
                                  onAccepter: () =>
                                      _accepterCourse(course));
                            },
                          ),
                        ),
                  ],
                ),
              ),

            // ─── Bottom navigation ─────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4))
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                      icon: Icons.home_rounded,
                      label: 'ACCUEIL',
                      active: _currentTab == 0,
                      onTap: () => setState(() => _currentTab = 0)),
                  _NavItem(
                      icon: Icons.explore_outlined,
                      label: 'DEMANDES',
                      active: _currentTab == 1,
                      onTap: () => setState(() => _currentTab = 1)),
                  _NavItem(
                      icon: Icons.history_rounded,
                      label: 'HISTORIQUE',
                      active: _currentTab == 2,
                      onTap: () {
                        setState(() => _currentTab = 2);
                        _loadStats();
                      }),
                  _NavItem(
                      icon: Icons.logout_rounded,
                      label: 'DECONNECTER',
                      active: false,
                      onTap: _deconnexion),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Widget écran d'attente de validation ─────────────────────────────────────

class _ValidationEnAttenteWidget extends StatelessWidget {
  const _ValidationEnAttenteWidget();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.8, end: 1.0),
            duration: const Duration(seconds: 1),
            curve: Curves.elasticOut,
            builder: (_, value, child) =>
                Transform.scale(scale: value, child: child),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.hourglass_top_rounded,
                size: 55,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 28),
          const Text(
            'Compte en attente\nde validation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: AppColors.textDark,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Vos documents ont bien été reçus. Un régulateur '
                'va vérifier vos informations et activer votre compte '
                'dans les plus brefs délais.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textMedium,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          _EtapeRow(
            numero: '1',
            titre: 'Documents soumis',
            description: 'Permis, CNI et photo de l\'engin',
            done: true,
          ),
          const SizedBox(height: 10),
          _EtapeRow(
            numero: '2',
            titre: 'Vérification en cours',
            description: 'Un régulateur examine vos documents',
            done: false,
          ),
          const SizedBox(height: 10),
          _EtapeRow(
            numero: '3',
            titre: 'Activation du compte',
            description: 'Vous recevrez une confirmation',
            done: false,
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _EtapeRow extends StatelessWidget {
  final String numero;
  final String titre;
  final String description;
  final bool done;

  const _EtapeRow({
    required this.numero,
    required this.titre,
    required this.description,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: done ? AppColors.success : AppColors.border,
          width: done ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: done
                  ? AppColors.success.withOpacity(0.12)
                  : AppColors.primary.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: done
                ? const Icon(Icons.check_rounded,
                color: AppColors.success, size: 20)
                : Center(
              child: Text(
                numero,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titre,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: done ? AppColors.success : AppColors.textDark,
                  ),
                ),
                Text(
                  description,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMedium),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Historique conducteur ────────────────────────────────────────────────────

class _HistoriqueConducteur extends StatelessWidget {
  final Map<String, dynamic>? stats;
  const _HistoriqueConducteur({this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats == null) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    final historique = stats!['historique'] as List? ?? [];
    if (historique.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: AppColors.border),
            SizedBox(height: 12),
            Text('Aucune course pour le moment',
                style:
                TextStyle(color: AppColors.textMedium, fontSize: 15)),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: historique.length,
      itemBuilder: (_, i) {
        final c = historique[i] as Map<String, dynamic>;
        final statut = c['statut']?.toString() ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (statut == 'TERMINEE'
                      ? AppColors.success
                      : AppColors.error)
                      .withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statut == 'TERMINEE' ? ' Terminée' : ' Annulée',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: statut == 'TERMINEE'
                          ? AppColors.success
                          : AppColors.error),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  c['destination_adresse']?.toString() ??
                      'Destination inconnue',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${c['prix_final'] != null ? (c['prix_final'] as num).toInt() : (c['prix_estime'] != null ? (c['prix_estime'] as num).toInt() : 0)} F',
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppColors.textDark),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Widgets internes ─────────────────────────────────────────────────────────

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
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: AppColors.border, shape: BoxShape.circle),
                child: const Icon(Icons.person_rounded,
                    color: AppColors.textMedium),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Nouveau passager',
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: AppColors.textDark)),
                    Row(
                      children: [
                        const Icon(Icons.route_rounded,
                            color: AppColors.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(
                            '${course.distanceKm?.toStringAsFixed(1) ?? "?"} km',
                            style: const TextStyle(
                                color: AppColors.textMedium, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${course.prixEstime?.toInt() ?? 0} F',
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                          color: AppColors.textDark)),
                  Text(course.modePaiement ?? 'ESPÈCES',
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textMedium)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Column(children: [
                Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: AppColors.success, shape: BoxShape.circle)),
                Container(
                    width: 2, height: 20, color: AppColors.border),
                Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                        color: AppColors.primary, shape: BoxShape.circle)),
              ]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(course.departAdresse ?? 'Départ',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 12),
                    Text(course.destinationAdresse ?? 'Destination',
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textDark),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: onAccepter,
              child: const Text('ACCEPTER LA COURSE',
                  style: TextStyle(letterSpacing: 1)),
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
  const _MessageEtat(
      {required this.icon,
        required this.message,
        required this.color,
        this.showLoading = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 48, color: color.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w500)),
          if (showLoading) ...[
            const SizedBox(height: 16),
            SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: color)),
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
                  color: active
                      ? AppColors.primary
                      : AppColors.textLight)),
        ],
      ),
    );
  }
}
