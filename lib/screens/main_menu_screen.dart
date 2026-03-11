import 'package:flutter/material.dart';
import '../services/save_manager.dart';
import 'character_creation_screen.dart';
import 'game_screen.dart';
import 'drama_manager.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  SaveMeta? _meta;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMeta();
  }

  Future<void> _loadMeta() async {
    final meta = await GameSaveManager.getMetadata();
    if (mounted) setState(() { _meta = meta; _loading = false; });
  }

  Future<void> _continue() async {
    final data = await GameSaveManager.load();
    if (!mounted) return;
    if (data == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saxlama faylı zədələnib. Yeni oyun başladılır.')),
      );
      Navigator.pushReplacement(
        context, MaterialPageRoute(builder: (_) => const CharacterCreationScreen()));
      return;
    }
    // Restore DramaManager singleton state
    DramaManager().restoreTriggered(data.dramaTriggered);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GameScreen(
          player: data.player,
          initialLogs: data.logs,
          initialEarlyDecisionCount: data.earlyDecisionCountTotal,
        ),
      ),
    );
  }

  Future<void> _newGame() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Yeni oyun', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Köhnə oyun silinəcək. Davam edirsən?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Xeyr')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Bəli, Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await GameSaveManager.delete();
    if (!mounted) return;
    Navigator.pushReplacement(
      context, MaterialPageRoute(builder: (_) => const CharacterCreationScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1565C0),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    const Text(
                      'AzLife',
                      style: TextStyle(
                        fontSize: 52, fontWeight: FontWeight.w900,
                        color: Colors.white, letterSpacing: 3,
                      ),
                    ),
                    const Text(
                      'Azərbaycan Həyat Simulyatoru',
                      style: TextStyle(fontSize: 14, color: Colors.white70, letterSpacing: 1),
                    ),
                    const Spacer(),
                    if (_meta != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white24),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_meta!.name} ${_meta!.surname}',
                              style: const TextStyle(
                                  fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_meta!.age} yaş · ${_meta!.city}',
                              style: const TextStyle(fontSize: 14, color: Colors.white70),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatSavedAt(_meta!.savedAt),
                              style: const TextStyle(fontSize: 12, color: Colors.white54),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _continue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2EC95C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('DAVAM ET',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: _newGame,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white38),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: const Text('YENİ OYUN',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: 1)),
                        ),
                      ),
                    ],
                    const Spacer(),
                  ],
                ),
              ),
      ),
    );
  }

  String _formatSavedAt(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'Az əvvəl saxlanıldı';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dəq. əvvəl saxlanıldı';
    if (diff.inHours < 24) return '${diff.inHours} saat əvvəl saxlanıldı';
    return '${diff.inDays} gün əvvəl saxlanıldı';
  }
}
