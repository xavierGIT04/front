// lib/screens/passager_home_screen.dart
// Wrapper de compatibilité — redirige vers l'écran passager réel
import 'package:flutter/material.dart';
import 'passager/passager_home_screen.dart' as p;

class PassagerHomeScreen extends StatelessWidget {
  const PassagerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const p.PassagerHomeScreen();
  }
}
