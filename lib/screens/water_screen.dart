import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../state/app_state.dart';
import '../theme/app_theme.dart';

/// Günlük su tüketimini takip eden, animasyonlu dalga göstergeli ekran.
///
/// Tüm veriler merkezi [AppState] üzerinde tutulur. Bu ekranda yapılan her
/// değişiklik ana ekrandaki su kartına anında yansır.
class WaterScreen extends StatefulWidget {
  const WaterScreen({super.key, required this.state});

  final AppState state;

  @override
  State<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends State<WaterScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _dalga;

  AppState get _state => widget.state;

  @override
  void initState() {
    super.initState();
    _dalga = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4200),
    )..repeat();
  }

  @override
  void dispose() {
    _dalga.dispose();
    super.dispose();
  }

  void _ekle(int ml) {
    setState(() {
      _state.suEkle(ml);
    });
    _bilgi('+$ml ml su eklendi');
  }

  void _azalt(int ml) {
    if (_state.suMl <= 0) {
      return;
    }
    setState(() {
      _state.suAzalt(ml);
    });
    _bilgi('$ml ml geri alındı');
  }

  void _sifirla() {
    if (_state.suMl <= 0) {
      return;
    }
    setState(_state.suSifirla);
    _bilgi('Günlük su kaydı sıfırlandı');
  }

  void _bilgi(String mesaj) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(mesaj), duration: const Duration(seconds: 2)),
      );
  }

  Future<void> _hedefDuzenle() async {
    final TextEditingController controller = TextEditingController(
      text: '${_state.suHedefMl}',
    );

    final int? sonuc = await showDialog<int>(
      context: context,
      builder: (BuildContext dialogContext) {
        String? hata;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: AppColors.border),
              ),
              title: const Row(
                children: [
                  Icon(
                    Icons.water_drop_rounded,
                    color: AppColors.blue,
                    size: 22,
                  ),
                  SizedBox(width: 8),
                  Text('Günlük Su Hedefi'),
                ],
              ),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: 'Hedef (ml)',
                  helperText: '500 - 8000 ml arasında bir değer gir.',
                  errorText: hata,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('İptal'),
                ),
                FilledButton(
                  onPressed: () {
                    final int? deger = int.tryParse(controller.text.trim());
                    if (deger == null || deger < 500 || deger > 8000) {
                      setDialogState(() {
                        hata = '500 - 8000 ml arasında olmalı';
                      });
                      return;
                    }
                    Navigator.of(dialogContext).pop(deger);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: const Color(0xFF00210E),
                  ),
                  child: const Text('Kaydet'),
                ),
              ],
            );
          },
        );
      },
    );

    controller.dispose();

    if (sonuc != null) {
      setState(() {
        _state.suHedefGuncelle(sonuc);
      });
      _bilgi('Yeni hedef: ${_litre(sonuc)} L');
    }
  }

  @override
  Widget build(BuildContext context) {
    final int suMl = _state.suMl;
    final int hedefMl = _state.suHedefMl;
    final double oran = _state.suOrani;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
          children: [
            _buildHeader(context),
            const SizedBox(height: 16),
            _buildAnaKart(context, suMl, hedefMl, oran),
            const SizedBox(height: 14),
            _buildIstatistikler(suMl, hedefMl),
            const SizedBox(height: 14),
            _buildHedefKarti(context, hedefMl),
            const SizedBox(height: 14),
            _buildIpucuKarti(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(13),
            side: const BorderSide(color: AppColors.border),
          ),
          child: InkWell(
            onTap: () => Navigator.of(context).pop(),
            borderRadius: BorderRadius.circular(13),
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Icon(
                Icons.arrow_back_rounded,
                color: AppColors.textPrimary,
                size: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'SU TAKİBİ',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.blue,
                  letterSpacing: 2.4,
                  fontSize: 10,
                ),
              ),
              Text(
                'Günlük Su Hedefin',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: _hedefDuzenle,
          tooltip: 'Su hedefini düzenle',
          icon: const Icon(Icons.tune_rounded, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildAnaKart(
    BuildContext context,
    int suMl,
    int hedefMl,
    double oran,
  ) {
    final TextTheme text = Theme.of(context).textTheme;
    final bool tamamlandi = suMl >= hedefMl;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[Color(0xFF10222C), Color(0xFF121B17)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.blue.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
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
                      tamamlandi ? 'Hedef tamamlandı!' : 'Bugünkü ilerleme',
                      style: text.titleMedium,
                    ),
                    Text(
                      tamamlandi
                          ? 'Harika iş, su hedefini doldurdun.'
                          : '${_litre(_state.kalanSuMl)} L kaldı',
                      style: text.bodyMedium?.copyWith(fontSize: 11),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (tamamlandi ? AppColors.green : AppColors.blue)
                      .withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '%${(oran * 100).round()}',
                  style: TextStyle(
                    color: tamamlandi ? AppColors.green : AppColors.blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: 244,
            height: 244,
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedBuilder(
                  animation: _dalga,
                  builder: (BuildContext context, Widget? child) {
                    return CustomPaint(
                      size: const Size.square(244),
                      painter: _SuDalgaPainter(oran: oran, dalga: _dalga.value),
                    );
                  },
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.water_drop_rounded,
                      color: Colors.white.withValues(alpha: 0.9),
                      size: 24,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '${_litre(suMl)} L',
                        style: text.displaySmall?.copyWith(
                          fontSize: 34,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Text(
                      '/ ${_litre(hedefMl)} L hedef',
                      style: text.bodyMedium?.copyWith(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _ekle(250),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.green,
                foregroundColor: const Color(0xFF00210E),
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.local_drink_rounded, size: 20),
              label: const Text(
                '1 Bardak Ekle  ·  250 ml',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _HizliMiktarButonu(
                  etiket: '+500 ml',
                  onTap: () => _ekle(500),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HizliMiktarButonu(
                  etiket: '+750 ml',
                  onTap: () => _ekle(750),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HizliMiktarButonu(
                  etiket: '−250 ml',
                  onTap: () => _azalt(250),
                  pasif: suMl == 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: suMl == 0 ? null : _sifirla,
              icon: const Icon(Icons.restart_alt_rounded, size: 16),
              label: const Text('Günlük kaydı sıfırla'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.textSecondary,
                textStyle: const TextStyle(fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIstatistikler(int suMl, int hedefMl) {
    return Row(
      children: [
        Expanded(
          child: _SuIstatistigi(
            baslik: 'İçilen',
            deger: '${_litre(suMl)} L',
            icon: Icons.local_drink_rounded,
            renk: AppColors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SuIstatistigi(
            baslik: 'Kalan',
            deger: '${_litre(_state.kalanSuMl)} L',
            icon: Icons.hourglass_bottom_rounded,
            renk: AppColors.amber,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _SuIstatistigi(
            baslik: 'Bardak',
            deger: (suMl / 250).toStringAsFixed(1),
            icon: Icons.coffee_rounded,
            renk: AppColors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildHedefKarti(BuildContext context, int hedefMl) {
    final int onerilen = (_state.kilo * 35).round();
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
              Icons.flag_rounded,
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
                  'Günlük Hedef',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  '${_litre(hedefMl)} L · Kilon için önerilen '
                  '${_litre(onerilen)} L',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: _hedefDuzenle,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.green,
              side: BorderSide(color: AppColors.green.withValues(alpha: 0.5)),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Değiştir'),
          ),
        ],
      ),
    );
  }

  Widget _buildIpucuKarti(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.blue.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.blue.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline_rounded,
            color: AppColors.blue,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Su hedefin kilona göre yaklaşık 35 ml/kg olarak önerilir. '
              'Antrenman günlerinde her 30 dakikalık egzersiz için ekstra '
              '300-500 ml su eklemeyi unutma.',
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(fontSize: 11, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  String _litre(int ml) => (ml / 1000).toStringAsFixed(2);
}

class _HizliMiktarButonu extends StatelessWidget {
  const _HizliMiktarButonu({
    required this.etiket,
    required this.onTap,
    this.pasif = false,
  });

  final String etiket;
  final VoidCallback onTap;
  final bool pasif;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: pasif ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 42,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            etiket,
            style: TextStyle(
              color: pasif ? AppColors.textSecondary : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}

class _SuIstatistigi extends StatelessWidget {
  const _SuIstatistigi({
    required this.baslik,
    required this.deger,
    required this.icon,
    required this.renk,
  });

  final String baslik;
  final String deger;
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
          Icon(icon, color: renk, size: 17),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              deger,
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

/// Dairesel su haznesini çizen ve animasyonlu dalgalar ekleyen painter.
class _SuDalgaPainter extends CustomPainter {
  const _SuDalgaPainter({required this.oran, required this.dalga});

  final double oran;
  final double dalga;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Offset.zero & size;
    final Path daire = Path()..addOval(rect);

    canvas.save();
    canvas.clipPath(daire);

    // Hazne arka planı
    final Paint arkaPlan = Paint()
      ..shader = const LinearGradient(
        colors: <Color>[Color(0xFF1B2A33), Color(0xFF111820)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(rect);
    canvas.drawRect(rect, arkaPlan);

    if (oran > 0) {
      final double suY = size.height * (1 - oran);

      final Paint dolgu = Paint()
        ..shader = LinearGradient(
          colors: <Color>[
            AppColors.blue.withValues(alpha: 0.85),
            AppColors.green.withValues(alpha: 0.85),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ).createShader(rect);
      canvas.drawRect(Rect.fromLTRB(0, suY, size.width, size.height), dolgu);

      _dalgaCiz(
        canvas,
        size,
        suY,
        phase: dalga * math.pi * 2,
        amplitude: 6,
        renk: Colors.white.withValues(alpha: 0.16),
      );
      _dalgaCiz(
        canvas,
        size,
        suY + 4,
        phase: dalga * math.pi * 2 + math.pi,
        amplitude: 4,
        renk: AppColors.green.withValues(alpha: 0.22),
      );
    }

    canvas.restore();

    // Dış halkalar
    canvas.drawCircle(
      rect.center,
      rect.width / 2 - 1,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = AppColors.border,
    );
    canvas.drawCircle(
      rect.center,
      rect.width / 2 - 7,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..color = AppColors.blue.withValues(alpha: 0.10),
    );
  }

  void _dalgaCiz(
    Canvas canvas,
    Size size,
    double suY, {
    required double phase,
    required double amplitude,
    required Color renk,
  }) {
    final Path dalga = Path()..moveTo(0, suY);
    for (double x = 0; x <= size.width; x += 3) {
      final double y =
          suY + math.sin((x / size.width) * math.pi * 2 + phase) * amplitude;
      dalga.lineTo(x, y);
    }
    dalga
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(dalga, Paint()..color = renk);
  }

  @override
  bool shouldRepaint(covariant _SuDalgaPainter oldDelegate) {
    return oldDelegate.oran != oran || oldDelegate.dalga != dalga;
  }
}
