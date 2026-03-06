import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import 'notation_screen.dart';

///  Écran de paiement mobile (TMONEY ou MOOV_MONEY uniquement)
/// Interface simplifiée : 4 chiffres + confirmation
class PaiementScreen extends StatefulWidget {
  final CourseModel course;
  const PaiementScreen({super.key, required this.course});

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  late CourseModel _course;
  bool _loading = false;

  //  Contrôleurs pour les 4 chiffres
  final List<TextEditingController> _pinCtrls = List.generate(
    4,
        (_) => TextEditingController(),
  );
  final List<FocusNode> _pinNodes = List.generate(4, (_) => FocusNode());

  @override
  void initState() {
    super.initState();
    _course = widget.course;
  }

  @override
  void dispose() {
    for (final ctrl in _pinCtrls) {
      ctrl.dispose();
    }
    for (final node in _pinNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _pin => _pinCtrls.map((c) => c.text).join();

  void _onPinChanged(int index, String value) {
    // On ajoute setState ici pour que le bouton "CONFIRMER"
    // vérifie la condition _pin.length == 4 à chaque frappe.
    setState(() {});

    if (value.isNotEmpty && index < 3) {
      _pinNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _pinNodes[index - 1].requestFocus();
    }
  }

  Future<void> _payer() async {
    if (_pin.length < 4) {
      showSnack(context, 'Entrez votre code PIN (4 chiffres)', error: true);
      return;
    }

    setState(() => _loading = true);
    try {
      await CourseApiService.payer(
        courseId: _course.id,
        modePaiement: _course.modePaiement ?? 'TMONEY',
        codePin: _pin,
      );

      if (!mounted) return;

      //  Redirection vers notation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => NotationScreen(course: _course),
        ),
      );
    } catch (e) {
      if (mounted) {
        showSnack(
          context,
          e.toString().replaceAll('Exception: ', ''),
          error: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String get _operateur {
    if (_course.modePaiement == 'MOOV_MONEY') return 'Moov Money';
    return 'T-Money';
  }

  IconData get _operateurIcon {
    if (_course.modePaiement == 'MOOV_MONEY') {
      return Icons.account_balance_wallet_rounded;
    }
    return Icons.phone_android_rounded;
  }

  Color get _operateurColor {
    if (_course.modePaiement == 'MOOV_MONEY') {
      return const Color(0xFF0066CC); // Bleu Moov
    }
    return const Color(0xFFFF6B00); // Orange T-Money
  }

  @override
  Widget build(BuildContext context) {
    final prix = _course.prixFinal ?? _course.prixEstime ?? 0;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ─── Header ──────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _operateurColor,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(_operateurIcon,
                            color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Paiement $_operateur',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'Entrez votre code PIN',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Montant
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'MONTANT À PAYER',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${prix.toInt()} FCFA',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const SizedBox(height: 12),

                    //  Interface simulation USSD simplifiée
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.lock_outline,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Code PIN de confirmation',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Simulation USSD',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textMedium,
                            ),
                          ),
                          const SizedBox(height: 28),

                          //  4 champs pour le code PIN
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(4, (i) {
                              return SizedBox(
                                width: 64,
                                height: 72,
                                child: TextField(
                                  controller: _pinCtrls[i],
                                  focusNode: _pinNodes[i],
                                  textAlign: TextAlign.center,
                                  keyboardType: TextInputType.number,
                                  maxLength: 1,
                                  obscureText: true,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textDark,
                                  ),
                                  decoration: InputDecoration(
                                    counterText: '',
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: const BorderSide(
                                          color: AppColors.border),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      borderSide: BorderSide(
                                        color: _operateurColor,
                                        width: 2.5,
                                      ),
                                    ),
                                  ),
                                  onChanged: (v) => _onPinChanged(i, v),
                                ),
                              );
                            }),
                          ),

                          const SizedBox(height: 24),

                          // Info sécurité
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline,
                                    color: _operateurColor, size: 20),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'Votre code PIN est sécurisé et ne sera jamais stocké.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMedium,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Résumé trajet
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Résumé de la course',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: AppColors.textDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            icon: Icons.place,
                            color: AppColors.success,
                            text: _course.departAdresse ?? 'Départ',
                          ),
                          const SizedBox(height: 10),
                          _InfoRow(
                            icon: Icons.flag,
                            color: AppColors.primary,
                            text: _course.destinationAdresse ?? 'Destination',
                          ),
                          if (_course.conducteur != null) ...[
                            const SizedBox(height: 10),
                            _InfoRow(
                              icon: Icons.person_rounded,
                              color: AppColors.textMedium,
                              text: _course.conducteur!.nomComplet,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ─── Bouton confirmation ─────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(20),
              child: AppButton(
                label: 'CONFIRMER LE PAIEMENT',
                onPressed: _pin.length == 4 ? _payer : null,
                loading: _loading,
                icon: Icons.check_circle_outline,
                color: _operateurColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _InfoRow({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 13, color: AppColors.textDark),
          ),
        ),
      ],
    );
  }
}