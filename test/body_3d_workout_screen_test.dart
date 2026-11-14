import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/screens/body_3d_workout_screen.dart';
import 'package:kalori/theme/app_theme.dart';

Widget _ekran() {
  return MaterialApp(theme: AppTheme.dark, home: const Body3DWorkoutScreen());
}

void main() {
  testWidgets('vücut tipi seçimi egzersiz şemasını günceller', (tester) async {
    await tester.pumpWidget(_ekran());
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Ektomorf'), findsOneWidget);
    expect(find.text('Mezomorf'), findsOneWidget);
    expect(find.text('Endomorf'), findsOneWidget);

    await tester.tap(find.text('Endomorf'));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.textContaining('Superset'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -650));
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Göğüs Egzersizleri'), findsOneWidget);
    expect(find.text('Bench Press'), findsOneWidget);
    expect(find.text('3 × 12-15'), findsWidgets);

    await tester.ensureVisible(find.text('Bacak'));
    await tester.pump(const Duration(milliseconds: 200));
    await tester.tap(find.text('Bacak'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Bacak Egzersizleri'), findsOneWidget);
    expect(find.text('Back Squat'), findsOneWidget);
    expect(find.text('3 × 12-15'), findsWidgets);
  });

  testWidgets('kas haritasına dokunmak bölgeyi değiştirir', (tester) async {
    await tester.pumpWidget(_ekran());
    await tester.pumpAndSettle();

    final Finder harita = find.byKey(const ValueKey<String>('kasHaritasi'));
    await tester.ensureVisible(harita);
    await tester.pumpAndSettle();

    final Offset solUst = tester.getTopLeft(harita);
    final Size boyut = tester.getSize(harita);

    // Önce bacak bölgesine dokun.
    await tester.tapAt(
      solUst + Offset(boyut.width * 0.425, boyut.height * 0.65),
    );
    await tester.pumpAndSettle();

    // Harita başlığındaki bölge rozeti anında güncellenir.
    expect(find.text('BACAK'), findsOneWidget);

    // Sonra göğüs bölgesine dokun (sağ pektoral).
    await tester.tapAt(
      solUst + Offset(boyut.width * 0.56, boyut.height * 0.25),
    );
    await tester.pumpAndSettle();

    expect(find.text('GÖĞÜS'), findsOneWidget);
  });
}
