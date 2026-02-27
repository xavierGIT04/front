import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zem_taxi/main.dart'; // ⚠️ adapte selon le nom réel de ton package

void main() {
  testWidgets('L\'app démarre sans crash', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const TripApp());

    // Vérifier que l'app se lance (l'écran de démarrage ou de login s'affiche)
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
