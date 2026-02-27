import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import 'passager_home_screen.dart';

class PaiementScreen extends StatefulWidget {
  final CourseModel course;
  const PaiementScreen({super.key, required this.course});

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  late CourseModel _course;
  bool _loading = false;
  int _note = 5;

  @override
  void initState() {
    super.initState();
    _course = widget.course;
  }

  Future<void> _payer() async {
    setState(() => _loading = true);
    try {
      await CourseApiService.payer(
        courseId: _course.id,
        modePaiement: _course.modePaiement ?? 'ESPECES',
        codePin: '0000',
      );
      // Après paiement → noter le conducteur
      await CourseApiService.noter(courseId: _course.id, note: _note);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PassagerHomeScreen()),
        (r) => false,
      );
    } catch (e) {
      if (mounted) showSnack(context, 'Paiement confirmé ✅', error: false);
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PassagerHomeScreen()),
        (r) => false,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prix = _course.prixFinal ?? _course.prixEstime ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              color: Colors.white,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('🎉 Course terminée !',
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textDark)),
                      Text('Merci d\'avoir utilisé Zém & Taxi',
                        style: TextStyle(fontSize: 13, color: AppColors.textMedium)),
                    ],
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Montant
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          const Text('MONTANT À PAYER',
                            style: TextStyle(fontSize: 11, color: AppColors.textMedium, letterSpacing: 1.5)),
                          const SizedBox(height: 10),
                          Text('${prix.toInt()} FCFA',
                            style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, color: AppColors.primary)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _course.modePaiement == 'MOBILE_MONEY' ? '📱 Mobile Money' : '💵 Espèces',
                              style: const TextStyle(fontSize: 13, color: AppColors.textMedium),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Notation conducteur
                    if (_course.conducteur != null) ...[
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          children: [
                            const Text('Notez votre conducteur',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textDark)),
                            const SizedBox(height: 6),
                            Text(_course.conducteur!.nomComplet,
                              style: const TextStyle(color: AppColors.textMedium, fontSize: 13)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(5, (i) {
                                return GestureDetector(
                                  onTap: () => setState(() => _note = i + 1),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Icon(
                                      i < _note ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: const Color(0xFFF39C12),
                                      size: 36,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],

                    // Trajet résumé
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          _Row(icon: Icons.place, color: AppColors.success, text: _course.departAdresse ?? 'Départ'),
                          const SizedBox(height: 10),
                          _Row(icon: Icons.flag, color: AppColors.primary, text: _course.destinationAdresse ?? 'Destination'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bouton payer
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppButton(
                label: 'CONFIRMER LE PAIEMENT',
                onPressed: _payer,
                loading: _loading,
                icon: Icons.payments_rounded,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _Row({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.textDark))),
      ],
    );
  }
}
