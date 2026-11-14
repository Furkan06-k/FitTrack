import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/fitness_models.dart';
import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Yemek ekleme modu.
enum _EklemeModu {
  manuel('Manuel & Hızlı Liste'),
  ai('AI Fotoğraf');

  const _EklemeModu(this.etiket);

  final String etiket;
}

/// Sık yenilen besinler; tek dokunuşla günlüğe eklenir.
const List<Ogun> _hizliBesinler = <Ogun>[
  Ogun(
    isim: 'Yulaf Kasesi',
    kalori: 350,
    protein: 14,
    karbonhidrat: 55,
    yag: 9,
    gramaj: 250,
    kaynak: 'Hızlı Liste',
  ),
  Ogun(
    isim: 'Tavuk Göğsü',
    kalori: 285,
    protein: 53,
    karbonhidrat: 0,
    yag: 6,
    gramaj: 150,
    kaynak: 'Hızlı Liste',
  ),
  Ogun(
    isim: 'Ton Balığı',
    kalori: 220,
    protein: 40,
    karbonhidrat: 0,
    yag: 5,
    gramaj: 120,
    kaynak: 'Hızlı Liste',
  ),
  Ogun(
    isim: 'Yumurta',
    kalori: 155,
    protein: 13,
    karbonhidrat: 1.1,
    yag: 11,
    gramaj: 100,
    kaynak: 'Hızlı Liste',
  ),
  Ogun(
    isim: 'Whey Protein',
    kalori: 120,
    protein: 24,
    karbonhidrat: 3,
    yag: 1.5,
    gramaj: 30,
    kaynak: 'Hızlı Liste',
  ),
];

/// Manuel ve yapay zeka destekli fotoğraf analizi ile yemek takibi.
///
/// Tüm öğünler merkezi [AppState] üzerinde tutulur; buradan eklenen bir yemek
/// dashboard'daki kalori ve makro toplamlarını anında günceller.
class NutritionAiScreen extends StatefulWidget {
  const NutritionAiScreen({super.key, required this.state});

  final AppState state;

  @override
  State<NutritionAiScreen> createState() => _NutritionAiScreenState();
}

class _NutritionAiScreenState extends State<NutritionAiScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _isimController = TextEditingController();
  final TextEditingController _gramajController = TextEditingController(
    text: '100',
  );
  final TextEditingController _kaloriController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _karbonhidratController = TextEditingController();
  final TextEditingController _yagController = TextEditingController();

  _EklemeModu _mod = _EklemeModu.manuel;

  AppState get _state => widget.state;

  @override
  void dispose() {
    _isimController.dispose();
    _gramajController.dispose();
    _kaloriController.dispose();
    _proteinController.dispose();
    _karbonhidratController.dispose();
    _yagController.dispose();
    super.dispose();
  }

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
            _buildOzetKarti(context),
            const SizedBox(height: 22),
            _buildModSecimi(context),
            const SizedBox(height: 14),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _mod == _EklemeModu.manuel
                  ? _buildManuelMod(context)
                  : _buildAiMod(context),
            ),
            const SizedBox(height: 26),
            _buildOgunBasligi(context),
            const SizedBox(height: 12),
            _buildOgunListesi(context),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Üst özet
  // ---------------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'BESLENME',
          style: text.labelLarge?.copyWith(
            color: AppColors.green,
            letterSpacing: 2.4,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text('Akıllı Yemek Takibi', style: text.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Manuel gir, hızlı listeden seç ya da yapay zeka ile fotoğraftan analiz et.',
          style: text.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildOzetKarti(BuildContext context) {
    final TextTheme text = Theme.of(context).textTheme;
    final int hedef = _state.hedefKalori;
    final int alinan = _state.alinanKalori;
    final int kalan = (hedef - alinan).clamp(0, 99999).toInt();
    final double oran = hedef <= 0
        ? 0
        : (alinan / hedef).clamp(0.0, 1.0).toDouble();
    final Color kaloriRenk = alinan > hedef ? AppColors.amber : AppColors.green;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF1B241F), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_dining_rounded,
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
                      'Günlük Kalori',
                      style: text.titleMedium?.copyWith(fontSize: 14),
                    ),
                    Text(
                      '${_state.ogunSayisi} öğün · $kalan kcal kaldı',
                      style: text.bodyMedium?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$alinan',
                      style: TextStyle(
                        color: kaloriRenk,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    TextSpan(
                      text: ' / $hedef',
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
          _MakroBar(
            etiket: 'Kalori',
            deger: alinan.toDouble(),
            hedef: hedef.toDouble(),
            birim: 'kcal',
            renk: kaloriRenk,
            icon: Icons.local_fire_department_rounded,
            oran: oran,
          ),
          const SizedBox(height: 12),
          _MakroBar(
            etiket: 'Protein',
            deger: _state.alinanProtein,
            hedef: _state.hedefProtein.toDouble(),
            birim: 'g',
            renk: AppColors.blue,
            icon: Icons.fitness_center_rounded,
          ),
          const SizedBox(height: 12),
          _MakroBar(
            etiket: 'Karbonhidrat',
            deger: _state.alinanKarbonhidrat,
            hedef: _state.hedefKarbonhidrat.toDouble(),
            birim: 'g',
            renk: AppColors.amber,
            icon: Icons.grain_rounded,
          ),
          const SizedBox(height: 12),
          _MakroBar(
            etiket: 'Yağ',
            deger: _state.alinanYag,
            hedef: _state.hedefYag.toDouble(),
            birim: 'g',
            renk: AppColors.purple,
            icon: Icons.water_drop_rounded,
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mod seçimi
  // ---------------------------------------------------------------------------

  Widget _buildModSecimi(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          for (final _EklemeModu mod in _EklemeModu.values) ...[
            Expanded(
              child: _ModButonu(
                etiket: mod.etiket,
                icon: mod == _EklemeModu.manuel
                    ? Icons.edit_note_rounded
                    : Icons.auto_awesome_rounded,
                secili: _mod == mod,
                onTap: () => _modDegistir(mod),
              ),
            ),
            if (mod != _EklemeModu.values.last) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Mod A: manuel giriş ve hızlı liste
  // ---------------------------------------------------------------------------

  Widget _buildManuelMod(BuildContext context) {
    return Column(
      key: const ValueKey<String>('manuel-mod'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.add_circle_outline_rounded,
                      color: AppColors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Manuel Yemek Ekle',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _isimController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Yemek adı',
                    hintText: 'Örn. Tavuklu pilav',
                    prefixIcon: Icon(Icons.restaurant_rounded),
                  ),
                  validator: (String? value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Yemek adı gerekli';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SayiAlani(
                        controller: _gramajController,
                        etiket: 'Gramaj (g)',
                        icon: Icons.scale_rounded,
                        ondalik: true,
                        validator: (String? value) => _sayiDogrula(
                          value,
                          'Gramaj',
                          1,
                          5000,
                          zorunlu: false,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SayiAlani(
                        controller: _kaloriController,
                        etiket: 'Kalori (kcal)',
                        icon: Icons.local_fire_department_rounded,
                        ondalik: false,
                        validator: (String? value) =>
                            _sayiDogrula(value, 'Kalori', 1, 5000),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _SayiAlani(
                        controller: _proteinController,
                        etiket: 'Protein (g)',
                        icon: Icons.fitness_center_rounded,
                        ondalik: true,
                        validator: (String? value) =>
                            _sayiDogrula(value, 'Protein', 0, 500),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SayiAlani(
                        controller: _karbonhidratController,
                        etiket: 'Karbonhidrat',
                        icon: Icons.grain_rounded,
                        ondalik: true,
                        validator: (String? value) =>
                            _sayiDogrula(value, 'Karbonhidrat', 0, 1000),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SayiAlani(
                        controller: _yagController,
                        etiket: 'Yağ (g)',
                        icon: Icons.water_drop_rounded,
                        ondalik: true,
                        validator: (String? value) =>
                            _sayiDogrula(value, 'Yağ', 0, 500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _MakroIpucu(
                  protein: _ondalikOku(_proteinController.text),
                  karbonhidrat: _ondalikOku(_karbonhidratController.text),
                  yag: _ondalikOku(_yagController.text),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _manuelEkle,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: const Color(0xFF00210E),
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: const Text('Yemeği Ekle'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.bolt_rounded, color: AppColors.amber, size: 18),
            const SizedBox(width: 8),
            Text(
              'Sık Yenilen Besinler',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            Text(
              'tek dokunuşla ekle',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 10),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final Ogun besin in _hizliBesinler)
              _HizliBesinCipi(besin: besin, onTap: () => _hizliEkle(besin)),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _aiFotografYukle,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.purple,
              side: BorderSide(color: AppColors.purple.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.photo_camera_rounded, size: 19),
            label: const Text('Fotoğraf Çek / Yükle'),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Mod B: AI fotoğraf analizi
  // ---------------------------------------------------------------------------

  Widget _buildAiMod(BuildContext context) {
    return Container(
      key: const ValueKey<String>('ai-mod'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF241B30), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.purple,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Yapay Zeka ile Analiz',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Fotoğraftaki yemekleri tanır, makroları hesaplar.',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  AppColors.purple.withValues(alpha: 0.20),
                  AppColors.blue.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.purple.withValues(alpha: 0.30),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_a_photo_rounded,
                  color: AppColors.purple,
                  size: 38,
                ),
                const SizedBox(height: 10),
                Text(
                  'Yemek fotoğrafını yükle',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tabağın tamamının göründüğü net bir fotoğraf en iyi sonucu verir.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _aiFotografYukle,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: const Color(0xFF1A1030),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.photo_camera_rounded, size: 20),
              label: const Text('Fotoğraf Çek / Yükle'),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.purple,
                size: 13,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Analiz; besinleri, ortalama kaloriyi ve makroları '
                  'otomatik hesaplar.',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Öğün listesi
  // ---------------------------------------------------------------------------

  Widget _buildOgunBasligi(BuildContext context) {
    final List<Ogun> ogunler = _state.ogunler;
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.blue.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(
            Icons.restaurant_menu_rounded,
            color: AppColors.blue,
            size: 18,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Bugünün Öğünleri',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${ogunler.length} öğün · ${_state.alinanKalori} kcal',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(fontSize: 11),
              ),
            ],
          ),
        ),
        if (ogunler.isNotEmpty)
          TextButton(
            onPressed: _tumunuSil,
            style: TextButton.styleFrom(foregroundColor: AppColors.danger),
            child: const Text('Temizle', style: TextStyle(fontSize: 11)),
          ),
      ],
    );
  }

  Widget _buildOgunListesi(BuildContext context) {
    final List<Ogun> ogunler = _state.ogunler;
    if (ogunler.isEmpty) {
      return const _BosDurum(
        icon: Icons.no_meals_rounded,
        baslik: 'Henüz yemek eklenmedi',
        aciklama:
            'Manuel formu, hızlı listeyi ya da AI fotoğraf analizini '
            'kullanarak günlüğünü oluştur.',
      );
    }

    return Column(
      children: [
        for (final Ogun ogun in ogunler) ...[
          _OgunSatiri(ogun: ogun, onSil: () => _ogunSil(ogun)),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Etkileşimler
  // ---------------------------------------------------------------------------

  void _modDegistir(_EklemeModu mod) {
    if (_mod == mod) {
      return;
    }
    setState(() {
      _mod = mod;
    });
  }

  void _manuelEkle() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final Ogun ogun = Ogun(
      isim: _isimController.text.trim(),
      kalori: int.parse(_kaloriController.text.trim()),
      protein: _ondalikOku(_proteinController.text),
      karbonhidrat: _ondalikOku(_karbonhidratController.text),
      yag: _ondalikOku(_yagController.text),
      gramaj: _ondalikOku(_gramajController.text),
      kaynak: 'Manuel',
    );

    _state.ogunEkle(ogun);

    _isimController.clear();
    _kaloriController.clear();
    _proteinController.clear();
    _karbonhidratController.clear();
    _yagController.clear();
    _gramajController.text = '100';
    setState(() {});

    _mesaj('${ogun.isim} eklendi · ${ogun.kalori} kcal');
  }

  void _hizliEkle(Ogun besin) {
    final Ogun ogun = besin.copyWith(kaynak: 'Hızlı Liste');
    _state.ogunEkle(ogun);
    _mesaj(
      '${ogun.isim} hızlı listeyle eklendi · ${ogun.kalori} kcal · '
      '${ogun.protein.toStringAsFixed(0)} g protein',
    );
  }

  Future<void> _aiFotografYukle() async {
    final Ogun? sonuc = await showModalBottomSheet<Ogun>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) => const _AiFotografSayfasi(),
    );
    if (sonuc == null || !mounted) {
      return;
    }
    _state.ogunEkle(sonuc);
    _mesaj(
      '${sonuc.isim} AI analiziyle eklendi · ${sonuc.kalori} kcal · '
      'P ${sonuc.protein.toStringAsFixed(0)} / '
      'K ${sonuc.karbonhidrat.toStringAsFixed(0)} / '
      'Y ${sonuc.yag.toStringAsFixed(0)} g',
    );
  }

  void _ogunSil(Ogun ogun) {
    _state.ogunSil(ogun);
    _mesaj('${ogun.isim} günlükten çıkarıldı.');
  }

  Future<void> _tumunuSil() async {
    if (_state.ogunler.isEmpty) {
      return;
    }
    final bool? onay = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('Tüm öğünler silinsin mi?'),
        content: const Text(
          'Bugünkü yemek listesi tamamen temizlenecek. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Temizle'),
          ),
        ],
      ),
    );
    if (onay != true || !mounted) {
      return;
    }
    for (final Ogun ogun in _state.ogunler.toList()) {
      _state.ogunSil(ogun);
    }
    _mesaj('Bugünkü öğün listesi temizlendi.');
  }

  void _mesaj(String metin) {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(metin)));
  }

  double _ondalikOku(String value) {
    final String temiz = value.trim().replaceAll(',', '.');
    if (temiz.isEmpty) {
      return 0;
    }
    return double.tryParse(temiz) ?? 0;
  }

  String? _sayiDogrula(
    String? value,
    String alan,
    num min,
    num max, {
    bool zorunlu = true,
  }) {
    if (value == null || value.trim().isEmpty) {
      return zorunlu ? '$alan gerekli' : null;
    }
    final double? sayi = double.tryParse(value.trim().replaceAll(',', '.'));
    if (sayi == null) {
      return 'Geçerli bir sayı gir';
    }
    if (sayi < min || sayi > max) {
      return '$min - $max arası';
    }
    return null;
  }
}

// -----------------------------------------------------------------------------
// AI analiz sonuçları (simülasyon)
// -----------------------------------------------------------------------------

class _AiSonuc {
  const _AiSonuc({
    required this.isim,
    required this.besinler,
    required this.kalori,
    required this.protein,
    required this.karbonhidrat,
    required this.yag,
    required this.gramaj,
    required this.guven,
  });

  final String isim;
  final List<String> besinler;
  final int kalori;
  final double protein;
  final double karbonhidrat;
  final double yag;
  final double gramaj;
  final int guven;

  Ogun get ogun => Ogun(
    isim: isim,
    kalori: kalori,
    protein: protein,
    karbonhidrat: karbonhidrat,
    yag: yag,
    gramaj: gramaj,
    kaynak: 'AI Analiz',
  );
}

const List<_AiSonuc> _aiSonuclari = <_AiSonuc>[
  _AiSonuc(
    isim: 'Izgara Tavuk & Bulgur',
    besinler: <String>[
      'Izgara tavuk göğsü 150 g',
      'Bulgur pilavı 120 g',
      'Mevsim salata 80 g',
    ],
    kalori: 620,
    protein: 52,
    karbonhidrat: 58,
    yag: 18,
    gramaj: 350,
    guven: 94,
  ),
  _AiSonuc(
    isim: 'Somon & Tatlı Patates',
    besinler: <String>[
      'Fırında somon 150 g',
      'Tatlı patates 180 g',
      'Brokoli 70 g',
    ],
    kalori: 540,
    protein: 38,
    karbonhidrat: 42,
    yag: 24,
    gramaj: 400,
    guven: 91,
  ),
  _AiSonuc(
    isim: 'Makarna & Köfte',
    besinler: <String>[
      'Haşlanmış makarna 180 g',
      'Izgara köfte 120 g',
      'Domates sosu 50 g',
    ],
    kalori: 720,
    protein: 34,
    karbonhidrat: 78,
    yag: 28,
    gramaj: 350,
    guven: 88,
  ),
  _AiSonuc(
    isim: 'Kahvaltı Tabağı',
    besinler: <String>[
      '2 yumurta 100 g',
      'Beyaz peynir 40 g',
      'Tam buğday ekmeği 60 g',
      'Zeytin 20 g',
    ],
    kalori: 480,
    protein: 26,
    karbonhidrat: 32,
    yag: 27,
    gramaj: 220,
    guven: 96,
  ),
  _AiSonuc(
    isim: 'Mercimek Çorbası & Ekmek',
    besinler: <String>[
      'Mercimek çorbası 300 ml',
      'Tam buğday ekmeği 70 g',
      'Limon 10 g',
    ],
    kalori: 390,
    protein: 18,
    karbonhidrat: 55,
    yag: 9,
    gramaj: 380,
    guven: 90,
  ),
];

/// Fotoğraf yükleme + yapay zeka analiz animasyonu simülasyonu.
///
/// Analiz tamamlandığında "Listeye Ekle" ile sonuç [Ogun] olarak geri döner.
class _AiFotografSayfasi extends StatefulWidget {
  const _AiFotografSayfasi();

  @override
  State<_AiFotografSayfasi> createState() => _AiFotografSayfasiState();
}

class _AiFotografSayfasiState extends State<_AiFotografSayfasi> {
  Timer? _zamanlayici;
  double _ilerleme = 0;
  bool _bitti = false;
  late _AiSonuc _sonuc;

  @override
  void initState() {
    super.initState();
    _sonuc = _aiSonuclari[Random().nextInt(_aiSonuclari.length)];
    _analiziBaslat();
  }

  @override
  void dispose() {
    _zamanlayici?.cancel();
    super.dispose();
  }

  void _analiziBaslat() {
    _zamanlayici?.cancel();
    setState(() {
      _ilerleme = 0;
      _bitti = false;
    });
    _zamanlayici = Timer.periodic(const Duration(milliseconds: 70), (Timer t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _ilerleme = (_ilerleme + 0.022).clamp(0.0, 1.0);
        if (_ilerleme >= 1) {
          _bitti = true;
          t.cancel();
        }
      });
    });
  }

  String get _adimMetni {
    if (_ilerleme < 0.25) {
      return 'Fotoğraf yükleniyor...';
    }
    if (_ilerleme < 0.55) {
      return 'Tabağın genel görünümü taranıyor...';
    }
    if (_ilerleme < 0.8) {
      return 'Besinler tanınıyor ve porsiyonlar ölçülüyor...';
    }
    return 'Kalori ve makrolar hesaplanıyor...';
  }

  @override
  Widget build(BuildContext context) {
    final double yukseklik = MediaQuery.sizeOf(context).height * 0.88;
    return Container(
      constraints: BoxConstraints(maxHeight: yukseklik),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: AppColors.purple,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AI Kalori Analizi',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontSize: 17),
                        ),
                        Text(
                          _bitti
                              ? 'Analiz tamamlandı'
                              : 'Yapay zeka fotoğrafı inceliyor',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    tooltip: 'Kapat',
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildFotografAlani(),
              const SizedBox(height: 16),
              if (!_bitti) ..._buildAnalizDurumu() else ..._buildSonuc(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFotografAlani() {
    return AspectRatio(
      aspectRatio: 16 / 10,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[Color(0xFF3A2D4A), Color(0xFF1E2733)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            Positioned(
              right: -20,
              bottom: -20,
              child: Icon(
                Icons.restaurant_rounded,
                size: 150,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 74,
                    height: 74,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Icon(
                      Icons.local_dining_rounded,
                      color: Colors.white,
                      size: 36,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _sonuc.isim,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'ÖRNEK YEMEK FOTOĞRAFI',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 8,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Positioned(
              left: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.photo_camera_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'YÜKLENDİ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (!_bitti)
              Align(
                alignment: Alignment(0, -1 + 2 * _ilerleme),
                child: Container(
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.purple,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: AppColors.purple.withValues(alpha: 0.8),
                        blurRadius: 12,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              ),
            if (_bitti)
              Positioned(
                right: 12,
                top: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: Color(0xFF00210E),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '%${_sonuc.guven} güven',
                        style: const TextStyle(
                          color: Color(0xFF00210E),
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildAnalizDurumu() {
    return <Widget>[
      Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: _ilerleme,
                  strokeWidth: 4,
                  backgroundColor: AppColors.surfaceHigh,
                  color: AppColors.purple,
                ),
                Text(
                  '%${(_ilerleme * 100).round()}',
                  style: const TextStyle(
                    color: AppColors.purple,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _adimMetni,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: LinearProgressIndicator(
                    value: _ilerleme,
                    minHeight: 6,
                    backgroundColor: AppColors.surfaceHigh,
                    color: AppColors.purple,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Text(
        'Besinler, porsiyonlar ve makrolar otomatik hesaplanıyor. '
        'Bu işlem birkaç saniye sürer.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
      ),
    ];
  }

  List<Widget> _buildSonuc() {
    return <Widget>[
      Text(
        'Tanınan Besinler',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final String besin in _sonuc.besinler)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.purple.withValues(alpha: 0.30),
                ),
              ),
              child: Text(
                besin,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      const SizedBox(height: 14),
      Row(
        children: [
          Expanded(
            child: _SonucKutusu(
              baslik: 'Kalori',
              deger: '${_sonuc.kalori}',
              birim: 'kcal',
              renk: AppColors.green,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SonucKutusu(
              baslik: 'Protein',
              deger: _sonuc.protein.toStringAsFixed(0),
              birim: 'g',
              renk: AppColors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SonucKutusu(
              baslik: 'Karb.',
              deger: _sonuc.karbonhidrat.toStringAsFixed(0),
              birim: 'g',
              renk: AppColors.amber,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _SonucKutusu(
              baslik: 'Yağ',
              deger: _sonuc.yag.toStringAsFixed(0),
              birim: 'g',
              renk: AppColors.purple,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Text(
        'Ortalama porsiyon: ${_sonuc.gramaj.toStringAsFixed(0)} g · '
        'Analiz güveni %${_sonuc.guven}',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
      ),
      const SizedBox(height: 16),
      Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _analiziBaslat,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.purple,
                side: BorderSide(
                  color: AppColors.purple.withValues(alpha: 0.5),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Tekrar Analiz'),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 2,
            child: FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(_sonuc.ogun),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: const Color(0xFF00210E),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.add_rounded, size: 19),
              label: const Text('Listeye Ekle'),
            ),
          ),
        ],
      ),
    ];
  }
}

// -----------------------------------------------------------------------------
// Widget'lar
// -----------------------------------------------------------------------------

class _MakroBar extends StatelessWidget {
  const _MakroBar({
    required this.etiket,
    required this.deger,
    required this.hedef,
    required this.birim,
    required this.renk,
    required this.icon,
    this.oran,
  });

  final String etiket;
  final double deger;
  final double hedef;
  final String birim;
  final Color renk;
  final IconData icon;
  final double? oran;

  @override
  Widget build(BuildContext context) {
    final double ilerleme =
        oran ?? (hedef <= 0 ? 0 : (deger / hedef).clamp(0.0, 1.0).toDouble());
    final String degerMetni = birim == 'kcal'
        ? deger.toStringAsFixed(0)
        : deger.toStringAsFixed(0);
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: renk, size: 13),
            const SizedBox(width: 6),
            Text(
              etiket,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              '$degerMetni / ${hedef.toStringAsFixed(0)} $birim',
              style: TextStyle(
                color: renk,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0, end: ilerleme),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (BuildContext context, double value, Widget? child) {
              return LinearProgressIndicator(
                value: value,
                minHeight: 7,
                backgroundColor: AppColors.surfaceHigh,
                color: renk,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ModButonu extends StatelessWidget {
  const _ModButonu({
    required this.etiket,
    required this.icon,
    required this.secili,
    required this.onTap,
  });

  final String etiket;
  final IconData icon;
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
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
          decoration: BoxDecoration(
            color: secili ? AppColors.surface : Colors.transparent,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(
              color: secili
                  ? AppColors.green.withValues(alpha: 0.5)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: secili ? AppColors.green : AppColors.textSecondary,
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  etiket,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secili ? AppColors.green : AppColors.textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
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

class _SayiAlani extends StatelessWidget {
  const _SayiAlani({
    required this.controller,
    required this.etiket,
    required this.icon,
    required this.ondalik,
    required this.validator,
  });

  final TextEditingController controller;
  final String etiket;
  final IconData icon;
  final bool ondalik;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: ondalik),
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(
          ondalik ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: etiket,
        prefixIcon: Icon(icon, size: 17),
        prefixIconConstraints: const BoxConstraints(minWidth: 34),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
      ),
      validator: validator,
    );
  }
}

class _MakroIpucu extends StatelessWidget {
  const _MakroIpucu({
    required this.protein,
    required this.karbonhidrat,
    required this.yag,
  });

  final double protein;
  final double karbonhidrat;
  final double yag;

  @override
  Widget build(BuildContext context) {
    final int hesaplanan = (protein * 4 + karbonhidrat * 4 + yag * 9).round();
    if (hesaplanan <= 0) {
      return Text(
        'İpucu: Makroları girdiğinde enerji değerini otomatik kontrol ederim.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
      );
    }
    return Row(
      children: [
        const Icon(Icons.insights_rounded, color: AppColors.amber, size: 13),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Makrolardan hesaplanan enerji: ~$hesaplanan kcal '
            '(1 g protein/karbo = 4, 1 g yağ = 9 kcal)',
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(fontSize: 10),
          ),
        ),
      ],
    );
  }
}

class _HizliBesinCipi extends StatelessWidget {
  const _HizliBesinCipi({required this.besin, required this.onTap});

  final Ogun besin;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.add_rounded,
                  color: AppColors.green,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    besin.isim,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '${besin.kalori} kcal · ${besin.protein.toStringAsFixed(0)} g P',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
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
}

class _OgunSatiri extends StatelessWidget {
  const _OgunSatiri({required this.ogun, required this.onSil});

  final Ogun ogun;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    final bool ai = ogun.kaynak == 'AI Analiz';
    final bool hizli = ogun.kaynak == 'Hızlı Liste';
    final Color renk = ai
        ? AppColors.purple
        : hizli
        ? AppColors.amber
        : AppColors.blue;
    final IconData icon = ai
        ? Icons.auto_awesome_rounded
        : hizli
        ? Icons.bolt_rounded
        : Icons.edit_note_rounded;

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
            child: Icon(icon, color: renk, size: 19),
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
                        ogun.isim,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: renk.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        ogun.kaynak,
                        style: TextStyle(
                          color: renk,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${ogun.gramaj > 0 ? '${ogun.gramaj.toStringAsFixed(0)} g · ' : ''}'
                  'P ${ogun.protein.toStringAsFixed(1)} g'
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
          const SizedBox(width: 8),
          Text(
            '${ogun.kalori}',
            style: TextStyle(
              color: renk,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Text(
            ' kcal',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 9,
              fontWeight: FontWeight.w600,
            ),
          ),
          IconButton(
            onPressed: onSil,
            tooltip: 'Yemeği sil',
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

class _SonucKutusu extends StatelessWidget {
  const _SonucKutusu({
    required this.baslik,
    required this.deger,
    required this.birim,
    required this.renk,
  });

  final String baslik;
  final String deger;
  final String birim;
  final Color renk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
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
                    ),
                  ),
                  TextSpan(
                    text: ' $birim',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 8,
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
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 9),
          ),
        ],
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
