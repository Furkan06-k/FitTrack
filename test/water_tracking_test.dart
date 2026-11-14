import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/main.dart';
import 'package:kalori/state/app_state.dart';

void main() {
  group('AppState su takibi', () {
    test('su ekleme, azaltma ve sıfırlama çalışır', () {
      final AppState state = AppState();

      expect(state.suMl, 0);
      expect(state.suOrani, 0);

      state.suEkle(250);
      expect(state.suMl, 250);
      expect(state.kalanSuMl, 2750);

      state.suEkle(500);
      expect(state.suMl, 750);

      state.suAzalt(250);
      expect(state.suMl, 500);

      state.suAzalt(9999);
      expect(state.suMl, 0);

      state.suEkle(1000);
      state.suSifirla();
      expect(state.suMl, 0);
    });

    test('su hedefi sınırlar içinde güncellenir', () {
      final AppState state = AppState();

      state.suHedefGuncelle(4000);
      expect(state.suHedefMl, 4000);

      state.suHedefGuncelle(100);
      expect(state.suHedefMl, 500);

      state.suHedefGuncelle(20000);
      expect(state.suHedefMl, 8000);
    });

    test('hedef kaydı su hedefini kiloya göre günceller', () {
      final AppState state = AppState();

      state.hedefKaydet(
        boy: 180,
        kilo: 100,
        hedefKilo: 90,
        kalori: 2200,
        protein: 200,
      );

      expect(state.suHedefMl, 3500);
    });
  });

  testWidgets('Su kartından su ekranı açılır ve su eklenebilir', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const KaloriApp());
    await tester.pumpAndSettle();

    expect(find.text('Su Takibi'), findsOneWidget);

    await tester.tap(find.text('Su Takibi'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Günlük Su Hedefin'), findsOneWidget);

    await tester.tap(find.text('1 Bardak Ekle  ·  250 ml'));
    await tester.pump();

    expect(find.text('0.25 L'), findsWidgets);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));

    expect(find.text('Bugünün Özeti'), findsOneWidget);
    expect(find.textContaining('0.25 / 3.00 L'), findsOneWidget);
  });
}
