import 'dart:async';

import 'package:flutter/material.dart';

import '../models/fitness_models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Geçmiş görünümünün dönem filtresi.
enum _Donem {
  gunluk('Günlük'),
  haftalik('Haftalık'),
  aylik('Aylık');

  const _Donem(this.etiket);

  final String etiket;
}

/// Koşu, bisiklet, yüzme, ağırlık antrenmanı ve eğimli yürüyüş için canlı
/// kronometre, anlık kalori/tempo takibi ve dönemsel geçmiş özeti sunar.
///
/// Tüm kayıtlar merkezi [AppState] üzerinde tutulur; bir seans kaydedildiğinde
/// dashboard'daki toplam yakılan kalori de anında güncellenir.
class ActivityTrackerScreen extends StatefulWidget {
  const ActivityTrackerScreen({super.key, required this.state});

  final AppState state;

  @override
  State<ActivityTrackerScreen> createState() => _ActivityTrackerScreenState();
}

class _ActivityTrackerScreenState extends State<ActivityTrackerScreen> {
  final Stopwatch _kronometre = Stopwatch();
  Timer? _tiklayici;

  AktiviteTuru _tur = AktiviteTuru.kosu;
  bool _calisiyor = false;
  _Donem _donem = _Donem.gunluk;

  AppState get _state => widget.state;

  Duration get _sure => _kronometre.elapsed;

  bool get _kaydedilebilir => _sure.inSeconds > 0;

  double get _anlikKalori => _tur.kalori(sure: _sure, kilo: _state.kilo);

  double get _anlikTempo => _tur.dakikaTempo(kilo: _state.kilo);

  double get _saatlikTempo => _anlikTempo * 60;

  @override
  void dispose() {
    _tiklayici?.cancel();
    _kronometre.stop();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Dönem hesaplamaları
  // ---------------------------------------------------------------------------

  DateTime get _bugun {
    final DateTime simdi = DateTime.now();
    return DateTime(simdi.year, simdi.month, simdi.day);
  }

  DateTime get _donemBaslangici => switch (_donem) {
    _Donem.gunluk => _bugun,
    _Donem.haftalik => _bugun.subtract(Duration(days: _bugun.weekday - 1)),
    _Donem.aylik => DateTime(_bugun.year, _bugun.month, 1),
  };

  List<AktiviteKaydi> get _donemKayitlari {
    final DateTime baslangic = _donemBaslangici;
    return _state.aktiviteler
        .where((AktiviteKaydi kayit) => !kayit.tarih.isBefore(baslangic))
        .toList();
  }

  Duration get _donemSuresi =>
      _donemKayitlari.fold(Duration.zero, (Duration toplam, AktiviteKaydi k) {
        return toplam + k.sure;
      });

  double get _donemKalorisi => _donemKayitlari.fold<double>(
    0,
    (double toplam, AktiviteKaydi k) => toplam + k.kalori,
  );

  /// Dönemdeki kayıtları etkinlik türüne göre gruplar.
  List<_TurOzeti> get _turOzetleri {
    final Map<AktiviteTuru, List<AktiviteKaydi>> gruplar =
        <AktiviteTuru, List<AktiviteKaydi>>{};
    for (final AktiviteKaydi kayit in _donemKayitlari) {
      gruplar.putIfAbsent(kayit.tur, () => <AktiviteKaydi>[]).add(kayit);
    }
    final List<_TurOzeti> ozetler = <_TurOzeti>[
      for (final MapEntry<AktiviteTuru, List<AktiviteKaydi>> entry
          in gruplar.entries)
        _TurOzeti(tur: entry.key, kayitlar: entry.value),
    ];
    ozetler.sort((_TurOzeti a, _TurOzeti b) => b.kalori.compareTo(a.kalori));
    return ozetler;
  }

  /// Dönemdeki kayıtları güne göre gruplar (en yeni gün önce).
  List<_GunGrubu> get _gunGruplari {
    final Map<DateTime, List<AktiviteKaydi>> gruplar =
        <DateTime, List<AktiviteKaydi>>{};
    for (final AktiviteKaydi kayit in _donemKayitlari) {
      final DateTime gun = DateTime(
        kayit.tarih.year,
        kayit.tarih.month,
        kayit.tarih.day,
      );
      gruplar.putIfAbsent(gun, () => <AktiviteKaydi>[]).add(kayit);
    }
    final List<DateTime> gunler = gruplar.keys.toList()
      ..sort((DateTime a, DateTime b) => b.compareTo(a));
    return <_GunGrubu>[
      for (final DateTime gun in gunler)
        _GunGrubu(gun: gun, kayitlar: _sirali(gruplar[gun]!)),
    ];
  }

  List<AktiviteKaydi> _sirali(List<AktiviteKaydi> liste) {
    final List<AktiviteKaydi> kopya = List<AktiviteKaydi>.of(liste);
    kopya.sort(
      (AktiviteKaydi a, AktiviteKaydi b) => b.tarih.compareTo(a.tarih),
    );
    return kopya;
  }

  String get _donemEtiketi => switch (_donem) {
    _Donem.gunluk => 'Bugün',
    _Donem.haftalik => 'Bu hafta',
    _Donem.aylik => '${_ayAdi(_bugun.month)} ${_bugun.year}',
  };

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildTurSecimi(context),
            const SizedBox(height: 16),
            _buildKronometreKarti(context),
            const SizedBox(height: 22),
            _buildGecmisBasligi(context),
            const SizedBox(height: 12),
            _buildDonemOzeti(context),
            const SizedBox(height: 12),
            _buildTurOzetleri(context),
            const SizedBox(height: 16),
            _buildGecmisListesi(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'AKTİVİTE',
          style: text.labelLarge?.copyWith(
            color: AppColors.purple,
            letterSpacing: 2.4,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text('Canlı Aktivite Takibi', style: text.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Etkinliğini seç, kronometreyi başlat ve yakılan kaloriyi anlık izle.',
          style: text.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildTurSecimi(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.sports_rounded, color: AppColors.purple, size: 18),
            const SizedBox(width: 8),
            Text(
              'Etkinlik Seçimi',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              '${_kiloMetni(_state.kilo)} kg',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            const double bosluk = 8;
            final double genislik = (constraints.maxWidth - bosluk * 2) / 3;
            return Wrap(
              spacing: bosluk,
              runSpacing: bosluk,
              children: [
                for (final AktiviteTuru tur in AktiviteTuru.values)
                  SizedBox(
                    width: genislik,
                    child: _TurKarti(
                      tur: tur,
                      secili: _tur == tur,
                      onTap: () => _turSec(tur),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildKronometreKarti(BuildContext context) {
    final Color renk = _tur.renk;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [renk.withValues(alpha: 0.18), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: renk.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_tur.ikon, color: renk, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _tur.etiket,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _durumMetni,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              _DurumRozeti(calisiyor: _calisiyor),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                _kronometreMetni(_sure),
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 54,
                  height: 1,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                  fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _CanliMetrik(
                  icon: Icons.local_fire_department_rounded,
                  renk: renk,
                  deger: _sayiMetni(_anlikKalori),
                  birim: 'kcal',
                  etiket: 'Yakılan',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CanliMetrik(
                  icon: Icons.timer_outlined,
                  renk: AppColors.blue,
                  deger: _sure.inMinutes.toString(),
                  birim: 'dk',
                  etiket: 'Geçen süre',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CanliMetrik(
                  icon: Icons.speed_rounded,
                  renk: AppColors.amber,
                  deger: _anlikTempo.toStringAsFixed(1),
                  birim: 'kcal/dk',
                  etiket: 'Anlık tempo',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Saatlik tahmini yakım: ${_sayiMetni(_saatlikTempo)} kcal · '
            'Kalori çarpanı ×${_tur.kaloriCarpani.toStringAsFixed(1)}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 10),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: _baslatDurdur,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: const Color(0xFF00210E),
                    disabledBackgroundColor: AppColors.surfaceHigh,
                    disabledForegroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: Icon(
                    _calisiyor ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 20,
                  ),
                  label: Text(
                    _calisiyor
                        ? 'Duraklat'
                        : _kaydedilebilir
                        ? 'Devam Et'
                        : 'Etkinliği Başlat',
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: _bitirVeKaydet,
                  style: FilledButton.styleFrom(
                    backgroundColor: renk,
                    foregroundColor: _tur.butonMetinRengi,
                    disabledBackgroundColor: AppColors.surfaceHigh,
                    disabledForegroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: const Text('Bitir ve Kaydet'),
                ),
              ),
            ],
          ),
          if (_calisiyor || _kaydedilebilir) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: _iptalEt,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.danger,
                    ),
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: const Text('İptal Et'),
                  ),
                ),
                Expanded(
                  child: TextButton.icon(
                    onPressed: _calisiyor ? null : _sifirla,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                    icon: const Icon(Icons.restart_alt_rounded, size: 18),
                    label: const Text('Sıfırla'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildGecmisBasligi(BuildContext context) {
    final int adet = _donemKayitlari.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.history_rounded,
                color: AppColors.purple,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aktivite Geçmişi',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '$adet kayıt · $_donemEtiketi',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              for (final _Donem donem in _Donem.values) ...[
                Expanded(
                  child: _SegmentButon(
                    etiket: donem.etiket,
                    secili: _donem == donem,
                    onTap: () => _donemDegistir(donem),
                  ),
                ),
                if (donem != _Donem.values.last) const SizedBox(width: 4),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDonemOzeti(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _OzetKarti(
            baslik: 'Toplam Süre',
            deger: _sureMetni(_donemSuresi),
            birim: '',
            icon: Icons.timer_outlined,
            renk: AppColors.blue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OzetKarti(
            baslik: 'Yakılan Kalori',
            deger: _sayiMetni(_donemKalorisi),
            birim: 'kcal',
            icon: Icons.local_fire_department_rounded,
            renk: AppColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _OzetKarti(
            baslik: 'Seans',
            deger: '${_donemKayitlari.length}',
            birim: 'adet',
            icon: Icons.event_available_rounded,
            renk: AppColors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildTurOzetleri(BuildContext context) {
    final List<_TurOzeti> ozetler = _turOzetleri;
    if (ozetler.isEmpty) {
      return const _BosDurum(
        icon: Icons.insights_rounded,
        baslik: 'Bu dönem için etkinlik özeti yok',
        aciklama:
            'Bir etkinlik kaydettiğinde tür bazlı dakika ve kalori '
            'özeti burada oluşur.',
      );
    }

    final int toplamSaniye = _donemSuresi.inSeconds;
    return Column(
      children: [
        for (final _TurOzeti ozet in ozetler) ...[
          _TurOzetKarti(ozet: ozet, toplamSaniye: toplamSaniye),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildGecmisListesi(BuildContext context) {
    final List<_GunGrubu> gruplar = _gunGruplari;
    if (gruplar.isEmpty) {
      return _BosDurum(
        icon: Icons.directions_run_rounded,
        baslik: '$_donemEtiketi için kayıt yok',
        aciklama:
            'Kronometreyi başlatıp seansını kaydettiğinde burada '
            'detaylı olarak görünecek.',
      );
    }

    return Column(
      children: [
        for (final _GunGrubu grup in gruplar) ...[
          _GunBasligi(grup: grup),
          const SizedBox(height: 8),
          for (final AktiviteKaydi kayit in grup.kayitlar) ...[
            _KayitSatiri(kayit: kayit, onSil: () => _sil(kayit)),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 6),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Etkileşimler
  // ---------------------------------------------------------------------------

  void _turSec(AktiviteTuru tur) {
    if (tur == _tur) {
      return;
    }
    if (_calisiyor || _kaydedilebilir) {
      _mesaj('Etkinliği değiştirmek için önce kaydı bitir ya da iptal et.');
      return;
    }
    setState(() {
      _tur = tur;
    });
  }

  void _donemDegistir(_Donem donem) {
    if (_donem == donem) {
      return;
    }
    setState(() {
      _donem = donem;
    });
  }

  void _baslatDurdur() {
    if (_calisiyor) {
      _durdur();
      return;
    }
    _baslat();
  }

  void _baslat() {
    if (!_kronometre.isRunning) {
      _kronometre.start();
    }
    _tiklayici?.cancel();
    _tiklayici = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    });
    setState(() {
      _calisiyor = true;
    });
  }

  void _durdur() {
    _kronometre.stop();
    _tiklayici?.cancel();
    _tiklayici = null;
    setState(() {
      _calisiyor = false;
    });
  }

  void _sifirla() {
    if (_calisiyor) {
      return;
    }
    setState(() {
      _kronometre.reset();
    });
  }

  void _bitirVeKaydet() {
    if (!_kaydedilebilir) {
      _mesaj('Kaydetmek için önce etkinliği başlat.');
      return;
    }
    if (_calisiyor) {
      _durdur();
    }

    final AktiviteKaydi kayit = AktiviteKaydi.olustur(
      tur: _tur,
      sure: _sure,
      kilo: _state.kilo,
    );

    _state.aktiviteEkle(kayit);

    setState(() {
      _kronometre.reset();
      _donem = _Donem.gunluk;
    });

    _mesaj(
      '${kayit.tur.etiket} · ${kayit.sureMetni} · '
      '${_sayiMetni(kayit.kalori)} kcal kaydedildi. '
      'Dashboard toplamı güncellendi.',
    );
  }

  Future<void> _iptalEt() async {
    if (!_calisiyor && !_kaydedilebilir) {
      return;
    }
    if (_calisiyor) {
      _durdur();
    }
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Seans iptal edilsin mi?'),
          content: Text(
            '${_tur.etiket} · ${_kronometreMetni(_sure)} kaydı silinecek ve '
            'hiçbir yere eklenmeyecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
              child: const Text('İptal Et'),
            ),
          ],
        );
      },
    );
    if (onay != true || !mounted) {
      return;
    }
    setState(() {
      _kronometre.reset();
    });
    _mesaj('Seans iptal edildi, kayıt oluşturulmadı.');
  }

  void _sil(AktiviteKaydi kayit) {
    _state.aktiviteSil(kayit);
    _mesaj('${kayit.tur.etiket} kaydı silindi.');
  }

  void _mesaj(String metin) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(metin)));
  }

  // ---------------------------------------------------------------------------
  // Metin yardımcıları
  // ---------------------------------------------------------------------------

  String get _durumMetni {
    if (_calisiyor) {
      return 'Canlı · kronometre çalışıyor';
    }
    if (_kaydedilebilir) {
      return 'Duraklatıldı · kaydetmeye hazır';
    }
    return 'Hazır · ${_tur.etiket} için başlat';
  }

  String _kronometreMetni(Duration sure) {
    final int toplamSaniye = sure.inSeconds;
    final int saat = toplamSaniye ~/ 3600;
    final int dakika = (toplamSaniye % 3600) ~/ 60;
    final int saniye = toplamSaniye % 60;
    String iki(int deger) => deger.toString().padLeft(2, '0');
    return '${iki(saat)}:${iki(dakika)}:${iki(saniye)}';
  }

  String _sureMetni(Duration sure) {
    final int dakika = sure.inMinutes;
    if (dakika < 60) {
      return '$dakika';
    }
    final int saat = dakika ~/ 60;
    final int kalan = dakika % 60;
    return '$saat sa $kalan';
  }

  String _sayiMetni(double deger) => deger.toStringAsFixed(0);

  String _kiloMetni(double deger) {
    if (deger == deger.roundToDouble()) {
      return deger.toStringAsFixed(0);
    }
    return deger.toStringAsFixed(1);
  }

  String _ayAdi(int ay) {
    const List<String> aylar = <String>[
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return aylar[ay - 1];
  }
}

// -----------------------------------------------------------------------------
// Etkinlik türü görünümü
// -----------------------------------------------------------------------------

extension _AktiviteGorunum on AktiviteTuru {
  Color get renk => switch (this) {
    AktiviteTuru.kosu => AppColors.green,
    AktiviteTuru.bisiklet => AppColors.amber,
    AktiviteTuru.yuzme => AppColors.blue,
    AktiviteTuru.agirlik => AppColors.purple,
    AktiviteTuru.egimliYuruyus => const Color(0xFFFF8A65),
  };

  Color get butonMetinRengi => switch (this) {
    AktiviteTuru.kosu => const Color(0xFF00210E),
    AktiviteTuru.bisiklet => const Color(0xFF2A1F00),
    AktiviteTuru.yuzme => Colors.white,
    AktiviteTuru.agirlik => const Color(0xFF1A1030),
    AktiviteTuru.egimliYuruyus => const Color(0xFF2A1000),
  };

  IconData get ikon => switch (this) {
    AktiviteTuru.kosu => Icons.directions_run_rounded,
    AktiviteTuru.bisiklet => Icons.directions_bike_rounded,
    AktiviteTuru.yuzme => Icons.pool_rounded,
    AktiviteTuru.agirlik => Icons.fitness_center_rounded,
    AktiviteTuru.egimliYuruyus => Icons.terrain_rounded,
  };
}

// -----------------------------------------------------------------------------
// Yardımcı veri sınıfları
// -----------------------------------------------------------------------------

class _TurOzeti {
  const _TurOzeti({required this.tur, required this.kayitlar});

  final AktiviteTuru tur;
  final List<AktiviteKaydi> kayitlar;

  Duration get sure => kayitlar.fold(
    Duration.zero,
    (Duration toplam, AktiviteKaydi k) => toplam + k.sure,
  );

  double get kalori =>
      kayitlar.fold(0, (double toplam, AktiviteKaydi k) => toplam + k.kalori);
}

class _GunGrubu {
  const _GunGrubu({required this.gun, required this.kayitlar});

  final DateTime gun;
  final List<AktiviteKaydi> kayitlar;

  Duration get toplamSure =>
      kayitlar.fold(Duration.zero, (Duration toplam, AktiviteKaydi kayit) {
        return toplam + kayit.sure;
      });

  double get toplamKalori => kayitlar.fold(
    0,
    (double toplam, AktiviteKaydi kayit) => toplam + kayit.kalori,
  );
}

// -----------------------------------------------------------------------------
// Widget'lar
// -----------------------------------------------------------------------------

class _TurKarti extends StatelessWidget {
  const _TurKarti({
    required this.tur,
    required this.secili,
    required this.onTap,
  });

  final AktiviteTuru tur;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color renk = tur.renk;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: secili ? renk.withValues(alpha: 0.16) : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: secili ? renk.withValues(alpha: 0.75) : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                tur.ikon,
                size: 22,
                color: secili ? renk : AppColors.textSecondary,
              ),
              const SizedBox(height: 7),
              SizedBox(
                height: 28,
                child: Center(
                  child: Text(
                    tur.etiket,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: secili ? renk : AppColors.textSecondary,
                      fontSize: 10,
                      height: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '×${tur.kaloriCarpani.toStringAsFixed(1)}',
                style: TextStyle(
                  color: (secili ? renk : AppColors.textSecondary).withValues(
                    alpha: 0.75,
                  ),
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CanliMetrik extends StatelessWidget {
  const _CanliMetrik({
    required this.icon,
    required this.renk,
    required this.deger,
    required this.birim,
    required this.etiket,
  });

  final IconData icon;
  final Color renk;
  final String deger;
  final String birim;
  final String etiket;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: renk, size: 16),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: deger,
                    style: TextStyle(
                      color: renk,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                  TextSpan(
                    text: ' $birim',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiket,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _DurumRozeti extends StatelessWidget {
  const _DurumRozeti({required this.calisiyor});

  final bool calisiyor;

  @override
  Widget build(BuildContext context) {
    final Color aktifRenk = calisiyor
        ? AppColors.green
        : AppColors.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: aktifRenk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: aktifRenk,
              shape: BoxShape.circle,
              boxShadow: calisiyor
                  ? <BoxShadow>[
                      BoxShadow(
                        color: aktifRenk.withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            calisiyor ? 'CANLI' : 'DURDU',
            style: TextStyle(
              color: aktifRenk,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _OzetKarti extends StatelessWidget {
  const _OzetKarti({
    required this.baslik,
    required this.deger,
    required this.birim,
    required this.icon,
    required this.renk,
  });

  final String baslik;
  final String deger;
  final String birim;
  final IconData icon;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: renk, size: 18),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: deger,
                    style: TextStyle(
                      color: renk,
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (birim.isNotEmpty)
                    TextSpan(
                      text: ' $birim',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            baslik,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _TurOzetKarti extends StatelessWidget {
  const _TurOzetKarti({required this.ozet, required this.toplamSaniye});

  final _TurOzeti ozet;
  final int toplamSaniye;

  @override
  Widget build(BuildContext context) {
    final Color renk = ozet.tur.renk;
    final double oran = toplamSaniye <= 0
        ? 0
        : (ozet.sure.inSeconds / toplamSaniye).clamp(0.0, 1.0);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(ozet.tur.ikon, color: renk, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        ozet.tur.etiket,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontSize: 13),
                      ),
                    ),
                    Text(
                      '${ozet.kayitlar.length} seans',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: oran,
                    minHeight: 5,
                    backgroundColor: AppColors.surfaceHigh,
                    color: renk,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${ozet.sure.inMinutes} dk  ·  '
                  '${ozet.kalori.toStringAsFixed(0)} kcal  ·  '
                  '%${(oran * 100).round()} pay',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButon extends StatelessWidget {
  const _SegmentButon({
    required this.etiket,
    required this.secili,
    required this.onTap,
  });

  final String etiket;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(11),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: secili ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: secili
                  ? AppColors.purple.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Text(
            etiket,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: secili ? AppColors.purple : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _GunBasligi extends StatelessWidget {
  const _GunBasligi({required this.grup});

  final _GunGrubu grup;

  static const List<String> _gunAdlari = <String>[
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];

  @override
  Widget build(BuildContext context) {
    final String baslik = _gunEtiketi(grup.gun);
    final String toplam =
        '${grup.toplamSure.inMinutes} dk · '
        '${grup.toplamKalori.toStringAsFixed(0)} kcal';
    return Row(
      children: [
        Text(
          baslik,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: AppColors.textPrimary, fontSize: 12),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            '${_gunAdlari[grup.gun.weekday - 1]} · $toplam',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }

  String _gunEtiketi(DateTime gun) {
    final DateTime simdi = DateTime.now();
    final DateTime bugun = DateTime(simdi.year, simdi.month, simdi.day);
    final int fark = bugun.difference(gun).inDays;
    if (fark == 0) {
      return 'Bugün';
    }
    if (fark == 1) {
      return 'Dün';
    }
    String iki(int deger) => deger.toString().padLeft(2, '0');
    return '${iki(gun.day)}.${iki(gun.month)}';
  }
}

class _KayitSatiri extends StatelessWidget {
  const _KayitSatiri({required this.kayit, required this.onSil});

  final AktiviteKaydi kayit;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    final Color renk = kayit.tur.renk;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(kayit.tur.ikon, color: renk, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  kayit.tur.etiket,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${kayit.sure.inMinutes} dk  ·  '
                  '${kayit.kalori.toStringAsFixed(0)} kcal'
                  '  ·  ${_saat(kayit.tarih)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: renk.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              kayit.sureMetni,
              style: TextStyle(
                color: renk,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          IconButton(
            onPressed: onSil,
            tooltip: 'Kaydı sil',
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  String _saat(DateTime tarih) {
    String iki(int deger) => deger.toString().padLeft(2, '0');
    return '${iki(tarih.hour)}:${iki(tarih.minute)}';
  }
}

class _BosDurum extends StatelessWidget {
  const _BosDurum({
    required this.icon,
    required this.baslik,
    required this.aciklama,
  });

  final IconData icon;
  final String baslik;
  final String aciklama;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 26),
          const SizedBox(height: 8),
          Text(baslik, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            aciklama,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
