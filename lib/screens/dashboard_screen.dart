import 'package:flutter/material.dart';

import '../models/fitness_models.dart';
import '../theme/app_theme.dart';

/// Ana ekran: günlük kalori/protein özeti, hızlı öğün ekleme ve suplement
/// takibi.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.ogunler,
    required this.suplementler,
    required this.hedefKalori,
    required this.hedefProtein,
    this.yakilanKalori = 0,
    required this.suMl,
    required this.suHedefMl,
    required this.onOgunEkle,
    required this.onOgunSil,
    required this.onSuplementToggle,
    required this.onSuEkle,
    required this.onSuEkraniAc,
    required this.onHedefDuzenle,
  });

  final List<Ogun> ogunler;
  final List<Suplement> suplementler;
  final int hedefKalori;
  final int hedefProtein;

  /// Aktivite sekmesinde bugün yakılan toplam kalori.
  final double yakilanKalori;

  /// Bugün içilen su ve günlük su hedefi (ml).
  final int suMl;
  final int suHedefMl;

  final ValueChanged<Ogun> onOgunEkle;
  final ValueChanged<Ogun> onOgunSil;
  final ValueChanged<int> onSuplementToggle;
  final ValueChanged<int> onSuEkle;
  final VoidCallback onSuEkraniAc;
  final VoidCallback onHedefDuzenle;

  int get _alinanKalori => ogunler.fold<int>(0, (t, o) => t + o.kalori);

  double get _alinanProtein => ogunler.fold<double>(0, (t, o) => t + o.protein);

  double get _alinanKarbonhidrat =>
      ogunler.fold<double>(0, (t, o) => t + o.karbonhidrat);

  double get _alinanYag => ogunler.fold<double>(0, (t, o) => t + o.yag);

  double get _kaloriOran => hedefKalori <= 0
      ? 0
      : (_alinanKalori / hedefKalori).clamp(0.0, 1.0).toDouble();

  double get _proteinOran => hedefProtein <= 0
      ? 0
      : (_alinanProtein / hedefProtein).clamp(0.0, 1.0).toDouble();

  @override
  Widget build(BuildContext context) {
    final int kalanKalori = (hedefKalori - _alinanKalori)
        .clamp(0, 99999)
        .toInt();
    final int alinanSuplement = suplementler.where((s) => s.alindiMi).length;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _buildHeader(context),
            const SizedBox(height: 22),
            _buildKaloriKarti(context, kalanKalori),
            const SizedBox(height: 16),
            _buildProteinKarti(context),
            const SizedBox(height: 12),
            _buildSuKarti(context),
            const SizedBox(height: 12),
            _buildEnerjiDengesi(context),
            const SizedBox(height: 12),
            _buildMakroOzeti(),
            const SizedBox(height: 28),
            _SectionHeader(
              icon: Icons.bolt_rounded,
              renk: AppColors.amber,
              baslik: 'Hızlı Öğün Ekle',
              altBaslik: 'Tek dokunuşla günlüğüne ekle',
            ),
            const SizedBox(height: 12),
            _buildHizliOgunler(context),
            const SizedBox(height: 28),
            _SectionHeader(
              icon: Icons.restaurant_menu_rounded,
              renk: AppColors.blue,
              baslik: 'Bugünün Öğünleri',
              altBaslik: '${ogunler.length} öğün · $_alinanKalori kcal',
            ),
            const SizedBox(height: 12),
            _buildOgunListesi(context),
            const SizedBox(height: 28),
            _SectionHeader(
              icon: Icons.medication_liquid_rounded,
              renk: AppColors.purple,
              baslik: 'Suplementler',
              altBaslik: '$alinanSuplement / ${suplementler.length} tamamlandı',
            ),
            const SizedBox(height: 12),
            _buildSuplementListesi(),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'Hedeflerini hesap ekranından güncelleyebilirsin.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'FITTRACK',
                style: text.labelLarge?.copyWith(
                  color: AppColors.green,
                  letterSpacing: 2.4,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 4),
              Text('Bugünün Özeti', style: text.headlineMedium),
              const SizedBox(height: 4),
              Text(_tarihMetni(), style: text.bodyMedium),
            ],
          ),
        ),
        _YuvarlakIkonButon(
          icon: Icons.tune_rounded,
          tooltip: 'Hedefleri düzenle',
          onTap: onHedefDuzenle,
        ),
      ],
    );
  }

  Widget _buildKaloriKarti(BuildContext context, int kalanKalori) {
    final TextTheme text = Theme.of(context).textTheme;
    final Color progressColor = _kaloriOran >= 1
        ? AppColors.amber
        : AppColors.green;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF20232A), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 132,
            height: 132,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: _kaloriOran),
                  duration: const Duration(milliseconds: 700),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return SizedBox.expand(
                      child: CircularProgressIndicator(
                        value: value,
                        strokeWidth: 11,
                        strokeCap: StrokeCap.round,
                        backgroundColor: AppColors.surfaceHigh,
                        color: progressColor,
                      ),
                    );
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$_alinanKalori',
                        style: text.displaySmall?.copyWith(fontSize: 30),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '/ $hedefKalori kcal',
                      style: text.bodyMedium?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'KALORİ',
                  style: text.labelLarge?.copyWith(
                    color: AppColors.textSecondary,
                    letterSpacing: 1.6,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$kalanKalori',
                  style: text.displaySmall?.copyWith(color: progressColor),
                ),
                Text('kcal kaldı', style: text.bodyMedium),
                const SizedBox(height: 14),
                _MiniBilgi(
                  icon: Icons.local_fire_department_rounded,
                  renk: AppColors.amber,
                  metin: 'Hedefin %${(_kaloriOran * 100).round()} tamam',
                ),
                const SizedBox(height: 6),
                _MiniBilgi(
                  icon: Icons.schedule_rounded,
                  renk: AppColors.blue,
                  metin: 'Günlük hedef: $hedefKalori kcal',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProteinKarti(BuildContext context) {
    final double protein = _alinanProtein;
    final int kalanProtein = (hedefProtein - protein)
        .ceil()
        .clamp(0, 9999)
        .toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fitness_center_rounded,
                  color: AppColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Protein',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Kilo başına 2 g hedefi',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: protein.toStringAsFixed(1),
                      style: const TextStyle(
                        color: AppColors.blue,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' / $hedefProtein g',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: _proteinOran),
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 9,
                  backgroundColor: AppColors.surfaceHigh,
                  color: AppColors.blue,
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(_proteinOran * 100).round()}% tamamlandı',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 11),
              ),
              Text(
                '$kalanProtein g kaldı',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.blue,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEnerjiDengesi(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int alinan = _alinanKalori;
    final int yakilan = yakilanKalori.round();
    final int net = alinan - yakilan;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1E2620), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.amber.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.swap_vert_rounded,
                  color: AppColors.amber,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enerji Dengesi',
                      style: text.titleMedium?.copyWith(fontSize: 14),
                    ),
                    Text(
                      'Bugün alınan − aktiviteyle yakılan',
                      style: text.bodyMedium?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _EnerjiKutusu(
                  baslik: 'Alınan',
                  deger: '$alinan',
                  renk: AppColors.blue,
                  icon: Icons.restaurant_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EnerjiKutusu(
                  baslik: 'Yakılan',
                  deger: '$yakilan',
                  renk: AppColors.amber,
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _EnerjiKutusu(
                  baslik: 'Net',
                  deger: '$net',
                  renk: AppColors.green,
                  icon: Icons.balance_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            yakilan > 0
                ? 'Aktivite seansların toplam $yakilan kcal yakım sağladı.'
                : 'Henüz aktivite kaydı yok. Aktivite sekmesinden bir seans '
                      'başlatabilirsin.',
            style: text.bodyMedium?.copyWith(fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildMakroOzeti() {
    return Row(
      children: [
        Expanded(
          child: _MakroKarti(
            baslik: 'Karbonhidrat',
            deger: _alinanKarbonhidrat,
            renk: AppColors.amber,
            icon: Icons.grain_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MakroKarti(
            baslik: 'Yağ',
            deger: _alinanYag,
            renk: AppColors.purple,
            icon: Icons.water_drop_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _MakroKarti(
            baslik: 'Öğün',
            deger: ogunler.length.toDouble(),
            renk: AppColors.green,
            icon: Icons.restaurant_rounded,
            birim: 'adet',
            ondalik: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildSuKarti(BuildContext context) {
    final double oran = suHedefMl <= 0
        ? 0
        : (suMl / suHedefMl).clamp(0.0, 1.0).toDouble();
    final int kalan = (suHedefMl - suMl).clamp(0, 99999).toInt();
    final TextTheme text = Theme.of(context).textTheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSuEkraniAc,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: <Color>[Color(0xFF122431), AppColors.surface],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.blue.withValues(alpha: 0.32)),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.blue.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.water_drop_rounded,
                      color: AppColors.blue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Su Takibi', style: text.titleMedium),
                        Text(
                          '$kalan ml kaldı · ${_litre(suMl)} / '
                          '${_litre(suHedefMl)} L',
                          style: text.bodyMedium?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      onSuEkle(250);
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text('+250 ml su eklendi.'),
                            duration: Duration(seconds: 1),
                          ),
                        );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.blue.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: AppColors.blue.withValues(alpha: 0.4),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add_rounded,
                            color: AppColors.blue,
                            size: 14,
                          ),
                          SizedBox(width: 3),
                          Text(
                            '250 ml',
                            style: TextStyle(
                              color: AppColors.blue,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: 0, end: oran),
                  duration: const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (BuildContext context, double value, Widget? child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceHigh,
                      color: oran >= 1 ? AppColors.green : AppColors.blue,
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '%${(oran * 100).round()} tamamlandı',
                    style: text.bodyMedium?.copyWith(fontSize: 10),
                  ),
                  const Spacer(),
                  Text(
                    'Detaylı takip',
                    style: text.bodyMedium?.copyWith(
                      fontSize: 10,
                      color: AppColors.blue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _litre(int ml) => (ml / 1000).toStringAsFixed(2);

  Widget _buildHizliOgunler(BuildContext context) {
    return SizedBox(
      height: 136,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: hazirOgunler.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final Ogun ogun = hazirOgunler[index];
          final bool vurgulu = index.isEven;
          final Color renk = vurgulu ? AppColors.green : AppColors.blue;
          return _HizliOgunKarti(
            ogun: ogun,
            renk: renk,
            onTap: () {
              onOgunEkle(ogun);
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text(
                      '${ogun.isim} günlüğe eklendi · '
                      '${ogun.kalori} kcal',
                    ),
                    duration: const Duration(seconds: 2),
                  ),
                );
            },
          );
        },
      ),
    );
  }

  Widget _buildOgunListesi(BuildContext context) {
    if (ogunler.isEmpty) {
      return _BosDurum(
        icon: Icons.no_meals_rounded,
        baslik: 'Henüz öğün eklenmedi',
        aciklama: 'Yukarıdaki hazır öğünlerden birine dokunarak başla.',
      );
    }

    return Column(
      children: [
        for (int i = 0; i < ogunler.length; i++) ...[
          _OgunSatiri(ogun: ogunler[i], onSil: () => onOgunSil(ogunler[i])),
          if (i != ogunler.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildSuplementListesi() {
    return Column(
      children: [
        for (int i = 0; i < suplementler.length; i++) ...[
          _SuplementSatiri(
            suplement: suplementler[i],
            onTap: () => onSuplementToggle(i),
          ),
          if (i != suplementler.length - 1) const SizedBox(height: 8),
        ],
      ],
    );
  }

  String _tarihMetni() {
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
    const List<String> gunler = <String>[
      'Pazartesi',
      'Salı',
      'Çarşamba',
      'Perşembe',
      'Cuma',
      'Cumartesi',
      'Pazar',
    ];
    final DateTime now = DateTime.now();
    return '${gunler[now.weekday - 1]}, ${now.day} ${aylar[now.month - 1]}';
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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

class _MiniBilgi extends StatelessWidget {
  const _MiniBilgi({
    required this.icon,
    required this.renk,
    required this.metin,
  });

  final IconData icon;
  final Color renk;
  final String metin;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: renk),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            metin,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 11),
          ),
        ),
      ],
    );
  }
}

class _EnerjiKutusu extends StatelessWidget {
  const _EnerjiKutusu({
    required this.baslik,
    required this.deger,
    required this.renk,
    required this.icon,
  });

  final String baslik;
  final String deger;
  final Color renk;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: renk, size: 15),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              deger,
              style: TextStyle(
                color: renk,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 1),
          Text(
            '$baslik · kcal',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _MakroKarti extends StatelessWidget {
  const _MakroKarti({
    required this.baslik,
    required this.deger,
    required this.renk,
    required this.icon,
    this.birim = 'g',
    this.ondalik = 1,
  });

  final String baslik;
  final double deger;
  final Color renk;
  final IconData icon;
  final String birim;
  final int ondalik;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
            child: Text(
              '${deger.toStringAsFixed(ondalik)} $birim',
              style: TextStyle(
                color: renk,
                fontSize: 17,
                fontWeight: FontWeight.w800,
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

class _HizliOgunKarti extends StatelessWidget {
  const _HizliOgunKarti({
    required this.ogun,
    required this.renk,
    required this.onTap,
  });

  final Ogun ogun;
  final Color renk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 148,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: renk.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: renk.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.add_rounded, color: renk, size: 20),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.textSecondary.withValues(alpha: 0.6),
                    size: 18,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                ogun.isim,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontSize: 13),
              ),
              const SizedBox(height: 4),
              Text(
                '${ogun.kalori} kcal · ${ogun.protein.toStringAsFixed(0)} g protein',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OgunSatiri extends StatelessWidget {
  const _OgunSatiri({required this.ogun, required this.onSil});

  final Ogun ogun;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
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
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              color: AppColors.green,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ogun.isim, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(
                  '${ogun.kalori} kcal  ·  P ${ogun.protein.toStringAsFixed(1)} g'
                  '  ·  K ${ogun.karbonhidrat.toStringAsFixed(1)} g'
                  '  ·  Y ${ogun.yag.toStringAsFixed(1)} g',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onSil,
            tooltip: 'Öğünü sil',
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
}

class _SuplementSatiri extends StatelessWidget {
  const _SuplementSatiri({required this.suplement, required this.onTap});

  final Suplement suplement;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bool alindi = suplement.alindiMi;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: alindi
                ? AppColors.green.withValues(alpha: 0.08)
                : AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: alindi
                  ? AppColors.green.withValues(alpha: 0.55)
                  : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: (alindi ? AppColors.green : AppColors.purple)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.medication_rounded,
                  color: alindi ? AppColors.green : AppColors.purple,
                  size: 19,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      suplement.isim,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: alindi ? TextDecoration.lineThrough : null,
                        color: alindi
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suplement.dozaj,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: alindi ? AppColors.green : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(
                    color: alindi ? AppColors.green : AppColors.border,
                    width: 1.6,
                  ),
                ),
                child: alindi
                    ? const Icon(
                        Icons.check_rounded,
                        color: Color(0xFF00210E),
                        size: 18,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(vertical: 26, horizontal: 18),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 28),
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

class _YuvarlakIkonButon extends StatelessWidget {
  const _YuvarlakIkonButon({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.border),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 46,
            height: 46,
            child: Icon(icon, color: AppColors.textPrimary),
          ),
        ),
      ),
    );
  }
}
