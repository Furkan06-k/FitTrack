import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/fitness_models.dart';
import 'package:kalori/screens/activity_tracker_screen.dart';
import 'package:kalori/state/app_state.dart';
import 'package:kalori/theme/app_theme.dart';

void main() {
  testWidgets('aktivite ekranı çalışır ve kayıt oluşturur', (tester) async {
    final AppState state = AppState(kilo: 80);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ActivityTrackerScreen(state: state),
      ),
    );

    expect(find.text('Canlı Aktivite Takibi'), findsOneWidget);

    await tester.ensureVisible(find.text('Etkinliği Başlat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Etkinliği Başlat'));
    await tester.pump();

    expect(find.text('Duraklat'), findsOneWidget);

    // Kronometre gerçek zamanı ölçtüğü için kısa bir gerçek bekleme gerekir.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 1300)),
    );
    // 1 sn'lik kronometre tiki butonu yeniden derler (etkinleştirir).
    await tester.pump(const Duration(seconds: 1));

    await tester.ensureVisible(find.text('Bitir ve Kaydet'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bitir ve Kaydet'));
    await tester.pumpAndSettle();

    expect(state.aktiviteler.length, 1);
    expect(state.aktiviteler.first.tur, AktiviteTuru.kosu);
    expect(state.aktiviteler.first.kalori, greaterThan(0));

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Bugün için kayıt yok'), findsNothing);
    expect(find.textContaining('kcal'), findsWidgets);
  });

  testWidgets('günlük, haftalık ve aylık geçmiş görünümü çalışır', (
    tester,
  ) async {
    final AppState state = AppState(
      kilo: 80,
      aktiviteler: <AktiviteKaydi>[
        AktiviteKaydi.olustur(
          tur: AktiviteTuru.bisiklet,
          sure: const Duration(minutes: 40),
          kilo: 80,
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: ActivityTrackerScreen(state: state),
      ),
    );

    await tester.tap(find.text('Bisiklet').first);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();

    expect(find.text('Günlük'), findsOneWidget);
    expect(find.text('Haftalık'), findsOneWidget);
    expect(find.text('Aylık'), findsOneWidget);

    await tester.tap(find.text('Haftalık'));
    await tester.pumpAndSettle();

    expect(find.text('Bugün'), findsOneWidget);
    expect(find.textContaining('40 dk'), findsWidgets);
    expect(find.textContaining('Bisiklet'), findsWidgets);

    await tester.tap(find.text('Aylık'));
    await tester.pumpAndSettle();

    expect(find.textContaining('40 dk'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.textContaining('40:00'), findsOneWidget);
  });
}
