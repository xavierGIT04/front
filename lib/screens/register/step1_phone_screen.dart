import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import 'step2_otp_screen.dart';
import 'package:flutter/services.dart';


class Step1PhoneScreen extends StatefulWidget {
  const Step1PhoneScreen({super.key});

  @override
  State<Step1PhoneScreen> createState() => _Step1PhoneScreenState();
}

class _Step1PhoneScreenState extends State<Step1PhoneScreen> {
  final _phoneCtrl = TextEditingController();
  bool _loading = false;

  Future<void> _requestOtp() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 8) {
      showSnack(context, 'Entrez un numéro valide', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ApiService.demanderOtp(phone);
      // Le backend renvoie le code en simulation
      final code = result['code'] as String;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Step2OtpScreen(telephone: phone, simulatedCode: code),
        ),
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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom -
                  kToolbarHeight,
            ),
            child: IntrinsicHeight(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const StepIndicator(currentStep: 0, totalSteps: 4),
                  const SizedBox(height: 32),

                  // Illustration
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Votre numéro\nde téléphone',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Nous vous enverrons un code de vérification\npour confirmer votre identité.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Champ téléphone
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        // Préfixe pays
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 17),
                          decoration: const BoxDecoration(
                            border: Border(
                                right: BorderSide(color: AppColors.border)),
                          ),
                          child: const Row(
                            children: [
                              Text('🇹🇬', style: TextStyle(fontSize: 20)),
                              SizedBox(width: 8),
                              Text(
                                '+228',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Input
                        Expanded(
                          child: TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            maxLength: 8, // Limite physique à 8 caractères
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly, // Autorise uniquement 0-9
                              LengthLimitingTextInputFormatter(8),    // Sécurité supplémentaire pour bloquer à 8
                            ],
                            decoration: const InputDecoration(
                              hintText: '90 00 00 00',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 16),
                            ),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 90),
                  PrimaryButton(
                    label: 'Recevoir le code',
                    onPressed: _requestOtp,
                    isLoading: _loading,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }
}

