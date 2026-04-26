import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:digital_khata_new/main.dart';

void main() {
  testWidgets('App launches without error', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(
      child: DigitalKhataApp(),
    ));
    
    // Verify that login screen appears
    expect(find.text('Digital Khata'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Create New Account'), findsOneWidget);
  });
}