import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/fitness_models.dart';
import '../theme/app_theme.dart';

/// Ağırlık antrenmanı hareketlerini ve kardiyo kayıtlarını yöneten ekran.
class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({
    super.key,
    required this.antrenmanlar,
    required this.onAntrenmanEkle,
    required this.onAntrenmanSil,
    required this.onKardiyoKaydet,
  });

  final List<Antrenman> antrenmanlar;
  final ValueChanged<Antrenman> onAntrenmanEkle;
  final ValueChanged<Antrenman> onAntrenmanSil;
  final void Function(String tur, int dakika) onKardiyoKaydet;

  @override
  State<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _hareketController = TextEditingController();
  final TextEditingController _setController = TextEditingController(text: '3');
  final TextEditingController _tekrarController = TextEditingController(
    text: '10',
  );
  final TextEditingController _agirlikController = TextEditingController(
    text: '20',
  );
  final TextEditingController _sureController = TextEditingController(
    text: '30',
  );

  String _kardiyoTuru = 'İncline Yürüyüş';

  @override
  void dispose() {
    _hareketController.dispose();
    _setController.dispose();
    _tekrarController.dispose();
    _agirlikController.dispose();
    _sureController.dispose();
    super.dispose();
  }

  List<Antrenman> get _agirlikHareketleri =>
      widget.antrenmanlar.where((a) => !a.kardiyoMu).toList();

  List<Antrenman> get _kardiyoKayitlari =>
      widget.antrenmanlar.where((a) => a.kardiyoMu).toList();

  double get _toplamHacim => _agirlikHareketleri.fold<double>(
    0,
    (toplam, a) => toplam + a.toplamHacim,
  );

  int get _toplamSet =>
      _agirlikHareketleri.fold<int>(0, (toplam, a) => toplam + a.set);

  int get _toplamKardiyoDakika =>
      _kardiyoKayitlari.fold<int>(0, (toplam, a) => toplam + a.kardiyoSuresi);

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
            _buildIstatistikler(),
            const SizedBox(height: 24),
            _buildHareketEklemeKarti(context),
            const SizedBox(height: 26),
            _BolumBasligi(
              icon: Icons.fitness_center_rounded,
              renk: AppColors.green,
              baslik: 'Ağırlık Hareketleri',
              altBaslik:
                  '${_agirlikHareketleri.length} hareket · $_toplamSet set',
            ),
            const SizedBox(height: 12),
            _buildHareketListesi(context),
            const SizedBox(height: 28),
            _buildKardiyoKarti(context),
            const SizedBox(height: 26),
            _BolumBasligi(
              icon: Icons.directions_run_rounded,
              renk: AppColors.blue,
              baslik: 'Kardiyo Kayıtları',
              altBaslik: 'Bu hafta toplam $_toplamKardiyoDakika dk',
            ),
            const SizedBox(height: 12),
            _buildKardiyoListesi(context),
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
          'ANTRENMAN',
          style: text.labelLarge?.copyWith(
            color: AppColors.blue,
            letterSpacing: 2.4,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 4),
        Text('Bugünkü Performans', style: text.headlineMedium),
        const SizedBox(height: 4),
        Text(
          'Hareketlerini ekle, kaldırdığın hacmi ve kardiyonu takip et.',
          style: text.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildIstatistikler() {
    return Row(
      children: [
        Expanded(
          child: _IstatistikKarti(
            baslik: 'Hareket',
            deger: '${_agirlikHareketleri.length}',
            birim: 'adet',
            icon: Icons.format_list_numbered_rounded,
            renk: AppColors.green,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _IstatistikKarti(
            baslik: 'Toplam Hacim',
            deger: _binlik(_toplamHacim),
            birim: 'kg',
            icon: Icons.monitor_weight_outlined,
            renk: AppColors.amber,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _IstatistikKarti(
            baslik: 'Kardiyo',
            deger: '$_toplamKardiyoDakika',
            birim: 'dk',
            icon: Icons.timer_outlined,
            renk: AppColors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildHareketEklemeKarti(BuildContext context) {
    return Container(
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
                  'Hareket Ekle',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _hareketController,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Hareket adı',
                hintText: 'Örn. Bench Press',
                prefixIcon: Icon(Icons.sports_gymnastics_rounded),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Hareket adı gerekli';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final String hareket in hazirHareketler)
                  _HizliHareketCipi(
                    etiket: hareket,
                    secili: _hareketController.text.trim() == hareket,
                    onTap: () {
                      setState(() {
                        _hareketController.text = hareket;
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SayiAlani(
                    controller: _setController,
                    etiket: 'Set',
                    icon: Icons.repeat_rounded,
                    izinVerilenOndalik: false,
                    validator: (value) => _sayiDogrula(value, 'Set', 1, 20),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SayiAlani(
                    controller: _tekrarController,
                    etiket: 'Tekrar',
                    icon: Icons.loop_rounded,
                    izinVerilenOndalik: false,
                    validator: (value) => _sayiDogrula(value, 'Tekrar', 1, 100),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SayiAlani(
                    controller: _agirlikController,
                    etiket: 'Kg',
                    icon: Icons.fitness_center_rounded,
                    izinVerilenOndalik: true,
                    validator: (value) =>
                        _sayiDogrula(value, 'Ağırlık', 0, 500),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _hareketEkle,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: const Color(0xFF00210E),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Hareketi Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHareketListesi(BuildContext context) {
    if (_agirlikHareketleri.isEmpty) {
      return const _BosDurum(
        icon: Icons.sports_gymnastics_rounded,
        baslik: 'Henüz hareket eklenmedi',
        aciklama: 'İlk hareketini yukarıdaki formdan ekleyerek başla.',
      );
    }

    return Column(
      children: [
        for (final Antrenman antrenman in _agirlikHareketleri) ...[
          _HareketSatiri(
            antrenman: antrenman,
            onSil: () => widget.onAntrenmanSil(antrenman),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  Widget _buildKardiyoKarti(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B2330), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: AppColors.blue,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Antrenman Sonu Kardiyo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Eğimli yürüyüş veya açık hava koşusunu dakika olarak kaydet.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _KardiyoSecenegi(
                  etiket: 'İncline Yürüyüş',
                  icon: Icons.terrain_rounded,
                  secili: _kardiyoTuru == 'İncline Yürüyüş',
                  renk: AppColors.green,
                  onTap: () => setState(() => _kardiyoTuru = 'İncline Yürüyüş'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KardiyoSecenegi(
                  etiket: 'Açık Hava Koşusu',
                  icon: Icons.directions_run_rounded,
                  secili: _kardiyoTuru == 'Açık Hava Koşusu',
                  renk: AppColors.blue,
                  onTap: () =>
                      setState(() => _kardiyoTuru = 'Açık Hava Koşusu'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _SayiAlani(
                  controller: _sureController,
                  etiket: 'Süre (dk)',
                  icon: Icons.timer_outlined,
                  izinVerilenOndalik: false,
                  validator: (value) => _sayiDogrula(value, 'Süre', 1, 300),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed: _kardiyoKaydet,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Kaydet'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildKardiyoListesi(BuildContext context) {
    if (_kardiyoKayitlari.isEmpty) {
      return const _BosDurum(
        icon: Icons.timer_off_outlined,
        baslik: 'Kardiyo kaydı yok',
        aciklama: 'Antrenman sonrası süreni ekleyerek takibe başla.',
      );
    }

    return Column(
      children: [
        for (final Antrenman kayit in _kardiyoKayitlari) ...[
          _KardiyoSatiri(
            antrenman: kayit,
            onSil: () => widget.onAntrenmanSil(kayit),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  void _hareketEkle() {
    FocusScope.of(context).unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final int set = int.parse(_setController.text.trim());
    final int tekrar = int.parse(_tekrarController.text.trim());
    final double agirlik = _ondalikOku(_agirlikController.text);

    widget.onAntrenmanEkle(
      Antrenman(
        hareketAdi: _hareketController.text.trim(),
        set: set,
        tekrar: tekrar,
        agirlik: agirlik,
      ),
    );

    _hareketController.clear();
    setState(() {});

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Hareket antrenmana eklendi.')),
      );
  }

  void _kardiyoKaydet() {
    FocusScope.of(context).unfocus();
    final String? hata = _sayiDogrula(_sureController.text, 'Süre', 1, 300);
    if (hata != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(hata)));
      return;
    }

    final int dakika = int.parse(_sureController.text.trim());
    widget.onKardiyoKaydet(_kardiyoTuru, dakika);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text('$_kardiyoTuru · $dakika dk kaydedildi.')),
      );
  }

  String? _sayiDogrula(String? value, String alan, num min, num max) {
    if (value == null || value.trim().isEmpty) {
      return '$alan gerekli';
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

  double _ondalikOku(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.')) ?? 0;
  }

  String _binlik(double deger) {
    final String tam = deger.toStringAsFixed(0);
    return tam.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
  }
}

class _SayiAlani extends StatelessWidget {
  const _SayiAlani({
    required this.controller,
    required this.etiket,
    required this.icon,
    required this.izinVerilenOndalik,
    required this.validator,
  });

  final TextEditingController controller;
  final String etiket;
  final IconData icon;
  final bool izinVerilenOndalik;
  final FormFieldValidator<String> validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(
        decimal: izinVerilenOndalik,
      ),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          izinVerilenOndalik ? RegExp(r'[0-9.,]') : RegExp(r'[0-9]'),
        ),
      ],
      decoration: InputDecoration(
        labelText: etiket,
        prefixIcon: Icon(icon, size: 18),
        prefixIconConstraints: const BoxConstraints(minWidth: 38),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 16,
        ),
      ),
      validator: validator,
    );
  }
}

class _IstatistikKarti extends StatelessWidget {
  const _IstatistikKarti({
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

class _HizliHareketCipi extends StatelessWidget {
  const _HizliHareketCipi({
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
      color: secili
          ? AppColors.green.withValues(alpha: 0.16)
          : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: secili
                  ? AppColors.green.withValues(alpha: 0.6)
                  : AppColors.border,
            ),
          ),
          child: Text(
            etiket,
            style: TextStyle(
              color: secili ? AppColors.green : AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _KardiyoSecenegi extends StatelessWidget {
  const _KardiyoSecenegi({
    required this.etiket,
    required this.icon,
    required this.secili,
    required this.renk,
    required this.onTap,
  });

  final String etiket;
  final IconData icon;
  final bool secili;
  final Color renk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: secili
                ? renk.withValues(alpha: 0.16)
                : AppColors.surfaceHigh,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: secili ? renk.withValues(alpha: 0.7) : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: secili ? renk : AppColors.textSecondary,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  etiket,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: secili ? renk : AppColors.textSecondary,
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

class _HareketSatiri extends StatelessWidget {
  const _HareketSatiri({required this.antrenman, required this.onSil});

  final Antrenman antrenman;
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
              Icons.fitness_center_rounded,
              color: AppColors.green,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  antrenman.hareketAdi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${antrenman.set} set × ${antrenman.tekrar} tekrar'
                  '  ·  ${_formatKg(antrenman.agirlik)} kg'
                  '  ·  ${_formatKg(antrenman.toplamHacim)} kg hacim',
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
            tooltip: 'Hareketi sil',
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

  String _formatKg(double deger) {
    if (deger == deger.roundToDouble()) {
      return deger.toStringAsFixed(0);
    }
    return deger.toStringAsFixed(1);
  }
}

class _KardiyoSatiri extends StatelessWidget {
  const _KardiyoSatiri({required this.antrenman, required this.onSil});

  final Antrenman antrenman;
  final VoidCallback onSil;

  @override
  Widget build(BuildContext context) {
    final bool yuruyus = antrenman.kardiyoTuru != 'Açık Hava Koşusu';
    final Color renk = yuruyus ? AppColors.green : AppColors.blue;

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
            child: Icon(
              yuruyus ? Icons.terrain_rounded : Icons.directions_run_rounded,
              color: renk,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  antrenman.hareketAdi,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 3),
                Text(
                  '${antrenman.kardiyoSuresi} dakika'
                  '${antrenman.tarih == null ? '' : '  ·  ${_saat(antrenman.tarih!)}'}',
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
              '${antrenman.kardiyoSuresi} dk',
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
