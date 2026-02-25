import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import '../login_screen.dart';

class Step4PassagerScreen extends StatefulWidget {
  final String telephone;
  final String nom;
  final String prenom;
  final String password;

  const Step4PassagerScreen({
    super.key,
    required this.telephone,
    required this.nom,
    required this.prenom,
    required this.password,
  });

  @override
  State<Step4PassagerScreen> createState() => _Step4PassagerScreenState();
}

class _Step4PassagerScreenState extends State<Step4PassagerScreen> {
  bool _loading = false;

  Future<void> _inscrire() async {
    setState(() => _loading = true);
    try {
      await ApiService.registerPassager(
        telephone: widget.telephone,
        nom: widget.nom,
        prenom: widget.prenom,
        password: widget.password,
      );
      if (!mounted) return;
      showSnack(context, '🎉 Inscription réussie ! Connectez-vous.');
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return;
      // Retour vers Login en vidant la pile
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      showSnack(context, e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const StepIndicator(currentStep: 3, totalSteps: 4),
              const SizedBox(height: 32),

              // Illustration
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF2196F3).withOpacity(0.15),
                        const Color(0xFF2196F3).withOpacity(0.05),
                      ],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_pin_circle_rounded,
                    size: 52,
                    color: Color(0xFF2196F3),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              const Text(
                'Compte Passager',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tout est prêt ! Vérifiez vos informations avant de valider.',
                style: TextStyle(fontSize: 14, color: AppColors.textMedium),
              ),
              const SizedBox(height: 32),

              // Récapitulatif
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _InfoRow(
                        icon: Icons.person_outline,
                        label: 'Prénom',
                        value: widget.prenom),
                    const Divider(height: 20),
                    _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Nom',
                        value: widget.nom),
                    const Divider(height: 20),
                    _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Téléphone',
                        value: '+228 ${widget.telephone}'),
                    const Divider(height: 20),
                    _InfoRow(
                        icon: Icons.shield_outlined,
                        label: 'Rôle',
                        value: 'Passager'),
                  ],
                ),
              ),
              const Spacer(),
              PrimaryButton(
                label: "Terminer l'inscription",
                onPressed: _inscrire,
                isLoading: _loading,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 12),
        Text(label,
            style:
                const TextStyle(color: AppColors.textMedium, fontSize: 13)),
        const Spacer(),
        Text(
          value,
          style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
              fontSize: 14),
        ),
      ],
    );
  }
}
