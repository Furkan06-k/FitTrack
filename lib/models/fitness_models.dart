/// Fitness, makro ve suplement takip uygulamasının veri modelleri.
///
/// Uygulama harici paket kullanmaz; bu dosyada yalnızca saf Dart sınıfları
/// bulunur.
library;

/// Günlük olarak tüketilen bir öğünü temsil eder.
class Ogun {
  final String isim;
  final int kalori;
  final double protein;
  final double karbonhidrat;
  final double yag;

  /// Porsiyonun yaklaşık ağırlığı (g). 0 ise bilinmiyor kabul edilir.
  final double gramaj;

  /// Öğünün hangi yolla eklendiği: "Manuel", "Hızlı Liste" veya "AI Analiz".
  final String kaynak;

  const Ogun({
    required this.isim,
    required this.kalori,
    required this.protein,
    required this.karbonhidrat,
    required this.yag,
    this.gramaj = 0,
    this.kaynak = 'Manuel',
  });

  /// Öğünün makro dağılımından hesaplanan enerji (1g protein/karbo = 4 kcal,
  /// 1g yağ = 9 kcal). Etiket değerleri ile karşılaştırma için kullanılabilir.
  int get hesaplananKalori =>
      (protein * 4 + karbonhidrat * 4 + yag * 9).round();

  Ogun copyWith({
    String? isim,
    int? kalori,
    double? protein,
    double? karbonhidrat,
    double? yag,
    double? gramaj,
    String? kaynak,
  }) {
    return Ogun(
      isim: isim ?? this.isim,
      kalori: kalori ?? this.kalori,
      protein: protein ?? this.protein,
      karbonhidrat: karbonhidrat ?? this.karbonhidrat,
      yag: yag ?? this.yag,
      gramaj: gramaj ?? this.gramaj,
      kaynak: kaynak ?? this.kaynak,
    );
  }

  @override
  String toString() =>
      'Ogun(isim: $isim, kalori: $kalori, protein: $protein, '
      'karbonhidrat: $karbonhidrat, yag: $yag, gramaj: $gramaj, '
      'kaynak: $kaynak)';
}

/// Günlük suplement takibinde kullanılan kayıt.
class Suplement {
  final String isim;
  final String dozaj;
  final bool alindiMi;

  const Suplement({
    required this.isim,
    required this.dozaj,
    this.alindiMi = false,
  });

  Suplement copyWith({String? isim, String? dozaj, bool? alindiMi}) {
    return Suplement(
      isim: isim ?? this.isim,
      dozaj: dozaj ?? this.dozaj,
      alindiMi: alindiMi ?? this.alindiMi,
    );
  }

  @override
  String toString() =>
      'Suplement(isim: $isim, dozaj: $dozaj, '
      'alindiMi: $alindiMi)';
}

/// Ağırlık antrenmanı hareketi veya kardiyo kaydı.
///
/// Ağırlık hareketlerinde [set], [tekrar] ve [agirlik] dolu olur.
/// Kardiyo kayıtlarında ise [kardiyoSuresi] dakika cinsinden doldurulur ve
/// [kardiyoTuru] kaydın türünü belirtir.
class Antrenman {
  final String hareketAdi;
  final int set;
  final int tekrar;
  final double agirlik;
  final int kardiyoSuresi;
  final String? kardiyoTuru;
  final DateTime? tarih;

  const Antrenman({
    required this.hareketAdi,
    this.set = 0,
    this.tekrar = 0,
    this.agirlik = 0,
    this.kardiyoSuresi = 0,
    this.kardiyoTuru,
    this.tarih,
  });

  /// Sadece kardiyo süresi ve türü içeren bir kayıt oluşturur.
  factory Antrenman.kardiyo({
    required String tur,
    required int dakika,
    DateTime? tarih,
  }) {
    return Antrenman(
      hareketAdi: tur,
      kardiyoSuresi: dakika,
      kardiyoTuru: tur,
      tarih: tarih ?? DateTime.now(),
    );
  }

  bool get kardiyoMu => kardiyoSuresi > 0;

  /// Hareketin toplam kaldırılan hacmi: set × tekrar × ağırlık (kg).
  double get toplamHacim => set * tekrar * agirlik;

  Antrenman copyWith({
    String? hareketAdi,
    int? set,
    int? tekrar,
    double? agirlik,
    int? kardiyoSuresi,
    String? kardiyoTuru,
    DateTime? tarih,
  }) {
    return Antrenman(
      hareketAdi: hareketAdi ?? this.hareketAdi,
      set: set ?? this.set,
      tekrar: tekrar ?? this.tekrar,
      agirlik: agirlik ?? this.agirlik,
      kardiyoSuresi: kardiyoSuresi ?? this.kardiyoSuresi,
      kardiyoTuru: kardiyoTuru ?? this.kardiyoTuru,
      tarih: tarih ?? this.tarih,
    );
  }

  @override
  String toString() =>
      'Antrenman(hareketAdi: $hareketAdi, set: $set, '
      'tekrar: $tekrar, agirlik: $agirlik, kardiyoSuresi: $kardiyoSuresi)';
}

/// Aktivite takip ekranında desteklenen etkinlik türleri.
///
/// [met] değeri, kalori hesabında kullanılan metabolik eşdeğerdir
/// (MET) ve aynı zamanda türün kalori çarpanıdır. Değerler ortalama bir
/// yetişkin için tipik yoğunlukları yansıtır.
enum AktiviteTuru {
  kosu(etiket: 'Koşu', met: 9.8),
  bisiklet(etiket: 'Bisiklet', met: 7.5),
  yuzme(etiket: 'Yüzme', met: 8.0),
  agirlik(etiket: 'Ağırlık Antrenmanı', met: 6.0),
  egimliYuruyus(etiket: 'Eğimli Yürüyüş', met: 5.3);

  const AktiviteTuru({required this.etiket, required this.met});

  final String etiket;
  final double met;

  /// Türün kalori çarpanı (MET değerinin kısa adı).
  double get kaloriCarpani => met;

  /// MET formülü ile yakılan kaloriyi hesaplar:
  /// kcal = MET × 3.5 × kilo / 200 × dakika.
  double kalori({required Duration sure, required double kilo}) {
    final double dakika = sure.inMilliseconds / 60000.0;
    if (dakika <= 0 || kilo <= 0) {
      return 0;
    }
    return met * 3.5 * kilo / 200.0 * dakika;
  }

  /// Dakikada yakılan ortalama kalori (anlık tempo).
  double dakikaTempo({required double kilo}) {
    if (kilo <= 0) {
      return 0;
    }
    return met * 3.5 * kilo / 200.0;
  }
}

/// Canlı aktivite takibinde kaydedilen tek bir seans.
class AktiviteKaydi {
  const AktiviteKaydi({
    required this.tur,
    required this.sure,
    required this.kalori,
    required this.tarih,
  });

  final AktiviteTuru tur;
  final Duration sure;
  final double kalori;
  final DateTime tarih;

  /// Seansı, verilen vücut ağırlığına göre kalori hesabıyla birlikte üretir.
  factory AktiviteKaydi.olustur({
    required AktiviteTuru tur,
    required Duration sure,
    required double kilo,
    DateTime? tarih,
  }) {
    return AktiviteKaydi(
      tur: tur,
      sure: sure,
      kalori: tur.kalori(sure: sure, kilo: kilo),
      tarih: tarih ?? DateTime.now(),
    );
  }

  int get dakika => sure.inMinutes;

  /// "12:34" veya "1:02:03" biçiminde süre metni.
  String get sureMetni {
    final int toplamSaniye = sure.inSeconds;
    final int saat = toplamSaniye ~/ 3600;
    final int dakika = (toplamSaniye % 3600) ~/ 60;
    final int saniye = toplamSaniye % 60;
    String iki(int deger) => deger.toString().padLeft(2, '0');
    if (saat > 0) {
      return '$saat:${iki(dakika)}:${iki(saniye)}';
    }
    return '${iki(dakika)}:${iki(saniye)}';
  }

  @override
  String toString() =>
      'AktiviteKaydi(tur: ${tur.etiket}, sure: $sure, '
      'kalori: $kalori, tarih: $tarih)';
}

/// Dashboard ekranındaki tek dokunuşla eklenebilen hazır öğünler.
const List<Ogun> hazirOgunler = <Ogun>[
  Ogun(
    isim: 'Yulaf Kasesi',
    kalori: 350,
    protein: 14,
    karbonhidrat: 55,
    yag: 9,
  ),
  Ogun(isim: 'Tavuk Göğsü', kalori: 285, protein: 53, karbonhidrat: 0, yag: 6),
  Ogun(isim: 'Ton Balığı', kalori: 220, protein: 40, karbonhidrat: 0, yag: 5),
  Ogun(
    isim: 'Peynirli Omlet',
    kalori: 310,
    protein: 21,
    karbonhidrat: 3,
    yag: 24,
  ),
  Ogun(
    isim: 'Pirinç & Et',
    kalori: 520,
    protein: 38,
    karbonhidrat: 62,
    yag: 12,
  ),
  Ogun(isim: 'Muz', kalori: 105, protein: 1.3, karbonhidrat: 27, yag: 0.4),
  Ogun(
    isim: 'Protein Shake',
    kalori: 160,
    protein: 30,
    karbonhidrat: 4,
    yag: 2,
  ),
  Ogun(
    isim: 'Yoğurt & Granola',
    kalori: 290,
    protein: 16,
    karbonhidrat: 34,
    yag: 10,
  ),
];

/// Uygulama açılışında oluşturulan varsayılan suplement listesi.
const List<Suplement> varsayilanSuplementler = <Suplement>[
  Suplement(isim: 'Whey Protein', dozaj: '30 g · antrenman sonrası'),
  Suplement(isim: 'Pre-Workout', dozaj: '1 ölçek · antrenmandan 30 dk önce'),
  Suplement(isim: 'BCAA', dozaj: '5 g · antrenman sırasında'),
  Suplement(isim: 'Kreatin', dozaj: '5 g · günün herhangi bir saati'),
  Suplement(isim: 'Omega-3', dozaj: '2 kapsül · yemekle birlikte'),
];

/// Antrenman ekranındaki hızlı seçim çipleri.
const List<String> hazirHareketler = <String>[
  'Bench Press',
  'Squat',
  'Deadlift',
  'Lat Pulldown',
  'Shoulder Press',
  'Barbell Row',
  'Leg Press',
  'Biceps Curl',
];
