import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/auth_storage.dart';
import '../utils/app_theme.dart';
import '../utils/widgets.dart';
import 'register/step1_phone_screen.dart';
import 'passager_home_screen.dart';
import 'conducteur_home_screen.dart';
import 'validation_en_attente_screen.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final data = await ApiService.authenticate(
        username: _phoneCtrl.text.trim(),
        password: _passCtrl.text,
      );
      await AuthStorage.saveSession(data);

      final roles = await AuthStorage.getRoles();
      if (!mounted) return;

      if (roles.contains('ROLE_CONDUCTEUR')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ConducteurHomeScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const PassagerHomeScreen()),
        );
      }
    } on AccountDisabledException {
      // Compte conducteur non encore validé par le régulateur
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => const ValidationEnAttenteScreen()),
      );
    } catch (e) {
      showSnack(
        context,
        e.toString().replaceAll('Exception: ', ''),
        error: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Logo + titre
                Center(child: const AppLogo()),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    'ZemExpress',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                    ),
                  ),
                ),
                const Center(
                  child: Text(
                    'Votre transport au Togo',
                    style: TextStyle(fontSize: 14, color: AppColors.textMedium),
                  ),
                ),
                const SizedBox(height: 40),

                const Text(
                  'Connexion',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 28),

                // Téléphone
                const Text(
                  'Numéro de téléphone',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  maxLength: 8, // Limite physique à 8 caractères
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly, // Autorise uniquement 0-9
                    LengthLimitingTextInputFormatter(8),    // Sécurité supplémentaire pour bloquer à 8
                  ],
                  decoration: const InputDecoration(
                    prefixIcon: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text('🇹🇬  +228',
                          style: TextStyle(fontSize: 15)),
                    ),
                    hintText: '90 00 00 00',
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Entrez votre numéro' : null,
                ),
                const SizedBox(height: 16),

                // Mot de passe
                const Text(
                  'Mot de passe',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.textLight),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textLight,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    ),
                    hintText: '••••••••',
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Entrez votre mot de passe'
                      : null,
                ),
                const SizedBox(height: 10),


                const SizedBox(height: 10),

                PrimaryButton(
                  label: 'Se connecter',
                  onPressed: _login,
                  isLoading: _loading,
                ),
                const SizedBox(height: 24),

                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Pas encore de compte ? ",
                        style: TextStyle(color: AppColors.textMedium),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const Step1PhoneScreen()),
                        ),
                        child: const Text(
                          "S'inscrire",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Badge plateforme officielle
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'PASSAGER & CONDUCTEUR',
                          style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textLight,
                              letterSpacing: 1.2),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'PLATEFORME OFFICIELLE DISPONIBLE',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}
