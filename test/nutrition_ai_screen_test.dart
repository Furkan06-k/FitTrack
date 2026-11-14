import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kalori/models/fitness_models.dart';
import 'package:kalori/screens/nutrition_ai_screen.dart';
import 'package:kalori/state/app_state.dart';
import 'package:kalori/theme/app_theme.dart';

Widget _ekran(AppState state) {
  return MaterialApp(
    theme: AppTheme.dark,
    home: NutritionAiScreen(state: state),
  );
}

void main() {
  testWidgets('günlük makro özet barları hesaplanır', (tester) async {
    final AppState state = AppState(
      ogunler: <Ogun>[
        const Ogun(
          isim: 'Test Öğün',
          kalori: 500,
          protein: 30,
          karbonhidrat: 40,
          yag: 10,
        ),
      ],
      hedefKalori: 2600,
      hedefProtein: 160,
    );

    await tester.pumpWidget(_ekran(state));

    expect(find.text('Akıllı Yemek Takibi'), findsOneWidget);
    expect(find.text('500 / 2600 kcal'), findsOneWidget);
    expect(find.text('30 / 160 g'), findsOneWidget);
    expect(find.text('Karbonhidrat'), findsWidgets);
    expect(find.text('Yağ'), findsWidgets);
  });

  testWidgets('manuel form ve hızlı çipler öğün ekler', (tester) async {
    final AppState state = AppState(
      ogunler: <Ogun>[],
      hedefKalori: 2600,
      hedefProtein: 160,
    );

    await tester.pumpWidget(_ekran(state));

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    // Alan sırası: ad, gramaj, kalori, protein, karbonhidrat, yağ.
    final Finder alanlar = find.byType(TextFormField);
    await tester.enterText(alanlar.at(0), 'Ev Yapımı Salata');
    await tester.enterText(alanlar.at(1), '250');
    await tester.enterText(alanlar.at(2), '320');
    await tester.enterText(alanlar.at(3), '18');
    await tester.enterText(alanlar.at(4), '22');
    await tester.enterText(alanlar.at(5), '14');

    await tester.ensureVisible(find.text('Yemeği Ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yemeği Ekle'));
    await tester.pumpAndSettle();

    expect(state.ogunler.length, 1);
    expect(state.ogunler.first.isim, 'Ev Yapımı Salata');
    expect(state.ogunler.first.kalori, 320);
    expect(state.ogunler.first.protein, 18);
    expect(state.ogunler.first.karbonhidrat, 22);
    expect(state.ogunler.first.yag, 14);

    await tester.ensureVisible(find.text('Yulaf Kasesi'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Yulaf Kasesi'));
    await tester.pump();

    expect(state.ogunler.length, 2);
    expect(state.ogunler.last.isim, 'Yulaf Kasesi');
  });

  testWidgets('AI analizi simülasyonu sonucu listeye ekler', (tester) async {
    final AppState state = AppState(
      ogunler: <Ogun>[],
      hedefKalori: 2600,
      hedefProtein: 160,
    );

    await tester.pumpWidget(_ekran(state));

    // AI moduna geç; fotoğraf yükleme kartı bu modda görünür.
    await tester.tap(find.text('AI Fotoğraf'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Fotoğraf Çek / Yükle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fotoğraf Çek / Yükle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('AI Kalori Analizi'), findsOneWidget);

    // Analiz adımları periyodik zamanlayıcıyla ilerler.
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();

    expect(find.text('Analiz tamamlandı'), findsOneWidget);
    expect(find.text('Listeye Ekle'), findsOneWidget);

    await tester.ensureVisible(find.text('Listeye Ekle'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Listeye Ekle'));
    await tester.pumpAndSettle();

    expect(state.ogunler.length, 1);
    expect(state.ogunler.first.kaynak, 'AI Analiz');
    expect(state.ogunler.first.kalori, greaterThan(0));
  });
}
