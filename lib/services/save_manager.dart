import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/player.dart';
import '../screens/game_screen.dart';

class SaveData {
  final Player player;
  final List<YearLog> logs;
  final int earlyDecisionCountTotal;
  final Set<String> dramaTriggered;

  const SaveData({
    required this.player,
    required this.logs,
    required this.earlyDecisionCountTotal,
    required this.dramaTriggered,
  });
}

class SaveMeta {
  final String name;
  final String surname;
  final String city;
  final int age;
  final DateTime savedAt;

  const SaveMeta({
    required this.name,
    required this.surname,
    required this.city,
    required this.age,
    required this.savedAt,
  });
}

class GameSaveManager {
  static const _saveKey = 'azlife_save_v1';
  static const _metaKey = 'azlife_save_meta';
  static const _currentVersion = 1;

  // ── Public API ────────────────────────────────

  static Future<void> save(SaveData data) async {
    final prefs = await SharedPreferences.getInstance();

    final payload = json.encode({
      'save_version': _currentVersion,
      'player': data.player.toJson(),
      'logs': data.logs.map((l) => l.toJson()).toList(),
      'earlyDecisionCountTotal': data.earlyDecisionCountTotal,
      'dramaTriggered': data.dramaTriggered.toList(),
    });

    final meta = json.encode({
      'name': data.player.name,
      'surname': data.player.surname,
      'city': data.player.birthCity,
      'age': data.player.age,
      'savedAt': DateTime.now().toIso8601String(),
    });

    await prefs.setString(_saveKey, payload);
    await prefs.setString(_metaKey, meta);
  }

  static Future<SaveData?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_saveKey);
    if (raw == null) return null;

    try {
      final map = json.decode(raw) as Map<String, dynamic>;
      final migrated = _migrate(map);

      return SaveData(
        player: Player.fromJson(migrated['player'] as Map<String, dynamic>),
        logs: (migrated['logs'] as List? ?? [])
            .map((l) => YearLog.fromJson(l as Map<String, dynamic>))
            .toList(),
        earlyDecisionCountTotal:
            migrated['earlyDecisionCountTotal'] as int? ?? 0,
        dramaTriggered:
            Set<String>.from(migrated['dramaTriggered'] as List? ?? []),
      );
    } catch (_) {
      // Corrupted save — wipe and return null
      await delete();
      return null;
    }
  }

  static Future<bool> exists() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_saveKey);
  }

  static Future<void> delete() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_saveKey);
    await prefs.remove(_metaKey);
  }

  static Future<SaveMeta?> getMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_metaKey);
    if (raw == null) return null;
    try {
      final m = json.decode(raw) as Map<String, dynamic>;
      return SaveMeta(
        name: m['name'] as String,
        surname: m['surname'] as String,
        city: m['city'] as String,
        age: m['age'] as int,
        savedAt: DateTime.parse(m['savedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Internal ──────────────────────────────────

  /// Forward migration stub. Currently a no-op at v1.
  static Map<String, dynamic> _migrate(Map<String, dynamic> data) {
    // ignore: unused_local_variable
    final version = data['save_version'] as int? ?? 1;
    // TODO: add migration blocks here when save_version increases
    return data;
  }
}
