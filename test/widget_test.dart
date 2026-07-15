import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aqua_pure_water/main.dart';

void main() {
  testWidgets('App displays configuration error when Firebase is not initialized', (WidgetTester tester) async {
    // Build our app with firebaseInitialized = false.
    await tester.pumpWidget(const MyApp(firebaseInitialized: false));

    // Verify that the config instructions screen is rendered.
    expect(find.text('Configuration Needed'), findsOneWidget);
    expect(find.text('Firebase Project Configuration Required'), findsOneWidget);
    expect(find.text('Steps to Setup:'), findsOneWidget);
  });
}
