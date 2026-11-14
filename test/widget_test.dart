// Bu test, uygulamanın temel ekranlarının açıldığını doğrular.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/main.dart';

void main() {
  testWidgets('Dashboard ve alt gezinme çubuğu görünür', (tester) async {
    await tester.pumpWidget(const KaloriApp());
    await tester.pumpAndSettle();

    expect(find.text('Bugünün Özeti'), findsOneWidget);
    expect(find.text('Özet'), findsOneWidget);
    expect(find.text('Aktivite'), findsOneWidget);
    expect(find.text('Beslenme'), findsOneWidget);
    expect(find.text('Vücut'), findsOneWidget);
    expect(find.text('Antrenman'), findsOneWidget);
    expect(find.text('Hesapla'), findsOneWidget);
  });

  testWidgets('Alt gezinme çubuğu ekranlar arasında geçiş yapar', (
    tester,
  ) async {
    await tester.pumpWidget(const KaloriApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Antrenman'));
    await tester.pumpAndSettle();
    expect(find.text('Bugünkü Performans'), findsOneWidget);

    await tester.tap(find.text('Hesapla'));
    await tester.pumpAndSettle();
    expect(find.text('Hedefini Belirle'), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
