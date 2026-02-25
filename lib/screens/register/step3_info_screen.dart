import 'package:flutter/material.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import 'step4_passager_screen.dart';
import 'step4_conducteur_screen.dart';

class Step3InfoScreen extends StatefulWidget {
  final String telephone;

  const Step3InfoScreen({super.key, required this.telephone});

  @override
  State<Step3InfoScreen> createState() => _Step3InfoScreenState();
}

class _Step3InfoScreenState extends State<Step3InfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscure = true;
  bool _obscureConfirm = true;

  void _continuer() {
    if (!_formKey.currentState!.validate()) return;
    if (_passCtrl.text != _confirmPassCtrl.text) {
      showSnack(context, 'Les mots de passe ne correspondent pas', error: true);
      return;
    }
    _choisirProfil();
  }

  void _choisirProfil() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProfilChoiceSheet(
        onPassager: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Step4PassagerScreen(
                telephone: widget.telephone,
                nom: _nomCtrl.text.trim(),
                prenom: _prenomCtrl.text.trim(),
                password: _passCtrl.text,
              ),
            ),
          );
        },
        onConducteur: () {
          Navigator.pop(context);
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => Step4ConducteurScreen(
                telephone: widget.telephone,
                nom: _nomCtrl.text.trim(),
                prenom: _prenomCtrl.text.trim(),
                password: _passCtrl.text,
              ),
            ),
          );
        },
      ),
    );
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StepIndicator(currentStep: 2, totalSteps: 4),
                const SizedBox(height: 32),

                const Text(
                  'Vos informations',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDark,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ces informations seront affichées sur votre profil.',
                  style: TextStyle(fontSize: 14, color: AppColors.textMedium),
                ),
                const SizedBox(height: 28),

                // Téléphone (lecture seule)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.border.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.phone_outlined,
                          color: AppColors.textLight, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        '+228 ${widget.telephone}',
                        style: const TextStyle(
                          color: AppColors.textMedium,
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.check_circle,
                          color: AppColors.success, size: 18),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Prénom
                _buildLabel('Prénom'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _prenomCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Kossi',
                    prefixIcon:
                        Icon(Icons.person_outline, color: AppColors.textLight),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),

                // Nom
                _buildLabel('Nom'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nomCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: 'Ex: Koffi',
                    prefixIcon:
                        Icon(Icons.badge_outlined, color: AppColors.textLight),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 16),

                // Mot de passe
                _buildLabel('Mot de passe'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    hintText: 'Min. 6 caractères',
                    prefixIcon:
                        const Icon(Icons.lock_outline, color: AppColors.textLight),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textLight,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Minimum 6 caractères'
                      : null,
                ),
                const SizedBox(height: 16),

                // Confirmer mot de passe
                _buildLabel('Confirmer le mot de passe'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _confirmPassCtrl,
                  obscureText: _obscureConfirm,
                  decoration: InputDecoration(
                    hintText: 'Répétez le mot de passe',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.textLight),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textLight,
                      ),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Champ requis' : null,
                ),
                const SizedBox(height: 32),

                PrimaryButton(
                  label: 'Continuer',
                  onPressed: _continuer,
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
      ),
    );
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }
}

// ─── Bottom sheet choix profil ────────────────────────────────────────────
class _ProfilChoiceSheet extends StatelessWidget {
  final VoidCallback onPassager;
  final VoidCallback onConducteur;

  const _ProfilChoiceSheet({
    required this.onPassager,
    required this.onConducteur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Vous êtes ?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choisissez votre rôle sur la plateforme',
            style: TextStyle(color: AppColors.textMedium, fontSize: 14),
          ),
          const SizedBox(height: 28),

          // Passager
          _ChoiceCard(
            icon: Icons.person_pin_circle_rounded,
            title: 'Passager',
            subtitle: 'Je recherche un transport',
            color: const Color(0xFF2196F3),
            onTap: onPassager,
          ),
          const SizedBox(height: 14),

          // Conducteur Zém
          _ChoiceCard(
            icon: Icons.motorcycle_rounded,
            title: 'Conducteur Zém',
            subtitle: 'Je propose des courses',
            color: AppColors.primary,
            onTap: onConducteur,
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                        color: AppColors.textMedium, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }
}
