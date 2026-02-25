import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import 'step3_info_screen.dart';

class Step2OtpScreen extends StatefulWidget {
  final String telephone;
  final String simulatedCode;

  const Step2OtpScreen({
    super.key,
    required this.telephone,
    required this.simulatedCode,
  });

  @override
  State<Step2OtpScreen> createState() => _Step2OtpScreenState();
}

class _Step2OtpScreenState extends State<Step2OtpScreen> {
  final List<TextEditingController> _ctrl =
      List.generate(4, (_) => TextEditingController());
  final List<FocusNode> _nodes = List.generate(4, (_) => FocusNode());
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    final digits = widget.simulatedCode.split('');
    for (int i = 0; i < digits.length && i < 4; i++) {
      _ctrl[i].text = digits[i];
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      showSnack(context, '📱 Code de simulation : ${widget.simulatedCode}');
    });
  }

  String get _fullCode => _ctrl.map((c) => c.text).join();

  Future<void> _verify() async {
    if (_fullCode.length < 4) {
      showSnack(context, 'Entrez le code à 4 chiffres', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ApiService.verifierOtp(widget.telephone, _fullCode);
      if (result['status'] == 'SUCCESS') {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Step3InfoScreen(telephone: widget.telephone),
          ),
        );
      }
    } catch (e) {
      showSnack(context, e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 3) {
      _nodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _nodes[index - 1].requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
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
                  const StepIndicator(currentStep: 1, totalSteps: 4),
                  const SizedBox(height: 32),

                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.sms_rounded,
                        size: 44,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Code de\nvérification',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDark,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Code envoyé au ${widget.telephone}\n(Le code est pré-rempli en mode simulation)',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textMedium,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Champs OTP
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(4, (i) {
                      return SizedBox(
                        width: 68,
                        height: 72,
                        child: TextFormField(
                          controller: _ctrl[i],
                          focusNode: _nodes[i],
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          maxLength: 1,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                          decoration: InputDecoration(
                            counterText: '',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppColors.primary, width: 2.5),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: AppColors.border),
                            ),
                          ),
                          onChanged: (v) => _onDigitChanged(i, v),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Renvoi code
                  Center(
                    child: TextButton(
                      onPressed: () async {
                        try {
                          final r = await ApiService.demanderOtp(widget.telephone);
                          final code = r['code'] as String;
                          final digits = code.split('');
                          for (int i = 0; i < digits.length && i < 4; i++) {
                            _ctrl[i].text = digits[i];
                          }
                          if (!mounted) return;
                          showSnack(context, '📱 Nouveau code : $code');
                        } catch (_) {}
                      },
                      child: const Text(
                        "Renvoyer le code",
                        style: TextStyle(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),

                  const Spacer(),
                  PrimaryButton(
                    label: 'Valider',
                    onPressed: _verify,
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
    for (final c in _ctrl) {
      c.dispose();
    }
    for (final n in _nodes) {
      n.dispose();
    }
    super.dispose();
  }
}
