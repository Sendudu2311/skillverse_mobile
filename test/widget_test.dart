// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:skillverse_mobile/presentation/app.dart';

void main() {
  testWidgets('SkillVerseApp renders without error', (WidgetTester tester) async {
    // Build SkillVerseApp and trigger a frame.
    await tester.pumpWidget(const SkillVerseApp());

    // Check for main dashboard content
    expect(find.textContaining('Xin chào'), findsOneWidget);
    // Check that bottom navigation exists
    expect(find.byType(BottomNavigationBar), findsOneWidget);
  });
}
