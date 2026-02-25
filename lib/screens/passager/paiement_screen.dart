import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import 'notation_screen.dart';

class PaiementScreen extends StatefulWidget {
  final CourseModel course;
  const PaiementScreen({super.key, required this.course});

  @override
  State<PaiementScreen> createState() => _PaiementScreenState();
}

class _PaiementScreenState extends State<PaiementScreen> {
  String _mode = 'ESPECES';
  bool _showUssd = false;
  bool _loading = false;

  void _choisirMode() {
    if (_mode == 'ESPECES') {
      _payerEspeces();
    } else {
      setState(() => _showUssd = true);
    }
  }

  Future<void> _payerEspeces() async {
    setState(() => _loading = true);
    try {
      final result = await CourseApiService.payer(
        courseId: widget.course.id,
        modePaiement: 'ESPECES',
        codePin: '0000',
      );
      if (!mounted) return;
      _goToNotation(result);
    } catch (e) {
      showSnack(context, e.toString().replaceAll('Exception: ', ''), error: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _goToNotation(CourseModel course) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => NotationScreen(course: course)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: _showUssd
            ? _UssdSimulator(
                course: widget.course,
                mode: _mode,
                onConfirmer: (pin) async {
                  setState(() => _loading = true);
                  try {
                    final result = await CourseApiService.payer(
                      courseId: widget.course.id,
                      modePaiement: _mode,
                      codePin: pin,
                    );
                    if (!mounted) return;
                    _goToNotation(result);
                  } catch (e) {
                    showSnack(context, e.toString().replaceAll('Exception: ', ''), error: true);
                    setState(() { _loading = false; _showUssd = false; });
                  }
                },
                onAnnuler: () => setState(() => _showUssd = false),
                loading: _loading,
              )
            : _ModeChoix(
                course: widget.course,
                modeSelectionne: _mode,
                onModeChange: (m) => setState(() => _mode = m),
                onConfirmer: _choisirMode,
                loading: _loading,
              ),
      ),
    );
  }
}

// ─── Choix du mode de paiement ────────────────────────────────────────────
class _ModeChoix extends StatelessWidget {
  final CourseModel course;
  final String modeSelectionne;
  final Function(String) onModeChange;
  final VoidCallback onConfirmer;
  final bool loading;

  const _ModeChoix({
    required this.course, required this.modeSelectionne,
    required this.onModeChange, required this.onConfirmer, required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.payments_rounded, size: 48, color: AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),

          Text(
            'Payer ${course.prixEstime?.toInt()} FCFA\nà ${course.conducteur?.nomComplet ?? "votre conducteur"} ?',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.textDark, height: 1.3),
          ),
          const SizedBox(height: 8),
          const Center(child: Text('Choisissez votre mode de paiement', style: TextStyle(color: AppColors.textMedium))),
          const SizedBox(height: 32),

          // Mode espèces
          _ModeCard(
            icon: Icons.money_rounded,
            title: 'Espèces',
            subtitle: 'Paiement direct au conducteur',
            selected: modeSelectionne == 'ESPECES',
            onTap: () => onModeChange('ESPECES'),
          ),
          const SizedBox(height: 12),

          // T-Money
          _ModeCard(
            icon: Icons.account_balance_wallet_rounded,
            title: 'T-Money',
            subtitle: 'Paiement via T-Money',
            selected: modeSelectionne == 'TMONEY',
            onTap: () => onModeChange('TMONEY'),
          ),
          const SizedBox(height: 12),

          // Moov Money
          _ModeCard(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Moov Money',
            subtitle: 'Paiement via Moov Money',
            selected: modeSelectionne == 'MOOV_MONEY',
            onTap: () => onModeChange('MOOV_MONEY'),
          ),

          const Spacer(),
          PrimaryButton(label: 'Confirmer', onPressed: onConfirmer, isLoading: loading),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _ModeCard({required this.icon, required this.title, required this.subtitle, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border, width: selected ? 2 : 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: selected ? AppColors.primary : AppColors.textLight, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? AppColors.textDark : AppColors.textDark)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textMedium)),
                ],
              ),
            ),
            if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

// ─── Simulateur USSD ──────────────────────────────────────────────────────
class _UssdSimulator extends StatefulWidget {
  final CourseModel course;
  final String mode;
  final Function(String) onConfirmer;
  final VoidCallback onAnnuler;
  final bool loading;

  const _UssdSimulator({
    required this.course, required this.mode,
    required this.onConfirmer, required this.onAnnuler, required this.loading,
  });

  @override
  State<_UssdSimulator> createState() => _UssdSimulatorState();
}

class _UssdSimulatorState extends State<_UssdSimulator> {
  String _pin = '';

  void _pressKey(String key) {
    if (_pin.length < 4) {
      setState(() => _pin += key);
    }
  }

  void _backspace() {
    if (_pin.isNotEmpty) setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final nomService = widget.mode == 'TMONEY' ? 'T-MONEY' : 'MOOV MONEY';

    return Container(
      color: const Color(0xFFF5F5F0),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // Header USSD
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.account_balance_wallet_rounded, size: 16, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('account_balance_wallet', style: TextStyle(fontSize: 11, color: AppColors.primary)),
                    ],
                  ),
                ),
                const Spacer(),
                const Text('Simulation\nde Paiement',
                  textAlign: TextAlign.right,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Text(nomService,
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark)),
            ),
            const SizedBox(height: 20),

            Text(
              'Payer ${widget.course.prixEstime?.toInt()} FCFA à\n${widget.course.conducteur?.nomComplet ?? "Conducteur"} (Zém) ?',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.textDark, height: 1.3),
            ),
            const SizedBox(height: 4),
            const Text('Entrez votre code PIN', style: TextStyle(color: AppColors.textMedium)),
            const SizedBox(height: 24),

            // Affichage PIN (points)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (i) {
                final filled = i < _pin.length;
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    children: [
                      if (filled)
                        const Icon(Icons.circle, size: 14, color: AppColors.textDark)
                      else
                        const SizedBox(height: 14),
                      const SizedBox(height: 4),
                      Container(
                        width: 48, height: 2,
                        color: filled ? AppColors.primary : AppColors.border,
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 28),

            // Clavier numérique
            _buildKeypad(),
            const Spacer(),

            // Boutons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onAnnuler,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      side: const BorderSide(color: AppColors.border),
                    ),
                    child: const Text('Annuler', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 16)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (_pin.length == 4 && !widget.loading)
                        ? () => widget.onConfirmer(_pin) : null,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: widget.loading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54))
                        : const Text('Confirmer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypad() {
    return Column(
      children: [
        _KeyRow(keys: const ['1', '2', '3'], labels: const ['', 'ABC', 'DEF'], onPress: _pressKey),
        const SizedBox(height: 8),
        _KeyRow(keys: const ['4', '5', '6'], labels: const ['GHI', 'JKL', 'MNO'], onPress: _pressKey),
        const SizedBox(height: 8),
        _KeyRow(keys: const ['7', '8', '9'], labels: const ['PQRS', 'TUV', 'WXYZ'], onPress: _pressKey),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            const SizedBox(width: 100),
            _KeyButton(key: const ValueKey('0'), digit: '0', label: '', onPress: _pressKey),
            SizedBox(
              width: 100, height: 70,
              child: TextButton(
                onPressed: _backspace,
                child: const Text('backspace', style: TextStyle(color: AppColors.textMedium, fontSize: 13)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _KeyRow extends StatelessWidget {
  final List<String> keys;
  final List<String> labels;
  final Function(String) onPress;
  const _KeyRow({required this.keys, required this.labels, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(3, (i) =>
        _KeyButton(key: ValueKey(keys[i]), digit: keys[i], label: labels[i], onPress: onPress),
      ),
    );
  }
}

class _KeyButton extends StatelessWidget {
  final String digit;
  final String label;
  final Function(String) onPress;
  const _KeyButton({super.key, required this.digit, required this.label, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onPress(digit),
      child: Container(
        width: 100, height: 70,
        decoration: BoxDecoration(
          color: const Color(0xFFEEEEE8),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(digit, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w400, color: AppColors.textDark)),
            if (label.isNotEmpty)
              Text(label, style: const TextStyle(fontSize: 9, color: AppColors.textMedium, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }
}
