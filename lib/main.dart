import 'package:flutter/material.dart';

import 'screens/activity_tracker_screen.dart';
import 'screens/body_3d_workout_screen.dart';
import 'screens/calculator_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/nutrition_ai_screen.dart';
import 'screens/water_screen.dart';
import 'screens/workout_screen.dart';
import 'state/app_state.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const KaloriApp());
}

/// Fitness, makro ve suplement takip uygulaması.
class KaloriApp extends StatelessWidget {
  const KaloriApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'FitTrack',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: const MainShell(),
    );
  }
}

/// Tüm ekranları tek bir [AppState] örneğine bağlayan kabuk.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final AppState _appState = AppState();

  int _seciliSayfa = 0;

  @override
  void initState() {
    super.initState();
    _appState.addListener(_durumDegisti);
  }

  @override
  void dispose() {
    _appState
      ..removeListener(_durumDegisti)
      ..dispose();
    super.dispose();
  }

  /// Merkezi state'teki her değişiklikte tüm sekmeler güncellenir.
  void _durumDegisti() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _seciliSayfa,
        children: [
          DashboardScreen(
            ogunler: _appState.ogunler,
            suplementler: _appState.suplementler,
            hedefKalori: _appState.hedefKalori,
            hedefProtein: _appState.hedefProtein,
            yakilanKalori: _appState.bugunYakilanKalori,
            suMl: _appState.suMl,
            suHedefMl: _appState.suHedefMl,
            onOgunEkle: _appState.ogunEkle,
            onOgunSil: _appState.ogunSil,
            onSuplementToggle: _appState.suplementToggle,
            onSuEkle: _appState.suEkle,
            onSuEkraniAc: _suEkraniAc,
            onHedefDuzenle: () => _sayfaDegistir(5),
          ),
          ActivityTrackerScreen(state: _appState),
          NutritionAiScreen(state: _appState),
          const Body3DWorkoutScreen(),
          WorkoutScreen(
            antrenmanlar: _appState.antrenmanlar,
            onAntrenmanEkle: _appState.antrenmanEkle,
            onAntrenmanSil: _appState.antrenmanSil,
            onKardiyoKaydet: _appState.kardiyoKaydet,
          ),
          CalculatorScreen(
            boy: _appState.boy,
            kilo: _appState.kilo,
            hedefKilo: _appState.hedefKilo,
            hedefKalori: _appState.hedefKalori,
            hedefProtein: _appState.hedefProtein,
            onKaydet: _appState.hedefKaydet,
          ),
        ],
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: BottomNavigationBar(
          currentIndex: _seciliSayfa,
          onTap: _sayfaDegistir,
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard_rounded),
              label: 'Özet',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.directions_run_outlined),
              activeIcon: Icon(Icons.directions_run_rounded),
              label: 'Aktivite',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.restaurant_menu_outlined),
              activeIcon: Icon(Icons.restaurant_menu_rounded),
              label: 'Beslenme',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.accessibility_new_outlined),
              activeIcon: Icon(Icons.accessibility_new_rounded),
              label: 'Vücut',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fitness_center_outlined),
              activeIcon: Icon(Icons.fitness_center_rounded),
              label: 'Antrenman',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calculate_outlined),
              activeIcon: Icon(Icons.calculate_rounded),
              label: 'Hesapla',
            ),
          ],
        ),
      ),
    );
  }

  void _sayfaDegistir(int index) {
    if (index == _seciliSayfa) {
      return;
    }
    setState(() {
      _seciliSayfa = index;
    });
  }

  void _suEkraniAc() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => WaterScreen(state: _appState),
      ),
    );
  }
}
