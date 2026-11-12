import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app_firebase/main.dart';

void main() {
  testWidgets('Firebase dashboard renders its main sections', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Firebase, bajo control.'), findsOneWidget);
    expect(find.text('Datos de usuario'), findsOneWidget);
    expect(find.text('Comprobar conexión'), findsOneWidget);
    expect(find.byIcon(Icons.storage_rounded), findsOneWidget);
  });
}
