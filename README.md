# FitTrack

**Flutter ile geliştirilmiş fitness, beslenme ve suplement takip uygulaması.**

FitTrack; günlük kalori ve makro takibini, su tüketimini, antrenman kayıtlarını ve suplement
listesini tek bir arayüzde toplar. Kalori hedefleri MET ve Mifflin-St Jeor formülleriyle
vücut ağırlığına göre hesaplanır.

## Özellikler

| Sekme | Ne yapar |
|---|---|
| **Özet** | Günlük kalori, makro, su ve antrenman durumunu tek ekranda gösterir |
| **Beslenme** | Manuel giriş, hızlı öğün listesi ve fotoğraf tabanlı analiz akışı (arayüz simülasyonu) |
| **Su** | Günlük hedef, tek dokunuşla ekleme ve geçmiş |
| **Aktivite** | Koşu, bisiklet, yüzme, ağırlık ve eğimli yürüyüş için canlı takip; MET ile kalori hesabı |
| **Suplement** | Günlük liste ve tamamlama işaretleme |
| **Vücut** | Etkileşimli kas haritası ve kilo takibi |

- **Kalori hesabı:** Mifflin-St Jeor ile bazal metabolizma + aktivite katsayısı
- **Kas haritası:** `CustomPainter` ile harici görsel kullanmadan çizilir
- **Durum yönetimi:** Tek `AppState` (`ChangeNotifier`) — tüm sekmeler aynı veriyi anında gösterir
- **Harici paket yok:** Yalnızca Flutter SDK ve `cupertino_icons`

## Mimari

```
lib/
├── main.dart                 # uygulama girişi, tema ve alt sekme yapısı
├── models/
│   └── fitness_models.dart   # öğün, antrenman, suplement, ölçüm modelleri
├── state/
│   └── app_state.dart        # merkezî durum (ChangeNotifier)
├── screens/                  # 6 sekme + hesaplama ekranı
└── theme/
    └── app_theme.dart        # renk ve tipografi
```

Veri akışı: **model → state → view**. Ekranlar veriyi değiştirmez; `AppState` üzerinden
değiştirir ve `notifyListeners()` ile tüm dinleyiciler güncellenir.

## Kurulum

```bash
flutter pub get
flutter run
```

Belirli bir platformda çalıştırmak için:

```bash
flutter run -d chrome     # web
flutter run -d windows    # masaüstü
flutter run -d <cihaz>    # bağlı Android/iOS cihaz
```

## Testler

```bash
flutter analyze
flutter test
```

Testler iş mantığını doğrular: kalori/makro hesapları, su ve öğün ekleme-silme,
aktivite kaydı ve günlük sıfırlama davranışı.

## Proje Raporu

Seminer projesi kapsamında hazırlanan detaylı rapor:
[`rapor/FitTrack_Proje_Raporu.pdf`](rapor/FitTrack_Proje_Raporu.pdf)

## Bilinen Sınırlar

- Veriler şu an bellekte tutulur; uygulama kapatıldığında sıfırlanır (kalıcılık yol haritasında).
- Fotoğraf tabanlı besin analizi gerçek bir modele bağlı değildir; arayüz simülasyonudur.

## Lisans

Eğitim amaçlı geliştirilmiştir.
