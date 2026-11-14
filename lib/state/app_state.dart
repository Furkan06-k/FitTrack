import 'package:flutter/foundation.dart';

import '../models/fitness_models.dart';

/// Uygulamanın tek merkezden yönetilen durumu.
///
/// Tüm ekranlar aynı [AppState] örneğini dinler; bir ekranda yapılan değişiklik
/// (örneğin bir aktivitenin kaydedilmesi) diğer ekranlara anında yansır.
class AppState extends ChangeNotifier {
  AppState({
    List<Ogun>? ogunler,
    List<Suplement>? suplementler,
    List<Antrenman>? antrenmanlar,
    List<AktiviteKaydi>? aktiviteler,
    this.hedefKalori = 2600,
    this.hedefProtein = 160,
    this.hedefKarbonhidrat = 325,
    this.hedefYag = 80,
    this.boy = 180,
    this.kilo = 80,
    this.hedefKilo = 75,
    this.suHedefMl = 3000,
  }) {
    _ogunler.addAll(ogunler ?? _varsayilanOgunler);
    _suplementler.addAll(suplementler ?? varsayilanSuplementler);
    _antrenmanlar.addAll(antrenmanlar ?? <Antrenman>[]);
    _aktiviteler.addAll(aktiviteler ?? <AktiviteKaydi>[]);
  }

  static List<Ogun> get _varsayilanOgunler => <Ogun>[
    hazirOgunler[0],
    hazirOgunler[1],
  ];

  // ---------------------------------------------------------------------------
  // Kullanıcı hedefleri
  // ---------------------------------------------------------------------------

  int hedefKalori;
  int hedefProtein;
  int hedefKarbonhidrat;
  int hedefYag;
  int boy;
  double kilo;
  double hedefKilo;
  int suHedefMl;

  // ---------------------------------------------------------------------------
  // Su takibi
  // ---------------------------------------------------------------------------

  int _suMl = 0;

  /// Bugün içilen toplam su (ml).
  int get suMl => _suMl;

  /// Su hedefinin tamamlanma oranı (0.0 - 1.0).
  double get suOrani {
    if (suHedefMl <= 0) {
      return 0;
    }
    return (_suMl / suHedefMl).clamp(0.0, 1.0).toDouble();
  }

  /// Hedefe kalan su miktarı (ml).
  int get kalanSuMl => (suHedefMl - _suMl).clamp(0, 99999).toInt();

  /// 250 ml'lik bardak cinsinden içilen su.
  double get suBardakSayisi => _suMl / 250;

  void suEkle(int ml) {
    if (ml <= 0) {
      return;
    }
    _suMl += ml;
    notifyListeners();
  }

  void suAzalt(int ml) {
    if (ml <= 0) {
      return;
    }
    _suMl = (_suMl - ml).clamp(0, 99999).toInt();
    notifyListeners();
  }

  void suSifirla() {
    if (_suMl == 0) {
      return;
    }
    _suMl = 0;
    notifyListeners();
  }

  void suHedefGuncelle(int ml) {
    final int yeniHedef = ml.clamp(500, 8000).toInt();
    if (yeniHedef == suHedefMl) {
      return;
    }
    suHedefMl = yeniHedef;
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Öğünler / beslenme
  // ---------------------------------------------------------------------------

  final List<Ogun> _ogunler = <Ogun>[];

  List<Ogun> get ogunler => List<Ogun>.unmodifiable(_ogunler);

  int get ogunSayisi => _ogunler.length;

  int get alinanKalori =>
      _ogunler.fold<int>(0, (int toplam, Ogun ogun) => toplam + ogun.kalori);

  double get alinanProtein => _ogunler.fold<double>(
    0,
    (double toplam, Ogun ogun) => toplam + ogun.protein,
  );

  double get alinanKarbonhidrat => _ogunler.fold<double>(
    0,
    (double toplam, Ogun ogun) => toplam + ogun.karbonhidrat,
  );

  double get alinanYag =>
      _ogunler.fold<double>(0, (double toplam, Ogun ogun) => toplam + ogun.yag);

  void ogunEkle(Ogun ogun) {
    _ogunler.add(ogun);
    notifyListeners();
  }

  void ogunSil(Ogun ogun) {
    final bool silindi = _ogunler.remove(ogun);
    if (silindi) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Suplementler
  // ---------------------------------------------------------------------------

  final List<Suplement> _suplementler = <Suplement>[];

  List<Suplement> get suplementler =>
      List<Suplement>.unmodifiable(_suplementler);

  int get alinanSuplementSayisi =>
      _suplementler.where((Suplement s) => s.alindiMi).length;

  void suplementToggle(int index) {
    if (index < 0 || index >= _suplementler.length) {
      return;
    }
    final Suplement mevcut = _suplementler[index];
    _suplementler[index] = mevcut.copyWith(alindiMi: !mevcut.alindiMi);
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Antrenmanlar
  // ---------------------------------------------------------------------------

  final List<Antrenman> _antrenmanlar = <Antrenman>[];

  List<Antrenman> get antrenmanlar =>
      List<Antrenman>.unmodifiable(_antrenmanlar);

  void antrenmanEkle(Antrenman antrenman) {
    _antrenmanlar.add(antrenman);
    notifyListeners();
  }

  void antrenmanSil(Antrenman antrenman) {
    final bool silindi = _antrenmanlar.remove(antrenman);
    if (silindi) {
      notifyListeners();
    }
  }

  void kardiyoKaydet(String tur, int dakika) {
    if (dakika <= 0) {
      return;
    }
    _antrenmanlar.add(Antrenman.kardiyo(tur: tur, dakika: dakika));
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // Aktiviteler
  // ---------------------------------------------------------------------------

  final List<AktiviteKaydi> _aktiviteler = <AktiviteKaydi>[];

  List<AktiviteKaydi> get aktiviteler =>
      List<AktiviteKaydi>.unmodifiable(_aktiviteler);

  /// Bugün kaydedilen aktiviteler.
  List<AktiviteKaydi> get bugununAktiviteleri {
    final DateTime simdi = DateTime.now();
    return _aktiviteler.where((AktiviteKaydi kayit) {
      return kayit.tarih.year == simdi.year &&
          kayit.tarih.month == simdi.month &&
          kayit.tarih.day == simdi.day;
    }).toList();
  }

  /// Bugün aktivitelerle yakılan toplam kalori.
  double get bugunYakilanKalori => bugununAktiviteleri.fold<double>(
    0,
    (double toplam, AktiviteKaydi kayit) => toplam + kayit.kalori,
  );

  /// Tüm zamanların yakılan toplam kalorisi.
  double get toplamYakilanKalori => _aktiviteler.fold<double>(
    0,
    (double toplam, AktiviteKaydi kayit) => toplam + kayit.kalori,
  );

  /// Bugünün enerji dengesi: alınan − yakılan.
  int get bugunNetKalori => (alinanKalori - bugunYakilanKalori).round();

  void aktiviteEkle(AktiviteKaydi kayit) {
    _aktiviteler.add(kayit);
    notifyListeners();
  }

  void aktiviteSil(AktiviteKaydi kayit) {
    final bool silindi = _aktiviteler.remove(kayit);
    if (silindi) {
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // Hedef güncelleme
  // ---------------------------------------------------------------------------

  void hedefKaydet({
    required int boy,
    required double kilo,
    required double hedefKilo,
    required int kalori,
    required int protein,
    int? karbonhidrat,
    int? yag,
  }) {
    this.boy = boy;
    this.kilo = kilo;
    this.hedefKilo = hedefKilo;
    hedefKalori = kalori;
    hedefProtein = protein;
    hedefKarbonhidrat =
        karbonhidrat ?? (kalori * 0.50 / 4).round().clamp(0, 9999).toInt();
    hedefYag = yag ?? (kalori * 0.30 / 9).round().clamp(0, 9999).toInt();
    // Kilo başına yaklaşık 35 ml su önerisiyle hedefi güncelle.
    suHedefMl = (kilo * 35).round().clamp(2000, 5000).toInt();
    notifyListeners();
  }
}
