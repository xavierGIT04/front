import 'package:flutter/material.dart';
import '../utils/app_theme.dart';
import 'login_screen.dart';

class ValidationEnAttenteScreen extends StatelessWidget {
  const ValidationEnAttenteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icône animée
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.8, end: 1.0),
                duration: const Duration(seconds: 1),
                curve: Curves.elasticOut,
                builder: (_, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 36),

              const Text(
                'Compte en cours\nde validation',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Vos documents ont bien été reçus.\nUn régulateur va vérifier vos informations '
                'et activer votre compte dans les plus brefs délais.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.textMedium,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 40),

              // Étapes de validation
              _EtapeCard(
                numero: '1',
                titre: 'Documents reçus',
                description: 'Permis, CNI et photo de l\'engin',
                done: true,
              ),
              const SizedBox(height: 12),
              _EtapeCard(
                numero: '2',
                titre: 'Vérification en cours',
                description: 'Un régulateur examine vos documents',
                done: false,
              ),
              const SizedBox(height: 12),
              _EtapeCard(
                numero: '3',
                titre: 'Activation du compte',
                description: 'Vous recevrez une confirmation',
                done: false,
              ),

              const SizedBox(height: 48),

              // Bouton retour connexion
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: () => Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Retour à la connexion',
                    style: TextStyle(
                      color: AppColors.textDark,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              const Text(
                'Réessayez de vous connecter une fois votre\ncompte activé par le régulateur.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EtapeCard extends StatelessWidget {
  final String numero;
  final String titre;
  final String description;
  final bool done;

  const _EtapeCard({
    required this.numero,
    required this.titre,
    required this.description,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
                : Text(
                    numero,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
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
                    fontSize: 14,
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
