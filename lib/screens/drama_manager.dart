import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/player.dart';

// ─────────────────────────────────────────────
// DATA MODELS
// ─────────────────────────────────────────────

class DramaEffect {
  final int happiness;
  final int relationshipParents;
  final int relationshipGirlfriend;
  final int money;
  final int smarts;
  final int looks;
  final int reputation;
  final int health;

  const DramaEffect({
    this.happiness = 0,
    this.relationshipParents = 0,
    this.relationshipGirlfriend = 0,
    this.money = 0,
    this.smarts = 0,
    this.looks = 0,
    this.reputation = 0,
    this.health = 0,
  });

  factory DramaEffect.fromJson(Map<String, dynamic> json) => DramaEffect(
        happiness: json['happiness'] ?? 0,
        relationshipParents: json['relationship_parents'] ?? 0,
        relationshipGirlfriend: json['relationship_girlfriend'] ?? 0,
        money: json['money'] ?? 0,
        smarts: json['smarts'] ?? 0,
        looks: json['looks'] ?? 0,
        reputation: json['reputation'] ?? 0,
        health: json['health'] ?? 0,
      );
}

class DramaChoice {
  final String label;
  final String description;
  final DramaEffect effects;
  final String outcome;

  const DramaChoice({
    required this.label,
    required this.description,
    required this.effects,
    required this.outcome,
  });

  factory DramaChoice.fromJson(Map<String, dynamic> json) => DramaChoice(
        label: json['label'] ?? "",
        description: json['description'] ?? "",
        effects: DramaEffect.fromJson(json['effects'] ?? {}),
        outcome: json['outcome'] ?? "",
      );
}

class DramaRequirements {
  final int minAge;
  final int maxAge;
  final bool noGirlfriend; 
  final String? trigger;   

  const DramaRequirements({
    this.minAge = 0,
    this.maxAge = 99,
    this.noGirlfriend = false,
    this.trigger,
  });

  factory DramaRequirements.fromJson(Map<String, dynamic> json) =>
      DramaRequirements(
        minAge: json['minAge'] ?? 0,
        maxAge: json['maxAge'] ?? 99,
        noGirlfriend: json['noGirlfriend'] ?? false,
        trigger: json['trigger'],
      );
}

class DramaEvent {
  final String id;
  final String title;
  final String description;
  final String npcName;
  final String npcEmoji;
  final DramaRequirements requirements;
  final List<DramaChoice> choices;
  final String dramaType;   
  final String dramaLabel;  
  final String dramaEmoji;
  final String dramaColor;

  const DramaEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.npcName,
    required this.npcEmoji,
    required this.requirements,
    required this.choices,
    required this.dramaType,
    required this.dramaLabel,
    required this.dramaEmoji,
    required this.dramaColor,
  });

  factory DramaEvent.fromJson(
    Map<String, dynamic> json, {
    required String type,
    required String label,
    required String emoji,
    required String color,
  }) =>
      DramaEvent(
        id: json['id'] ?? "unknown",
        title: json['title'] ?? "Hadisə",
        description: json['description'] ?? "",
        npcName: json['npcName'] ?? "Naməlum",
        npcEmoji: json['npcEmoji'] ?? "👤",
        requirements: DramaRequirements.fromJson(json['requirements'] ?? {}),
        choices: (json['choices'] as List? ?? [])
            .map((c) => DramaChoice.fromJson(c as Map<String, dynamic>))
            .toList(),
        dramaType: type,
        dramaLabel: label,
        dramaEmoji: emoji,
        dramaColor: color,
      );
}

// ─────────────────────────────────────────────
// DRAMA MANAGER SERVICE
// ─────────────────────────────────────────────

class DramaManager {
  static const double _triggerChance = 0.15; 

  final _random = Random();
  List<DramaEvent> _allEvents = [];
  final Set<String> _triggeredThisLife = {};  

  bool _isLoaded = false;

  static final DramaManager _instance = DramaManager._internal();
  factory DramaManager() => _instance;
  DramaManager._internal();

  Future<void> load() async {
    if (_isLoaded) return;

    try {
      final raw = await rootBundle.loadString('assets/json/drama_events.json');
      final jsonData = jsonDecode(raw) as Map<String, dynamic>;
      final types = jsonData['dramaTypes'] as Map<String, dynamic>;

      _allEvents = [];

      for (final entry in types.entries) {
        final typeKey = entry.key;
        final typeData = entry.value as Map<String, dynamic>;
        final label = typeData['label'] as String;
        final emoji = typeData['emoji'] as String;
        final color = typeData['color'] as String;
        final events = typeData['events'] as List;

        for (final e in events) {
          _allEvents.add(DramaEvent.fromJson(
            e as Map<String, dynamic>,
            type: typeKey,
            label: label,
            emoji: emoji,
            color: color,
          ));
        }
      }
      _isLoaded = true;
    } catch (e) {
      // ignore: avoid_print
      print("DramaManager load error: $e");
    }
  }

  void resetLife() {
    _triggeredThisLife.clear();
  }

  Set<String> get triggeredThisLife => Set.unmodifiable(_triggeredThisLife);

  void restoreTriggered(Set<String> ids) {
    _triggeredThisLife
      ..clear()
      ..addAll(ids);
  }

  DramaEvent? rollDrama({
    required int playerAge,
    bool hasGirlfriend = false,
    String currentTrigger = 'random',
  }) {
    if (!_isLoaded) return null;

    if (_random.nextDouble() > _triggerChance) return null;

    final eligible = _allEvents.where((e) {
      if (playerAge < e.requirements.minAge) return false;
      if (playerAge > e.requirements.maxAge) return false;
      if (e.requirements.noGirlfriend && hasGirlfriend) return false;
      if (e.requirements.trigger != null &&
          e.requirements.trigger != 'random' &&
          e.requirements.trigger != currentTrigger) { return false; }
      if (_triggeredThisLife.contains(e.id)) return false;

      return true;
    }).toList();

    if (eligible.isEmpty) return null;

    final chosen = eligible[_random.nextInt(eligible.length)];
    _triggeredThisLife.add(chosen.id);
    return chosen;
  }

  void applyChoice({
    required DramaChoice choice,
    required Player player,
  }) {
    final e = choice.effects;
    player.happiness = (player.happiness + e.happiness).clamp(0, 100);
    player.smarts = (player.smarts + e.smarts).clamp(0, 100);
    player.looks = (player.looks + e.looks).clamp(0, 100);
    player.money += e.money;
    player.health = (player.health + e.health).clamp(0, 100);

    for (var member in player.family) {
      if (member.relation == "Ata" || member.relation == "Ana") {
        member.relationship = (member.relationship + e.relationshipParents).clamp(0, 100);
      }
    }
  }
}
