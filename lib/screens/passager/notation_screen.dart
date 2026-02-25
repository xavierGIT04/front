import 'package:flutter/material.dart';
import '../../models/course_model.dart';
import '../../services/course_api_service.dart';
import '../../utils/app_theme.dart';
import '../../utils/widgets.dart';
import 'passager_home_screen.dart';

class NotationScreen extends StatefulWidget {
  final CourseModel course;
  const NotationScreen({super.key, required this.course});

  @override
  State<NotationScreen> createState() => _NotationScreenState();
}

class _NotationScreenState extends State<NotationScreen>
    with SingleTickerProviderStateMixin {
  int _note = 0;
  final _commentCtrl = TextEditingController();
  bool _loading = false;
  bool _done = false;
  late AnimationController _anim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _scaleAnim = CurvedAnimation(parent: _anim, curve: Curves.elasticOut);
    _anim.forward();
  }

  Future<void> _noter() async {
    if (_note == 0) {
      showSnack(context, 'Choisissez une note', error: true);
      return;
    }
    setState(() => _loading = true);
    try {
      await CourseApiService.noter(
        courseId: widget.course.id,
        note: _note,
        commentaire: _commentCtrl.text,
      );
      setState(() { _done = true; _loading = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const PassagerHomeScreen()),
        (r) => false,
      );
    } catch (e) {
      showSnack(context, e.toString().replaceAll('Exception: ', ''), error: true);
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _anim.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_done) return _SuccessScreen();

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Icône succès paiement
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100, height: 100,
                  decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 55),
                ),
              ),
              const SizedBox(height: 20),

              const Text('Paiement réussi !',
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.textDark)),
              Text('${widget.course.prixEstime?.toInt() ?? 0} FCFA payés',
                style: const TextStyle(color: AppColors.textMedium, fontSize: 16)),
              const SizedBox(height: 40),

              // Notation
              const Text('Comment était votre course ?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              const SizedBox(height: 6),
              Text('Notez ${widget.course.conducteur?.prenom ?? "votre conducteur"}',
                style: const TextStyle(color: AppColors.textMedium)),
              const SizedBox(height: 20),

              // Étoiles
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _note = i + 1),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        i < _note ? Icons.star_rounded : Icons.star_border_rounded,
                        color: i < _note ? AppColors.primary : AppColors.border,
                        size: 44,
                      ),
                    ),
                  );
                }),
              ),

              if (_note > 0) ...[
                const SizedBox(height: 8),
                Text(_ratingLabel(_note),
                  style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 15)),
              ],

              const SizedBox(height: 24),

              // Commentaire optionnel
              TextField(
                controller: _commentCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Laisser un commentaire (optionnel)...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              PrimaryButton(
                label: 'Valider la note',
                onPressed: _note > 0 ? _noter : null,
                isLoading: _loading,
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.pushAndRemoveUntil(context,
                  MaterialPageRoute(builder: (_) => const PassagerHomeScreen()), (r) => false),
                child: const Text('Passer', style: TextStyle(color: AppColors.textMedium)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _ratingLabel(int note) {
    switch (note) {
      case 1: return 'Très mauvais 😞';
      case 2: return 'Mauvais 😐';
      case 3: return 'Correct 🙂';
      case 4: return 'Bien 😊';
      case 5: return 'Excellent ! 🌟';
      default: return '';
    }
  }
}

class _SuccessScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.success,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 100),
            SizedBox(height: 20),
            Text('Merci pour votre note !',
              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Redirection...', style: TextStyle(color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}
