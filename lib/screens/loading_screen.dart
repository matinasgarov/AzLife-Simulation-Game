import 'package:flutter/material.dart';
import '../services/save_manager.dart';
import 'main_menu_screen.dart';
import 'character_creation_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  @override
  void initState() {
    super.initState();
    _checkAndRoute();
  }

  Future<void> _checkAndRoute() async {
    // Minimum splash duration + save check run in parallel
    final results = await Future.wait([
      Future.delayed(const Duration(seconds: 2)),
      GameSaveManager.exists(),
    ]);
    if (!mounted) return;
    final hasSave = results[1] as bool;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => hasSave ? const MainMenuScreen() : const CharacterCreationScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'AzLife',
              style: TextStyle(
                fontSize: 40, fontWeight: FontWeight.bold,
                color: Colors.white, letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(color: Colors.white),
            const SizedBox(height: 20),
            Text(
              'Azərbaycan həyatı simulyasiya edilir...',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.8)),
            ),
          ],
        ),
      ),
    );
  }
}
