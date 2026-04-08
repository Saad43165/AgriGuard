// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child species in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:agriguard_fyp/main.dart';

void main() {
  testWidgets('App widget can be pumped in tests', (WidgetTester tester) async {
    // In widget tests we avoid Firebase + providers by using AgriGuardApp overrides.
    await tester.pumpWidget(
      AgriGuardApp(
        themeOverride: ThemeData.light(),
        homeOverride: const SizedBox.shrink(),
      ),
    );

    expect(find.byType(AgriGuardApp), findsOneWidget);
  });
}
