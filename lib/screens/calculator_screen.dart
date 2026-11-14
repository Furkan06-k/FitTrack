import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Hedef kaydetme geri çağrısı.
typedef HedefKaydetCallback = void Function({
  required int boy,
  required double kilo,
  required double hedefKilo,
  required int kalori,
  required int protein,
});

/// Boy, kilo ve hedef kiloya göre günlük kalori/protein hesaplayan ekran.
class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({
    super.key,
    required this.boy,
    required this.kilo,
    required this.hedefKilo,
    required this.hedefKalori,
    required this.hedefProtein,
    required this.onKaydet,
  });

  final int boy;
  final double kilo;
  final double hedefKilo;
  final int hedefKalori;
  final int hedefProtein;
  final HedefKaydetCallback onKaydet;

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  late final TextEditingController _boyController;
  late final TextEditingController _kiloController;
  late final TextEditingController _hedefKiloController;

  @override
  void initState() {
    super.initState();
    _boyController = TextEditingController(
      text: _kisaYaz(widget.boy.toDouble()),
    );
    _kiloController = TextEditingController(text: _kisaYaz(widget.kilo));
    _hedefKiloController = TextEditingController(
      text: _kisaYaz(widget.hedefKilo),
    );

    _boyController.addListener(_yenidenHesapla);
    _kiloController.addListener(_yenidenHesapla);
    _hedefKiloController.addListener(_yenidenHesapla);
  }

  @override
  void dispose() {
    _boyController.dispose();
    _kiloController.dispose();
    _hedefKiloController.dispose();
    super.dispose();
  }

  void _yenidenHesapla() {
    setState(() {});
  }

  double? get _boy => _ondalikOku(_boyController.text);
  double? get _kilo => _ondalikOku(_kiloController.text);
  double? get _hedefKilo => _ondalikOku(_hedefKiloController.text);

  bool get _girdilerGecerli {
    final double? boy = _boy;
    final double? kilo = _kilo;
    final double? hedef = _hedefKilo;
    return boy != null &&
        boy >= 100 &&
        boy <= 250 &&
        kilo != null &&
        kilo >= 30 &&
        kilo <= 300 &&
        hedef != null &&
        hedef >= 30 &&
        hedef <= 300;
  }

  int get _hesaplananKalori {
    if (!_girdilerGecerli) {
      return 0;
    }
    final double boy = _boy!;
    final double kilo = _kilo!;
    final double hedef = _hedefKilo!;

    // Mifflin-St Jeor denkleminin cinsiyet-nötr ortalaması.
    final double bmr = 10 * kilo + 6.25 * boy - 5 * 25 - 78;
    final double tdee = bmr * 1.55;

    final double fark = hedef - kilo;
    double kalori = tdee;
    if (fark < -0.5) {
      kalori -= 500; // Yağ kaybı için ılımlı açık
    } else if (fark > 0.5) {
      kalori += 300; // Kas kazanımı için ılımlı fazla
    }

    return kalori.round().clamp(1200, 5000).toInt();
  }

  int get _hesaplananProtein {
    if (!_girdilerGecerli) {
      return 0;
    }
    return (_kilo! * 2).round();
  }

  double? get _vucutKitleIndeksi {
    if (!_girdilerGecerli) {
      return null;
    }
    final double boyMetre = _boy! / 100;
    return _kilo! / (boyMetre * boyMetre);
  }

  @override
  Widget build(BuildContext context) {
    final double? bmi = _vucutKitleIndeksi;
    final bool gecerli = _girdilerGecerli;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            _buildHeader(context),
            const SizedBox(height: 20),
            _buildBilgiKarti(context),
            const SizedBox(height: 18),
            _buildFormKarti(context),
            const SizedBox(height: 18),
            _buildSonucKarti(context, gecerli),
            const SizedBox(height: 14),
            _buildBmiKarti(context, bmi),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: gecerli ? _hedefiKaydet : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  disabledBackgroundColor: AppColors.surfaceHigh,
                  disabledForegroundColor: AppColors.textSecondary,
                  foregroundColor: const Color(0xFF00210E),
                  padding: const EdgeInsets.symmetric(vertical: 17),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.save_rounded, size: 20),
                label: const Text(
                  'Hedefi Ana Ekrana Kaydet',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Not: Hesaplama tahmini bir başlangıç noktasıdır. '
              'Mifflin-St Jeor denklemi, orta düzey aktivite ve kilo başına '
              '2 g protein esas alınır. Sağlık durumun için uzmana danış.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 11),
            ),
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
          'HESAPLA',
          style: text.labelLarge?.copyWith(
            color: AppColors.green,
            letterSpacing: 2.4,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text('Hedefini Belirle', style: text.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Günlük kalori ve protein hedefin otomatik hesaplansın.',
          style: text.bodyMedium,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MevcutHedefCipi(
              icon: Icons.local_fire_department_rounded,
              renk: AppColors.amber,
              metin: '${widget.hedefKalori} kcal',
            ),
            _MevcutHedefCipi(
              icon: Icons.fitness_center_rounded,
              renk: AppColors.blue,
              metin: '${widget.hedefProtein} g protein',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBilgiKarti(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.blue,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hedef kilon mevcut kilondan düşükse kalori açığı, yüksekse '
              'kontrollü kalori fazlası uygulanır. Protein hedefi her zaman '
              'kilo başına 2 g olarak hesaplanır.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 12, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormKarti(BuildContext context) {
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
              const Icon(
                Icons.straighten_rounded,
                color: AppColors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Bilgilerin',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _GirdiAlani(
            controller: _boyController,
            etiket: 'Boy',
            birim: 'cm',
            icon: Icons.height_rounded,
            ondalik: false,
            hata: _boyHatasi(),
          ),
          const SizedBox(height: 12),
          _GirdiAlani(
            controller: _kiloController,
            etiket: 'Mevcut kilo',
            birim: 'kg',
            icon: Icons.monitor_weight_outlined,
            ondalik: true,
            hata: _kiloHatasi(),
          ),
          const SizedBox(height: 12),
          _GirdiAlani(
            controller: _hedefKiloController,
            etiket: 'Hedef kilo',
            birim: 'kg',
            icon: Icons.flag_outlined,
            ondalik: true,
            hata: _hedefKiloHatasi(),
          ),
        ],
      ),
    );
  }

  Widget _buildSonucKarti(BuildContext context, bool gecerli) {
    final TextTheme text = Theme.of(context).textTheme;
    final int kalori = _hesaplananKalori;
    final int protein = _hesaplananProtein;
    final int karbonhidrat = gecerli
        ? ((kalori - protein * 4) * 0.45 / 4).round().clamp(0, 9999).toInt()
        : 0;
    final int yag = gecerli
        ? ((kalori * 0.28) / 9).round().clamp(0, 9999).toInt()
        : 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF17251C), Color(0xFF171B24)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Günlük Hedefin',
                style: text.titleMedium?.copyWith(fontSize: 16),
              ),
              const Spacer(),
              if (!gecerli)
                Text(
                  'Veri bekleniyor',
                  style: text.bodyMedium?.copyWith(fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _SonucDegeri(
                  deger: gecerli ? '$kalori' : '—',
                  birim: 'kcal',
                  etiket: 'Kalori',
                  renk: AppColors.green,
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SonucDegeri(
                  deger: gecerli ? '$protein' : '—',
                  birim: 'g',
                  etiket: 'Protein',
                  renk: AppColors.blue,
                  icon: Icons.fitness_center_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _KucukSonuc(
                  etiket: 'Karbonhidrat',
                  deger: gecerli ? '$karbonhidrat g' : '—',
                  renk: AppColors.amber,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _KucukSonuc(
                  etiket: 'Yağ',
                  deger: gecerli ? '$yag g' : '—',
                  renk: AppColors.purple,
                ),
              ),
            ],
          ),
          if (gecerli) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                Icon(_hedefYonu().icon, size: 14, color: _hedefYonu().renk),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _hedefYonu().metin,
                    style: text.bodyMedium?.copyWith(
                      fontSize: 11,
                      color: _hedefYonu().renk,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBmiKarti(BuildContext context, double? bmi) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: AppColors.green,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vücut Kitle İndeksi',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  bmi == null
                      ? 'Bilgilerini girerek görebilirsin.'
                      : '${bmi.toStringAsFixed(1)} · ${_bmiSinifi(bmi)}',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _HedefYonu _hedefYonu() {
    final double fark = (_hedefKilo ?? 0) - (_kilo ?? 0);
    if (fark < -0.5) {
      return const _HedefYonu(
        icon: Icons.trending_down_rounded,
        renk: AppColors.amber,
        metin: 'Yağ kaybı için ılımlı kalori açığı uygulanıyor.',
      );
    }
    if (fark > 0.5) {
      return const _HedefYonu(
        icon: Icons.trending_up_rounded,
        renk: AppColors.blue,
        metin: 'Kas kazanımı için kontrollü kalori fazlası uygulanıyor.',
      );
    }
    return const _HedefYonu(
      icon: Icons.horizontal_rule_rounded,
      renk: AppColors.green,
      metin: 'Kilo koruma modu: hedef, bakım kalorisi olarak ayarlandı.',
    );
  }

  String? _boyHatasi() {
    final double? deger = _boy;
    if (deger != null && (deger < 100 || deger > 250)) {
      return '100 - 250 cm arasında olmalı';
    }
    return null;
  }

  String? _kiloHatasi() {
    final double? deger = _kilo;
    if (deger != null && (deger < 30 || deger > 300)) {
      return '30 - 300 kg arasında olmalı';
    }
    return null;
  }

  String? _hedefKiloHatasi() {
    final double? deger = _hedefKilo;
    if (deger != null && (deger < 30 || deger > 300)) {
      return '30 - 300 kg arasında olmalı';
    }
    return null;
  }

  void _hedefiKaydet() {
    if (!_girdilerGecerli) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Lütfen geçerli bilgiler gir.')),
        );
      return;
    }

    FocusScope.of(context).unfocus();
    widget.onKaydet(
      boy: _boy!.round(),
      kilo: _kilo!,
      hedefKilo: _hedefKilo!,
      kalori: _hesaplananKalori,
      protein: _hesaplananProtein,
    );

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            'Hedef güncellendi · $_hesaplananKalori kcal · '
            '$_hesaplananProtein g protein',
          ),
        ),
      );
  }

  double? _ondalikOku(String value) {
    final String temiz = value.trim().replaceAll(',', '.');
    if (temiz.isEmpty) {
      return null;
    }
    return double.tryParse(temiz);
  }

  String _kisaYaz(double deger) {
    if (deger == deger.roundToDouble()) {
      return deger.toStringAsFixed(0);
    }
    return deger.toStringAsFixed(1);
  }

  String _bmiSinifi(double bmi) {
    if (bmi < 18.5) {
      return 'Zayıf';
    }
    if (bmi < 25) {
      return 'Normal';
    }
    if (bmi < 30) {
      return 'Fazla kilolu';
    }
    return 'Obez';
  }
}

class _GirdiAlani extends StatelessWidget {
  const _GirdiAlani({
    required this.controller,
    required this.etiket,
    required this.birim,
    required this.icon,
    required this.ondalik,
    this.hata,
  });

  final TextEditingController controller;
  final String etiket;
  final String birim;
  final IconData icon;
  final bool ondalik;
  final String? hata;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: ondalik),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          ondalik ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: etiket,
        prefixIcon: Icon(icon, size: 20),
        suffixText: birim,
        suffixStyle: const TextStyle(
          color: AppColors.textSecondary,
          fontWeight: FontWeight.w600,
        ),
        errorText: hata,
      ),
    );
  }
}

class _SonucDegeri extends StatelessWidget {
  const _SonucDegeri({
    required this.deger,
    required this.birim,
    required this.etiket,
    required this.renk,
    required this.icon,
  });

  final String deger;
  final String birim;
  final String etiket;
  final Color renk;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: renk.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: renk, size: 16),
              const SizedBox(width: 5),
              Text(
                etiket,
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 10),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: ' $birim',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KucukSonuc extends StatelessWidget {
  const _KucukSonuc({
    required this.etiket,
    required this.deger,
    required this.renk,
  });

  final String etiket;
  final String deger;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: renk, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              etiket,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 10),
            ),
          ),
          Text(
            deger,
            style: TextStyle(
              color: renk,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _MevcutHedefCipi extends StatelessWidget {
  const _MevcutHedefCipi({
    required this.icon,
    required this.renk,
    required this.metin,
  });

  final IconData icon;
  final Color renk;
  final String metin;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
      decoration: BoxDecoration(
        color: renk.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: renk.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: renk, size: 13),
          const SizedBox(width: 5),
          Text(
            metin,
            style: TextStyle(
              color: renk,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _HedefYonu {
  const _HedefYonu({
    required this.icon,
    required this.renk,
    required this.metin,
  });

  final IconData icon;
  final Color renk;
  final String metin;
}
