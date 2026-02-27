import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../utils/app_theme.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  List<CourseModel> _courses = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistorique();
  }

  Future<void> _loadHistorique() async {
    setState(() { _loading = true; _error = null; });
    try {
      final courses = await CourseApiService.getHistoriquePassager();
      if (mounted) setState(() { _courses = courses; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.border),
            const SizedBox(height: 12),
            const Text('Impossible de charger\nl\'historique',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textMedium, fontSize: 15)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadHistorique,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_courses.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.history_rounded, size: 64, color: AppColors.border),
            SizedBox(height: 12),
            Text('Aucune course pour le moment',
              style: TextStyle(color: AppColors.textMedium, fontSize: 15)),
            SizedBox(height: 6),
            Text('Vos courses apparaîtront ici',
              style: TextStyle(color: AppColors.textLight, fontSize: 13)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadHistorique,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _courses.length,
        itemBuilder: (_, i) {
          final c = _courses[i];
          return _CourseHistoriqueCard(course: c);
        },
      ),
    );
  }
}

class _CourseHistoriqueCard extends StatelessWidget {
  final CourseModel course;
  const _CourseHistoriqueCard({required this.course});

  @override
  Widget build(BuildContext context) {
    final isTerminee = course.statut == 'TERMINEE';
    final prix = course.prixFinal ?? course.prixEstime ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // En-tête
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: (isTerminee ? AppColors.success : AppColors.error).withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isTerminee ? AppColors.success : AppColors.error).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isTerminee ? '✅ Terminée' : '❌ Annulée',
                    style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold,
                      color: isTerminee ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
                const Spacer(),
                Text('${prix.toInt()} FCFA',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.textDark)),
              ],
            ),
          ),

          // Trajet
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(course.departAdresse ?? 'Départ',
                      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Container(width: 2, height: 16, color: AppColors.border),
                ),
                Row(
                  children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(course.destinationAdresse ?? 'Destination',
                      style: const TextStyle(fontSize: 13, color: AppColors.textDark),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ],
            ),
          ),

          // Conducteur + note
          if (course.conducteur != null || course.distanceKm != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  if (course.conducteur != null) ...[
                    const Icon(Icons.person_rounded, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text(course.conducteur!.nomComplet,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                    const SizedBox(width: 12),
                  ],
                  if (course.distanceKm != null) ...[
                    const Icon(Icons.route_rounded, size: 14, color: AppColors.textLight),
                    const SizedBox(width: 4),
                    Text('${course.distanceKm!.toStringAsFixed(1)} km',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                  ],
                  const Spacer(),
                  if (course.noteConducteur != null)
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < (course.noteConducteur ?? 0) ? Icons.star_rounded : Icons.star_outline_rounded,
                        size: 14,
                        color: const Color(0xFFF39C12),
                      )),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
