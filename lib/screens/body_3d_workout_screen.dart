import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Vücut tipine göre öneriler, etkileşimli anatomik kas haritası ve seçilen
/// bölgeye ait egzersizleri gösteren 3D görünümlü antrenman ekranı.
///
/// Kas haritası harici görsel veya 3D model kullanmaz; insan silüeti ve kas
/// grupları [CustomPainter] ile çizilir. Bölgeye dokunulduğunda ilgili kas
/// grubu nabız gibi parlar ve egzersiz listesi güncellenir.
class Body3DWorkoutScreen extends StatefulWidget {
  const Body3DWorkoutScreen({super.key});

  @override
  State<Body3DWorkoutScreen> createState() => _Body3DWorkoutScreenState();
}

class _Body3DWorkoutScreenState extends State<Body3DWorkoutScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _nabiz;
  late final Animation<double> _parlama;

  _VucutTipi _vucutTipi = _VucutTipi.mezomorf;
  _KasBolgesi _seciliBolge = _KasBolgesi.gogus;

  @override
  void initState() {
    super.initState();
    _nabiz = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    // Tek seferlik nabız: parlaklık önce azalır, sonra yerine oturur.
    // Sonsuz tekrar yerine tek seferlik olması, testlerde pumpAndSettle'ın
    // sonsuza kadar beklemesini de engeller.
    _parlama = _nabiz.drive(
      TweenSequence<double>(<TweenSequenceItem<double>>[
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 1,
            end: 0.35,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 1,
        ),
        TweenSequenceItem<double>(
          tween: Tween<double>(
            begin: 0.35,
            end: 1,
          ).chain(CurveTween(curve: Curves.easeIn)),
          weight: 1,
        ),
      ]),
    );
    _nabiz.forward(from: 0);
  }

  @override
  void dispose() {
    _nabiz.dispose();
    super.dispose();
  }

  _Sema get _sema => switch (_vucutTipi) {
    _VucutTipi.ektomorf => const _Sema(
      set: 4,
      tekrar: '8-10',
      dinlenme: '90 sn',
    ),
    _VucutTipi.mezomorf => const _Sema(
      set: 4,
      tekrar: '8-12',
      dinlenme: '75 sn',
    ),
    _VucutTipi.endomorf => const _Sema(
      set: 3,
      tekrar: '12-15',
      dinlenme: '45-60 sn',
    ),
  };

  List<_Egzersiz> get _egzersizler =>
      _egzersizlerHaritasi[_seciliBolge] ?? const <_Egzersiz>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _buildHeader(context),
            const SizedBox(height: 24),
            _BolumBasligi(
              icon: Icons.psychology_alt_rounded,
              renk: AppColors.amber,
              baslik: 'Vücut Tipini Seç',
              altBaslik: 'Antrenman ve beslenme önerileri buna göre şekillenir',
            ),
            const SizedBox(height: 12),
            _buildVucutTipiKarti(context),
            const SizedBox(height: 26),
            _BolumBasligi(
              icon: Icons.accessibility_new_rounded,
              renk: AppColors.purple,
              baslik: 'Anatomik Kas Haritası',
              altBaslik: 'Bölgeye dokun, kas grubunun parlamasını izle',
            ),
            const SizedBox(height: 12),
            _buildHaritaKarti(context),
            const SizedBox(height: 26),
            _buildEgzersizBasligi(context),
            const SizedBox(height: 12),
            _buildEgzersizListesi(),
            const SizedBox(height: 16),
            _buildBilgiNotu(context),
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
          'VÜCUT 3D',
          style: text.labelLarge?.copyWith(
            color: AppColors.purple,
            letterSpacing: 2.4,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text('Kas Haritası & Antrenman', style: text.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Vücut tipini belirle, kas grubunu seç ve sana uygun hareketleri gör.',
          style: text.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildVucutTipiKarti(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              for (final _VucutTipi tip in _VucutTipi.values) ...[
                Expanded(
                  child: _VucutTipiKarti(
                    tip: tip,
                    secili: tip == _vucutTipi,
                    onTap: () => _vucutTipiSec(tip),
                  ),
                ),
                if (tip != _VucutTipi.values.last) const SizedBox(width: 8),
              ],
            ],
          ),
          const SizedBox(height: 16),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _VucutTipiBilgisi(
              key: ValueKey<_VucutTipi>(_vucutTipi),
              tip: _vucutTipi,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHaritaKarti(BuildContext context) {
    final Color renk = _seciliBolge.renk;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1C1F2A), AppColors.surface],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.threed_rotation_rounded,
                  color: AppColors.purple,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '3D Anatomik Görünüm',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: renk.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: renk.withValues(alpha: 0.45)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: renk,
                        shape: BoxShape.circle,
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: renk.withValues(alpha: 0.7),
                            blurRadius: 6,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _seciliBolge.etiket.toUpperCase(),
                      style: TextStyle(
                        color: renk,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Kas grubuna dokunarak egzersizleri filtreleyebilirsin.',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 11),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: 340,
            child: AnimatedBuilder(
              animation: _parlama,
              builder: (BuildContext context, Widget? child) {
                return LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                    final Size boyut = Size(
                      constraints.maxWidth,
                      constraints.maxHeight,
                    );
                    return GestureDetector(
                      key: const ValueKey<String>('kasHaritasi'),
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (TapDownDetails details) =>
                          _haritaDokunuldu(details.localPosition, boyut),
                      child: CustomPaint(
                        size: boyut,
                        painter: _KasHaritasiPainter(
                          secili: _seciliBolge,
                          pulse: _parlama.value,
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (final _KasBolgesi bolge in _KasBolgesi.values) ...[
                Expanded(
                  child: _BolgeButonu(
                    bolge: bolge,
                    secili: bolge == _seciliBolge,
                    onTap: () => _bolgeSec(bolge),
                  ),
                ),
                if (bolge != _KasBolgesi.values.last) const SizedBox(width: 6),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEgzersizBasligi(BuildContext context) {
    final Color renk = _seciliBolge.renk;
    final _Sema sema = _sema;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: renk.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.fitness_center_rounded, color: renk, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${_seciliBolge.etiket} Egzersizleri',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${_seciliBolge.latin} · ${_egzersizler.length} hareket',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: renk.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${sema.set} × ${sema.tekrar}',
            style: TextStyle(
              color: renk,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEgzersizListesi() {
    final _Sema sema = _sema;
    final List<_Egzersiz> liste = _egzersizler;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      child: Column(
        key: ValueKey<_KasBolgesi>(_seciliBolge),
        children: [
          for (final _Egzersiz egzersiz in liste) ...[
            _EgzersizSatiri(
              egzersiz: egzersiz,
              renk: _seciliBolge.renk,
              set: sema.set,
              tekrar: sema.tekrar,
              dinlenme: sema.dinlenme,
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildBilgiNotu(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.amber,
            size: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Set ve tekrar aralıkları seçtiğin vücut tipine göre otomatik '
              'güncellenir. Isınma setlerini toplam hacme dahil etmeyi unutma.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  void _vucutTipiSec(_VucutTipi tip) {
    if (tip == _vucutTipi) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _vucutTipi = tip;
    });
  }

  void _bolgeSec(_KasBolgesi bolge) {
    if (bolge == _seciliBolge) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _seciliBolge = bolge;
    });
    _nabiz.forward(from: 0);
  }

  void _haritaDokunuldu(Offset konum, Size boyut) {
    final _GovdeGeometrisi geometri = _GovdeGeometrisi(boyut);
    for (final MapEntry<_KasBolgesi, Path> entry in geometri.bolgeler.entries) {
      if (entry.value.contains(konum)) {
        _bolgeSec(entry.key);
        return;
      }
    }
  }
}

/// Vücut tipine göre önerilen set / tekrar / dinlenme şeması.
class _Sema {
  const _Sema({
    required this.set,
    required this.tekrar,
    required this.dinlenme,
  });

  final int set;
  final String tekrar;
  final String dinlenme;
}

enum _VucutTipi {
  ektomorf(
    etiket: 'Ektomorf',
    kisaAd: 'İnce & hızlı',
    icon: Icons.eco_rounded,
    renk: AppColors.amber,
    aciklama:
        'İnce kemik yapısı ve hızlı metabolizma. Kalori açığı hızlı oluşur; '
        'kas kütlesi kazanmak sabır ve düzenli beslenme ister.',
    antrenman: 'Bileşik hareketler · 4-5 set · 8-10 tekrar · 90 sn dinlenme',
    beslenme: 'Kalori fazlası · öğün başına 30-40 g protein · sık ara öğün',
  ),
  mezomorf(
    etiket: 'Mezomorf',
    kisaAd: 'Dengeli & atletik',
    icon: Icons.fitness_center_rounded,
    renk: AppColors.green,
    aciklama:
        'Geniş omuz, dar bel ve dengeli hormon profili. Hem kas kazanımı hem '
        'yağ kaybı görece kolaydır; düzenli progresyon en büyük avantajın.',
    antrenman: 'Bileşik + izolasyon · 4 set · 8-12 tekrar · 75 sn dinlenme',
    beslenme: 'Dengeli makrolar · 1.8-2.2 g/kg protein · kalori dengesi',
  ),
  endomorf(
    etiket: 'Endomorf',
    kisaAd: 'Geniş & güçlü',
    icon: Icons.shield_rounded,
    renk: AppColors.blue,
    aciklama:
        'Daha geniş kemik yapısı ve güçlü bir alt yapı. Yağlanmaya yatkın '
        'olduğundan antrenman yoğunluğu ve beslenme kontrolü kritik.',
    antrenman: 'Superset · 3 set · 12-15 tekrar · 45-60 sn dinlenme',
    beslenme: 'Kontrollü kalori · düşük GI karbonhidrat · yüksek protein',
  );

  const _VucutTipi({
    required this.etiket,
    required this.kisaAd,
    required this.icon,
    required this.renk,
    required this.aciklama,
    required this.antrenman,
    required this.beslenme,
  });

  final String etiket;
  final String kisaAd;
  final IconData icon;
  final Color renk;
  final String aciklama;
  final String antrenman;
  final String beslenme;
}

enum _KasBolgesi {
  gogus(
    etiket: 'Göğüs',
    latin: 'Pectoralis Major',
    renk: AppColors.green,
    aciklama:
        'İtiş gücünün merkezi; göğüs, ön omuz ve triceps birlikte çalışır.',
  ),
  karin(
    etiket: 'Karın',
    latin: 'Rectus Abdominis',
    renk: AppColors.amber,
    aciklama: 'Gövde stabilitesi, core kuvveti ve denge için temel bölge.',
  ),
  omuz(
    etiket: 'Omuz',
    latin: 'Deltoideus',
    renk: AppColors.blue,
    aciklama:
        'Üç başlı deltoid kası; itiş ve çekiş hareketlerinde kilit rol oynar.',
  ),
  bacak(
    etiket: 'Bacak',
    latin: 'Quadriceps & Hamstrings',
    renk: AppColors.purple,
    aciklama: 'Alt vücut kuvveti, patlayıcılık ve metabolizma için en büyük kas grubu.',
  );

  const _KasBolgesi({
    required this.etiket,
    required this.latin,
    required this.renk,
    required this.aciklama,
  });

  final String etiket;
  final String latin;
  final Color renk;
  final String aciklama;
}

class _Egzersiz {
  const _Egzersiz({
    required this.isim,
    required this.ekipman,
    required this.zorluk,
    required this.icon,
  });

  final String isim;
  final String ekipman;
  final String zorluk;
  final IconData icon;
}

const Map<_KasBolgesi, List<_Egzersiz>> _egzersizlerHaritasi =
    <_KasBolgesi, List<_Egzersiz>>{
      _KasBolgesi.gogus: <_Egzersiz>[
        _Egzersiz(
          isim: 'Bench Press',
          ekipman: 'Barbell',
          zorluk: 'Orta',
          icon: Icons.fitness_center_rounded,
        ),
        _Egzersiz(
          isim: 'Incline Dumbbell Press',
          ekipman: 'Dumbbell',
          zorluk: 'Orta',
          icon: Icons.trending_up_rounded,
        ),
        _Egzersiz(
          isim: 'Cable Crossover',
          ekipman: 'Kablo',
          zorluk: 'Başlangıç',
          icon: Icons.waves_rounded,
        ),
        _Egzersiz(
          isim: 'Şınav',
          ekipman: 'Vücut Ağırlığı',
          zorluk: 'Başlangıç',
          icon: Icons.accessibility_new_rounded,
        ),
        _Egzersiz(
          isim: 'Dips',
          ekipman: 'Paralel Bar',
          zorluk: 'İleri',
          icon: Icons.sports_gymnastics_rounded,
        ),
      ],
      _KasBolgesi.karin: <_Egzersiz>[
        _Egzersiz(
          isim: 'Hanging Leg Raise',
          ekipman: 'Barfiks Barı',
          zorluk: 'İleri',
          icon: Icons.sports_gymnastics_rounded,
        ),
        _Egzersiz(
          isim: 'Cable Crunch',
          ekipman: 'Kablo',
          zorluk: 'Orta',
          icon: Icons.waves_rounded,
        ),
        _Egzersiz(
          isim: 'Plank',
          ekipman: 'Vücut Ağırlığı',
          zorluk: 'Başlangıç',
          icon: Icons.straighten_rounded,
        ),
        _Egzersiz(
          isim: 'Russian Twist',
          ekipman: 'Disk',
          zorluk: 'Orta',
          icon: Icons.rotate_right_rounded,
        ),
        _Egzersiz(
          isim: 'Ab Wheel Rollout',
          ekipman: 'Tekerlek',
          zorluk: 'İleri',
          icon: Icons.circle_outlined,
        ),
      ],
      _KasBolgesi.omuz: <_Egzersiz>[
        _Egzersiz(
          isim: 'Overhead Press',
          ekipman: 'Barbell',
          zorluk: 'Orta',
          icon: Icons.fitness_center_rounded,
        ),
        _Egzersiz(
          isim: 'Lateral Raise',
          ekipman: 'Dumbbell',
          zorluk: 'Başlangıç',
          icon: Icons.unfold_more_rounded,
        ),
        _Egzersiz(
          isim: 'Face Pull',
          ekipman: 'Kablo',
          zorluk: 'Başlangıç',
          icon: Icons.waves_rounded,
        ),
        _Egzersiz(
          isim: 'Arnold Press',
          ekipman: 'Dumbbell',
          zorluk: 'Orta',
          icon: Icons.sync_rounded,
        ),
        _Egzersiz(
          isim: 'Front Raise',
          ekipman: 'Dumbbell',
          zorluk: 'Başlangıç',
          icon: Icons.arrow_upward_rounded,
        ),
      ],
      _KasBolgesi.bacak: <_Egzersiz>[
        _Egzersiz(
          isim: 'Back Squat',
          ekipman: 'Barbell',
          zorluk: 'İleri',
          icon: Icons.fitness_center_rounded,
        ),
        _Egzersiz(
          isim: 'Romanian Deadlift',
          ekipman: 'Barbell',
          zorluk: 'Orta',
          icon: Icons.vertical_align_bottom_rounded,
        ),
        _Egzersiz(
          isim: 'Leg Press',
          ekipman: 'Makine',
          zorluk: 'Başlangıç',
          icon: Icons.straighten_rounded,
        ),
        _Egzersiz(
          isim: 'Walking Lunge',
          ekipman: 'Dumbbell',
          zorluk: 'Orta',
          icon: Icons.directions_walk_rounded,
        ),
        _Egzersiz(
          isim: 'Standing Calf Raise',
          ekipman: 'Makine',
          zorluk: 'Başlangıç',
          icon: Icons.height_rounded,
        ),
      ],
    };

/// İnsan silüetinin ve kas bölgelerinin normalize edilmiş geometrisi.
///
/// Aynı geometri hem çizim hem de dokunma testi için kullanılır; böylece
/// görünen bölgeler ile tıklanabilir alanlar birebir örtüşür.
class _GovdeGeometrisi {
  _GovdeGeometrisi(this.size);

  final Size size;

  double get w => size.width;
  double get h => size.height;
  double get cx => w / 2;

  Offset get basMerkez => Offset(cx, h * 0.078);
  double get basYaricapi => w * 0.085;

  Path get boyun => Path()
    ..addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - w * 0.04, h * 0.125, cx + w * 0.04, h * 0.19),
        Radius.circular(w * 0.02),
      ),
    );

  Path get govde {
    final Path p = Path();
    p.moveTo(cx - w * 0.145, h * 0.185);
    p.quadraticBezierTo(cx - w * 0.205, h * 0.24, cx - w * 0.185, h * 0.34);
    p.quadraticBezierTo(cx - w * 0.155, h * 0.44, cx - w * 0.165, h * 0.52);
    p.lineTo(cx - w * 0.155, h * 0.56);
    p.lineTo(cx + w * 0.155, h * 0.56);
    p.lineTo(cx + w * 0.165, h * 0.52);
    p.quadraticBezierTo(cx + w * 0.155, h * 0.44, cx + w * 0.185, h * 0.34);
    p.quadraticBezierTo(cx + w * 0.205, h * 0.24, cx + w * 0.145, h * 0.185);
    p.close();
    return p;
  }

  Path get solKol => Path()
    ..moveTo(cx - w * 0.135, h * 0.21)
    ..quadraticBezierTo(cx - w * 0.235, h * 0.3, cx - w * 0.245, h * 0.4)
    ..quadraticBezierTo(cx - w * 0.26, h * 0.49, cx - w * 0.245, h * 0.555);

  Path get sagKol => Path()
    ..moveTo(cx + w * 0.135, h * 0.21)
    ..quadraticBezierTo(cx + w * 0.235, h * 0.3, cx + w * 0.245, h * 0.4)
    ..quadraticBezierTo(cx + w * 0.26, h * 0.49, cx + w * 0.245, h * 0.555);

  Path get solBacak => Path()
    ..moveTo(cx - w * 0.078, h * 0.535)
    ..quadraticBezierTo(cx - w * 0.1, h * 0.7, cx - w * 0.09, h * 0.79)
    ..quadraticBezierTo(cx - w * 0.085, h * 0.87, cx - w * 0.095, h * 0.935);

  Path get sagBacak => Path()
    ..moveTo(cx + w * 0.078, h * 0.535)
    ..quadraticBezierTo(cx + w * 0.1, h * 0.7, cx + w * 0.09, h * 0.79)
    ..quadraticBezierTo(cx + w * 0.085, h * 0.87, cx + w * 0.095, h * 0.935);

  Map<_KasBolgesi, Path> get bolgeler => <_KasBolgesi, Path>{
    _KasBolgesi.omuz: _omuzlar,
    _KasBolgesi.gogus: _gogus,
    _KasBolgesi.karin: _karin,
    _KasBolgesi.bacak: _bacaklar,
  };

  Path get _gogus {
    final Path p = Path();
    p.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - w * 0.125, h * 0.212, cx - w * 0.012, h * 0.292),
        Radius.circular(w * 0.028),
      ),
    );
    p.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + w * 0.012, h * 0.212, cx + w * 0.125, h * 0.292),
        Radius.circular(w * 0.028),
      ),
    );
    return p;
  }

  Path get _karin {
    final Path p = Path();
    for (int satir = 0; satir < 3; satir++) {
      for (int kolon = 0; kolon < 2; kolon++) {
        final double sol = cx - w * 0.058 + kolon * w * 0.064;
        final double ust = h * 0.317 + satir * h * 0.046;
        p.addRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(sol, ust, w * 0.052, h * 0.034),
            Radius.circular(w * 0.014),
          ),
        );
      }
    }
    return p;
  }

  Path get _omuzlar {
    final Path p = Path();
    p.addOval(
      Rect.fromCircle(
        center: Offset(cx - w * 0.172, h * 0.207),
        radius: w * 0.05,
      ),
    );
    p.addOval(
      Rect.fromCircle(
        center: Offset(cx + w * 0.172, h * 0.207),
        radius: w * 0.05,
      ),
    );
    return p;
  }

  Path get _bacaklar {
    final Path p = Path();
    p.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - w * 0.125, h * 0.555, cx - w * 0.025, h * 0.735),
        Radius.circular(w * 0.03),
      ),
    );
    p.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + w * 0.025, h * 0.555, cx + w * 0.125, h * 0.735),
        Radius.circular(w * 0.03),
      ),
    );
    p.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx - w * 0.112, h * 0.755, cx - w * 0.032, h * 0.875),
        Radius.circular(w * 0.026),
      ),
    );
    p.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(cx + w * 0.032, h * 0.755, cx + w * 0.112, h * 0.875),
        Radius.circular(w * 0.026),
      ),
    );
    return p;
  }
}

class _KasHaritasiPainter extends CustomPainter {
  _KasHaritasiPainter({required this.secili, required this.pulse});

  final _KasBolgesi secili;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final _GovdeGeometrisi geo = _GovdeGeometrisi(size);
    final double cx = geo.cx;
    final double w = geo.w;
    final double h = geo.h;

    // Zemin gölgesi.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.962),
        width: w * 0.34,
        height: h * 0.028,
      ),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12),
    );

    final Paint govdeDolgu = Paint()..color = const Color(0xFF26262C);
    final Paint govdeKenar = Paint()
      ..color = const Color(0xFF3C3C46)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    // Uzuvlar gövdenin arkasında kalacak şekilde önce çizilir.
    final Paint kolPaint = Paint()
      ..color = const Color(0xFF2A2A31)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.075
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(geo.solKol, kolPaint);
    canvas.drawPath(geo.sagKol, kolPaint);

    final Paint bacakPaint = Paint()
      ..color = const Color(0xFF2A2A31)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.105
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(geo.solBacak, bacakPaint);
    canvas.drawPath(geo.sagBacak, bacakPaint);

    canvas.drawPath(geo.govde, govdeDolgu);
    canvas.drawPath(geo.govde, govdeKenar);
    canvas.drawPath(geo.boyun, govdeDolgu);
    canvas.drawCircle(geo.basMerkez, geo.basYaricapi, govdeDolgu);
    canvas.drawCircle(geo.basMerkez, geo.basYaricapi, govdeKenar);

    // Kas grupları.
    for (final MapEntry<_KasBolgesi, Path> entry in geo.bolgeler.entries) {
      final bool seciliMi = entry.key == secili;
      final Color renk = entry.key.renk;

      if (seciliMi) {
        canvas.drawPath(
          entry.value,
          Paint()
            ..color = renk.withValues(alpha: 0.3 + 0.28 * pulse)
            ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10 + 10 * pulse),
        );
      }

      canvas.drawPath(
        entry.value,
        Paint()
          ..color = renk.withValues(alpha: seciliMi ? 0.5 + 0.18 * pulse : 0.2)
          ..style = PaintingStyle.fill,
      );

      canvas.drawPath(
        entry.value,
        Paint()
          ..color = renk.withValues(alpha: seciliMi ? 0.95 : 0.42)
          ..style = PaintingStyle.stroke
          ..strokeWidth = seciliMi ? 1.6 : 1.0,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _KasHaritasiPainter oldDelegate) {
    return oldDelegate.secili != secili || oldDelegate.pulse != pulse;
  }
}

class _VucutTipiKarti extends StatelessWidget {
  const _VucutTipiKarti({
    required this.tip,
    required this.secili,
    required this.onTap,
  });

  final _VucutTipi tip;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
          decoration: BoxDecoration(
            color: secili
                ? tip.renk.withValues(alpha: 0.14)
                : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: secili
                  ? tip.renk.withValues(alpha: 0.72)
                  : AppColors.border,
            ),
          ),
          child: Column(
            children: [
              Icon(
                tip.icon,
                color: secili ? tip.renk : AppColors.textSecondary,
                size: 22,
              ),
              const SizedBox(height: 7),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tip.etiket,
                  maxLines: 1,
                  style: TextStyle(
                    color: secili ? tip.renk : AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  tip.kisaAd,
                  maxLines: 1,
                  style: TextStyle(
                    color: secili
                        ? tip.renk.withValues(alpha: 0.8)
                        : AppColors.textSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VucutTipiBilgisi extends StatelessWidget {
  const _VucutTipiBilgisi({super.key, required this.tip});

  final _VucutTipi tip;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: tip.renk.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(tip.icon, color: tip.renk, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${tip.etiket} · ${tip.kisaAd}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Kişiselleştirilmiş öneriler',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: tip.renk.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'AKTİF',
                style: TextStyle(
                  color: tip.renk,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          tip.aciklama,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontSize: 12, height: 1.45),
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _IpucuKutusu(
                icon: Icons.fitness_center_rounded,
                baslik: 'Antrenman',
                metin: tip.antrenman,
                renk: tip.renk,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _IpucuKutusu(
                icon: Icons.restaurant_rounded,
                baslik: 'Beslenme',
                metin: tip.beslenme,
                renk: AppColors.amber,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _IpucuKutusu extends StatelessWidget {
  const _IpucuKutusu({
    required this.icon,
    required this.baslik,
    required this.metin,
    required this.renk,
  });

  final IconData icon;
  final String baslik;
  final String metin;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: renk, size: 13),
              const SizedBox(width: 5),
              Text(
                baslik,
                style: TextStyle(
                  color: renk,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            metin,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 10, height: 1.35),
          ),
        ],
      ),
    );
  }
}

class _BolgeButonu extends StatelessWidget {
  const _BolgeButonu({
    required this.bolge,
    required this.secili,
    required this.onTap,
  });

  final _KasBolgesi bolge;
  final bool secili;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: secili
                ? bolge.renk.withValues(alpha: 0.14)
                : AppColors.surfaceHigh.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: secili
                  ? bolge.renk.withValues(alpha: 0.6)
                  : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: bolge.renk,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    bolge.etiket,
                    maxLines: 1,
                    style: TextStyle(
                      color: secili ? bolge.renk : AppColors.textSecondary,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EgzersizSatiri extends StatelessWidget {
  const _EgzersizSatiri({
    required this.egzersiz,
    required this.renk,
    required this.set,
    required this.tekrar,
    required this.dinlenme,
  });

  final _Egzersiz egzersiz;
  final Color renk;
  final int set;
  final String tekrar;
  final String dinlenme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
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
            child: Icon(egzersiz.icon, color: renk, size: 19),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  egzersiz.isim,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${egzersiz.ekipman}  ·  ${egzersiz.zorluk}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$set × $tekrar',
                style: TextStyle(
                  color: renk,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$dinlenme dinlenme',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BolumBasligi extends StatelessWidget {
  const _BolumBasligi({
    required this.icon,
    required this.renk,
    required this.baslik,
    required this.altBaslik,
  });

  final IconData icon;
  final Color renk;
  final String baslik;
  final String altBaslik;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: renk.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: renk, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(baslik, style: Theme.of(context).textTheme.titleMedium),
              Text(
                altBaslik,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
