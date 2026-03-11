# Save / Load System — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Persist all AzLife game state to device storage so players never lose progress across app restarts, with a polished Main Menu that lets them continue or start fresh.

**Architecture:** `shared_preferences` stores two JSON keys — a full save blob and a lightweight metadata blob. `GameSaveManager` (a static service class) handles all read/write/migrate operations. `Player`, `FamilyMember`, `SchoolMate`, and `YearLog` each gain `toJson()`/`fromJson()` for serialization. `LoadingScreen` routes to a new `MainMenuScreen` when a save exists, or directly to `CharacterCreationScreen` when it doesn't. `GameScreen` auto-saves after `ageUp()`, on background, and via a manual save button.

**Tech Stack:** Flutter/Dart, `shared_preferences: ^2.3.2`, `dart:convert`, `flutter_test` (existing), `package:flutter/services.dart` (for `TestDefaultBinaryMessengerBinding` in tests)

**Spec:** `docs/superpowers/specs/2026-03-11-save-load-system-design.md`

---

## Chunk 1: Foundation — Dependencies + Model Serialization

### Task 1: Add shared_preferences dependency

**Files:**
- Modify: `pubspec.yaml`
- Test: run `flutter pub get`

- [ ] **Step 1: Add the dependency**

In `pubspec.yaml`, under `dependencies:`, add:
```yaml
dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  audioplayers: ^5.2.1
  shared_preferences: ^2.3.2   # ← add this line
```

- [ ] **Step 2: Fetch packages**

```bash
flutter pub get
```
Expected: resolves without errors, `pubspec.lock` updated.

- [ ] **Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "feat: add shared_preferences for save system"
```

---

### Task 2: Add toJson / fromJson to FamilyMember

**Files:**
- Modify: `lib/models/player.dart`
- Test: `test/models/family_member_serialization_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/models/family_member_serialization_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:az_life/models/player.dart';

void main() {
  group('FamilyMember serialization', () {
    test('round-trips all fields via toJson/fromJson', () {
      final original = FamilyMember(
        name: 'Əli',
        surname: 'Məmmədov',
        gender: Gender.male,
        relation: 'Ata',
        education: 'Ali təhsil',
        job: 'Həkim',
        maritalStatus: 'Evli',
        diseases: ['Diabet'],
        interactionHistory: ['Söhbət etdiniz'],
        monthlyIncome: 1500,
        totalMoney: 20000,
        generosity: 70,
        religiousness: 60,
        looks: 55,
        health: 80,
        relationship: 90,
        isAlive: true,
        age: 45,
      );

      final json = original.toJson();
      final restored = FamilyMember.fromJson(json);

      expect(restored.name, 'Əli');
      expect(restored.surname, 'Məmmədov');
      expect(restored.gender, Gender.male);
      expect(restored.relation, 'Ata');
      expect(restored.education, 'Ali təhsil');
      expect(restored.job, 'Həkim');
      expect(restored.maritalStatus, 'Evli');
      expect(restored.diseases, ['Diabet']);
      expect(restored.interactionHistory, ['Söhbət etdiniz']);
      expect(restored.monthlyIncome, 1500);
      expect(restored.totalMoney, 20000);
      expect(restored.generosity, 70);
      expect(restored.religiousness, 60);
      expect(restored.looks, 55);
      expect(restored.health, 80);
      expect(restored.relationship, 90);
      expect(restored.isAlive, true);
      expect(restored.age, 45);
      expect(restored.askedMoneyThisYear, false);
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/models/family_member_serialization_test.dart
```
Expected: FAIL — `toJson` / `fromJson` not defined.

- [ ] **Step 3: Implement toJson / fromJson on FamilyMember**

In `lib/models/player.dart`, inside `class FamilyMember`, add after the constructor:

```dart
  Map<String, dynamic> toJson() => {
        'name': name,
        'surname': surname,
        'gender': gender.name,          // "male" or "female"
        'relationship': relationship,
        'isAlive': isAlive,
        'age': age,
        'imagePath': imagePath,
        'relation': relation,
        'education': education,
        'job': job,
        'maritalStatus': maritalStatus,
        'diseases': diseases,
        'interactionHistory': interactionHistory,
        'monthlyIncome': monthlyIncome,
        'totalMoney': totalMoney,
        'generosity': generosity,
        'religiousness': religiousness,
        'looks': looks,
        'health': health,
        'askedMoneyThisYear': askedMoneyThisYear,
      };

  factory FamilyMember.fromJson(Map<String, dynamic> j) => FamilyMember(
        name: j['name'] as String,
        surname: j['surname'] as String,
        gender: Gender.values.firstWhere((e) => e.name == j['gender']),
        relation: j['relation'] as String,
        education: j['education'] as String? ?? 'Orta təhsil',
        job: j['job'] as String? ?? 'İşsiz',
        maritalStatus: j['maritalStatus'] as String? ?? 'Subay',
        diseases: List<String>.from(j['diseases'] as List? ?? []),
        interactionHistory: List<String>.from(j['interactionHistory'] as List? ?? []),
        monthlyIncome: j['monthlyIncome'] as int? ?? 0,
        totalMoney: j['totalMoney'] as int? ?? 1000,
        generosity: j['generosity'] as int? ?? 50,
        religiousness: j['religiousness'] as int? ?? 50,
        looks: j['looks'] as int? ?? 60,
        health: j['health'] as int? ?? 70,
        relationship: j['relationship'] as int? ?? 100,
        isAlive: j['isAlive'] as bool? ?? true,
        age: j['age'] as int? ?? 0,
        imagePath: j['imagePath'] as String?,
      )..askedMoneyThisYear = j['askedMoneyThisYear'] as bool? ?? false;
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/models/family_member_serialization_test.dart
```
Expected: PASS.

---

### Task 3: Add toJson / fromJson to SchoolMate

**Files:**
- Modify: `lib/models/player.dart`
- Test: `test/models/school_mate_serialization_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/models/school_mate_serialization_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:az_life/models/player.dart';

void main() {
  group('SchoolMate serialization', () {
    test('round-trips all fields including partner/wedding state', () {
      final original = SchoolMate(
        name: 'Leyla',
        surname: 'Həsənova',
        gender: Gender.female,
        money: 5000,
        health: 85,
        smarts: 70,
        looks: 80,
        relationType: FriendRelationType.partner,
        interactionHistory: ['Tanış oldunuz'],
        askedMoneyThisYear: false,
        occupation: 'Həkim',
        partnerStartAge: 20,
        netWorth: 25000,
        partnerStatus: PartnerStatus.fiance,
        proposalCooldownYears: 0,
        weddingVenue: 'Restoran',
        weddingGuestTier: 2,
        weddingScheduledAge: 25,
        weddingPlanStatus: 'planned',
        weddingTotalCost: 5400,
        weddingDepositPaid: true,
        relationship: 85,
        isAlive: true,
        age: 22,
      );

      final json = original.toJson();
      final restored = SchoolMate.fromJson(json);

      expect(restored.name, 'Leyla');
      expect(restored.gender, Gender.female);
      expect(restored.relationType, FriendRelationType.partner);
      expect(restored.partnerStatus, PartnerStatus.fiance);
      expect(restored.weddingVenue, 'Restoran');
      expect(restored.weddingScheduledAge, 25);
      expect(restored.weddingPlanStatus, 'planned');
      expect(restored.weddingTotalCost, 5400);
      expect(restored.weddingDepositPaid, true);
      expect(restored.occupation, 'Həkim');
      expect(restored.netWorth, 25000);
      expect(restored.relationship, 85);
      expect(restored.age, 22);
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/models/school_mate_serialization_test.dart
```

- [ ] **Step 3: Implement toJson / fromJson on SchoolMate**

In `lib/models/player.dart`, inside `class SchoolMate`, add after the constructor:

```dart
  Map<String, dynamic> toJson() => {
        'name': name,
        'surname': surname,
        'gender': gender.name,
        'relationship': relationship,
        'isAlive': isAlive,
        'age': age,
        'imagePath': imagePath,
        'money': money,
        'health': health,
        'smarts': smarts,
        'looks': looks,
        'relationType': relationType.name,
        'interactionHistory': interactionHistory,
        'askedMoneyThisYear': askedMoneyThisYear,
        'occupation': occupation,
        'partnerStartAge': partnerStartAge,
        'netWorth': netWorth,
        'partnerStatus': partnerStatus.name,
        'proposalCooldownYears': proposalCooldownYears,
        'weddingVenue': weddingVenue,
        'weddingGuestTier': weddingGuestTier,
        'weddingScheduledAge': weddingScheduledAge,
        'weddingPlanStatus': weddingPlanStatus,
        'weddingTotalCost': weddingTotalCost,
        'weddingDepositPaid': weddingDepositPaid,
      };

  factory SchoolMate.fromJson(Map<String, dynamic> j) => SchoolMate(
        name: j['name'] as String,
        surname: j['surname'] as String,
        gender: Gender.values.firstWhere((e) => e.name == j['gender']),
        money: j['money'] as int? ?? 0,
        health: j['health'] as int? ?? 100,
        smarts: j['smarts'] as int? ?? 50,
        looks: j['looks'] as int? ?? 50,
        relationType: FriendRelationType.values.firstWhere(
          (e) => e.name == (j['relationType'] as String? ?? 'friend'),
        ),
        interactionHistory: List<String>.from(j['interactionHistory'] as List? ?? []),
        askedMoneyThisYear: j['askedMoneyThisYear'] as bool? ?? false,
        occupation: j['occupation'] as String? ?? '',
        partnerStartAge: j['partnerStartAge'] as int? ?? 0,
        netWorth: j['netWorth'] as int? ?? 0,
        partnerStatus: PartnerStatus.values.firstWhere(
          (e) => e.name == (j['partnerStatus'] as String? ?? 'partner'),
        ),
        proposalCooldownYears: j['proposalCooldownYears'] as int? ?? 0,
        weddingVenue: j['weddingVenue'] as String? ?? '',
        weddingGuestTier: j['weddingGuestTier'] as int? ?? 1,
        weddingScheduledAge: j['weddingScheduledAge'] as int? ?? 0,
        weddingPlanStatus: j['weddingPlanStatus'] as String? ?? 'none',
        weddingTotalCost: j['weddingTotalCost'] as int? ?? 0,
        weddingDepositPaid: j['weddingDepositPaid'] as bool? ?? false,
        relationship: j['relationship'] as int? ?? 50,
        isAlive: j['isAlive'] as bool? ?? true,
        age: j['age'] as int? ?? 0,
        imagePath: j['imagePath'] as String?,
      );
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/models/school_mate_serialization_test.dart
```

---

### Task 4: Add toJson / fromJson to Player

**Files:**
- Modify: `lib/models/player.dart`
- Test: `test/models/player_serialization_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/models/player_serialization_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:az_life/models/player.dart';

void main() {
  group('Player serialization', () {
    test('round-trips core stats', () {
      final original = Player(
        name: 'Rüfət',
        surname: 'Əliyev',
        gender: Gender.male,
        birthCity: 'Bakı',
        title: 'Yeniyetmə',
        age: 15,
        health: 80,
        happiness: 70,
        smarts: 60,
        looks: 55,
        money: 1200,
      )
        ..isEnrolledInSchool = true
        ..grades = 72.5
        ..hasPartner = false;

      final json = original.toJson();
      final restored = Player.fromJson(json);

      expect(restored.name, 'Rüfət');
      expect(restored.surname, 'Əliyev');
      expect(restored.gender, Gender.male);
      expect(restored.birthCity, 'Bakı');
      expect(restored.title, 'Yeniyetmə');
      expect(restored.age, 15);
      expect(restored.health, 80);
      expect(restored.happiness, 70);
      expect(restored.smarts, 60);
      expect(restored.money, 1200);
      expect(restored.isEnrolledInSchool, true);
      expect(restored.grades, 72.5);
      expect(restored.hasPartner, false);
    });

    test('round-trips family and friends lists', () {
      final original = Player(
        name: 'Anar', surname: 'Nəsirov',
        gender: Gender.male, birthCity: 'Gəncə',
      );
      original.family.add(FamilyMember(
        name: 'Fatimə', surname: 'Nəsirova',
        gender: Gender.female, relation: 'Ana',
      ));
      original.friends.add(SchoolMate(
        name: 'Orxan', surname: 'Quliyev',
        gender: Gender.male,
      ));

      final restored = Player.fromJson(original.toJson());

      expect(restored.family.length, 1);
      expect(restored.family.first.name, 'Fatimə');
      expect(restored.family.first.relation, 'Ana');
      expect(restored.friends.length, 1);
      expect(restored.friends.first.name, 'Orxan');
    });
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/models/player_serialization_test.dart
```

- [ ] **Step 3: Implement toJson / fromJson on Player**

In `lib/models/player.dart`, inside `class Player`, add after `startSchool()`:

```dart
  Map<String, dynamic> toJson() => {
        'name': name,
        'surname': surname,
        'gender': gender.name,
        'birthCity': birthCity,
        'title': title,
        'age': age,
        'health': health,
        'happiness': happiness,
        'smarts': smarts,
        'looks': looks,
        'money': money,
        'imagePath': imagePath,
        'isEnrolledInSchool': isEnrolledInSchool,
        'isEnrolledInUniversity': isEnrolledInUniversity,
        'universityYearsStudied': universityYearsStudied,
        'hasBachelorDegree': hasBachelorDegree,
        'isInMilitary': isInMilitary,
        'militaryYearsServed': militaryYearsServed,
        'militaryServiceDuration': militaryServiceDuration,
        'grades': grades,
        'schoolPopularity': schoolPopularity,
        'schoolActivity': schoolActivity,
        'studiedHardThisYear': studiedHardThisYear,
        'skippedSchoolThisYear': skippedSchoolThisYear,
        'hasPartner': hasPartner,
        'family': family.map((m) => m.toJson()).toList(),
        'friends': friends.map((f) => f.toJson()).toList(),
      };

  factory Player.fromJson(Map<String, dynamic> j) {
    final player = Player(
      name: j['name'] as String,
      surname: j['surname'] as String,
      gender: Gender.values.firstWhere((e) => e.name == j['gender']),
      birthCity: j['birthCity'] as String,
      title: j['title'] as String? ?? 'Körpə',
      age: j['age'] as int? ?? 0,
      health: j['health'] as int? ?? 100,
      happiness: j['happiness'] as int? ?? 100,
      smarts: j['smarts'] as int? ?? 50,
      looks: j['looks'] as int? ?? 50,
      money: j['money'] as int? ?? 0,
      imagePath: j['imagePath'] as String?,
    );
    player.isEnrolledInSchool     = j['isEnrolledInSchool'] as bool? ?? false;
    player.isEnrolledInUniversity = j['isEnrolledInUniversity'] as bool? ?? false;
    player.universityYearsStudied = j['universityYearsStudied'] as int? ?? 0;
    player.hasBachelorDegree      = j['hasBachelorDegree'] as bool? ?? false;
    player.isInMilitary           = j['isInMilitary'] as bool? ?? false;
    player.militaryYearsServed    = j['militaryYearsServed'] as int? ?? 0;
    player.militaryServiceDuration = (j['militaryServiceDuration'] as num?)?.toDouble() ?? 0;
    player.grades                 = (j['grades'] as num?)?.toDouble() ?? 0.0;
    player.schoolPopularity       = j['schoolPopularity'] as int? ?? 50;
    player.schoolActivity         = j['schoolActivity'] as int? ?? 50;
    player.studiedHardThisYear    = j['studiedHardThisYear'] as bool? ?? false;
    player.skippedSchoolThisYear  = j['skippedSchoolThisYear'] as bool? ?? false;
    player.hasPartner             = j['hasPartner'] as bool? ?? false;
    player.family = (j['family'] as List? ?? [])
        .map((m) => FamilyMember.fromJson(m as Map<String, dynamic>))
        .toList();
    player.friends = (j['friends'] as List? ?? [])
        .map((f) => SchoolMate.fromJson(f as Map<String, dynamic>))
        .toList();
    return player;
  }
```

- [ ] **Step 4: Run all model tests — expect all PASS**

```bash
flutter test test/models/
```

- [ ] **Step 5: Commit**

```bash
git add lib/models/player.dart test/models/
git commit -m "feat: add toJson/fromJson serialization to all models"
```

---

## Chunk 2: GameSaveManager + YearLog Serialization

### Task 5: Add YearLog serialization

**Files:**
- Modify: `lib/screens/game_screen.dart` — `YearLog` class (lines 13–18)
- Test: `test/save/year_log_serialization_test.dart`

- [ ] **Step 1: Write the failing test**

Create `test/save/year_log_serialization_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:az_life/screens/game_screen.dart';

void main() {
  test('YearLog round-trips via toJson/fromJson', () {
    final log = YearLog(age: 10, events: ['Məktəbə başladın.', 'Yeni dost tapdın.']);
    final restored = YearLog.fromJson(log.toJson());
    expect(restored.age, 10);
    expect(restored.events, ['Məktəbə başladın.', 'Yeni dost tapdın.']);
  });
}
```

- [ ] **Step 2: Run test — expect FAIL**

```bash
flutter test test/save/year_log_serialization_test.dart
```

- [ ] **Step 3: Add toJson/fromJson to YearLog in game_screen.dart**

Replace the `YearLog` class:

```dart
class YearLog {
  final int age;
  final List<String> events;

  YearLog({required this.age, required this.events});

  Map<String, dynamic> toJson() => {'age': age, 'events': events};

  factory YearLog.fromJson(Map<String, dynamic> j) => YearLog(
        age: j['age'] as int,
        events: List<String>.from(j['events'] as List? ?? []),
      );
}
```

- [ ] **Step 4: Run test — expect PASS**

```bash
flutter test test/save/year_log_serialization_test.dart
```

---

### Task 6: Create GameSaveManager

**Files:**
- Create: `lib/services/save_manager.dart`
- Test: `test/save/save_manager_test.dart`

- [ ] **Step 1: Write the failing tests**

Create `test/save/save_manager_test.dart`:

```dart
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:az_life/models/player.dart';
import 'package:az_life/screens/game_screen.dart';
import 'package:az_life/services/save_manager.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('GameSaveManager', () {
    Player _makePlayer() => Player(
          name: 'Rüfət',
          surname: 'Əliyev',
          gender: Gender.male,
          birthCity: 'Bakı',
          age: 5,
          money: 100,
        );

    test('exists() returns false when no save', () async {
      expect(await GameSaveManager.exists(), false);
    });

    test('save() then exists() returns true', () async {
      final data = SaveData(
        player: _makePlayer(),
        logs: [YearLog(age: 5, events: ['Doğuldun.'])],
        earlyDecisionCountTotal: 1,
        dramaTriggered: {'drama_001'},
      );
      await GameSaveManager.save(data);
      expect(await GameSaveManager.exists(), true);
    });

    test('load() returns null when no save exists', () async {
      expect(await GameSaveManager.load(), null);
    });

    test('save() then load() restores all state correctly', () async {
      final player = _makePlayer()..health = 75;
      final data = SaveData(
        player: player,
        logs: [YearLog(age: 5, events: ['Test hadisə'])],
        earlyDecisionCountTotal: 2,
        dramaTriggered: {'drama_002', 'drama_003'},
      );

      await GameSaveManager.save(data);
      final loaded = await GameSaveManager.load();

      expect(loaded, isNotNull);
      expect(loaded!.player.name, 'Rüfət');
      expect(loaded.player.health, 75);
      expect(loaded.player.age, 5);
      expect(loaded.logs.length, 1);
      expect(loaded.logs.first.events.first, 'Test hadisə');
      expect(loaded.earlyDecisionCountTotal, 2);
      expect(loaded.dramaTriggered, {'drama_002', 'drama_003'});
    });

    test('delete() removes save', () async {
      final data = SaveData(
        player: _makePlayer(),
        logs: [],
        earlyDecisionCountTotal: 0,
        dramaTriggered: {},
      );
      await GameSaveManager.save(data);
      expect(await GameSaveManager.exists(), true);
      await GameSaveManager.delete();
      expect(await GameSaveManager.exists(), false);
    });

    test('getMetadata() returns correct name and age', () async {
      final data = SaveData(
        player: _makePlayer(),
        logs: [],
        earlyDecisionCountTotal: 0,
        dramaTriggered: {},
      );
      await GameSaveManager.save(data);
      final meta = await GameSaveManager.getMetadata();
      expect(meta, isNotNull);
      expect(meta!.name, 'Rüfət');
      expect(meta.surname, 'Əliyev');
      expect(meta.age, 5);
      expect(meta.city, 'Bakı');
    });

    test('load() returns null and auto-deletes corrupted save', () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('azlife_save_v1', 'NOT VALID JSON {{{');
      final result = await GameSaveManager.load();
      expect(result, null);
      expect(await GameSaveManager.exists(), false);
    });
  });
}
```

- [ ] **Step 2: Run tests — expect FAIL**

```bash
flutter test test/save/save_manager_test.dart
```

- [ ] **Step 3: Create lib/services/save_manager.dart**

```dart
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
  static const _saveKey  = 'azlife_save_v1';
  static const _metaKey  = 'azlife_save_meta';
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
        name:    m['name'] as String,
        surname: m['surname'] as String,
        city:    m['city'] as String,
        age:     m['age'] as int,
        savedAt: DateTime.parse(m['savedAt'] as String),
      );
    } catch (_) {
      return null;
    }
  }

  // ── Internal ──────────────────────────────────

  /// Forward migration stub. Currently a no-op at v1.
  /// Add version checks here as save schema evolves:
  ///   if (data['save_version'] < 2) { /* add new field with default */ }
  static Map<String, dynamic> _migrate(Map<String, dynamic> data) {
    // ignore: unused_local_variable
    final version = data['save_version'] as int? ?? 1;
    // TODO: add migration blocks here when save_version increases
    return data;
  }
}
```

- [ ] **Step 4: Run tests — expect all PASS**

```bash
flutter test test/save/save_manager_test.dart
```

- [ ] **Step 5: Commit**

```bash
git add lib/services/save_manager.dart lib/screens/game_screen.dart \
        test/save/
git commit -m "feat: implement GameSaveManager with shared_preferences"
```

---

## Chunk 3: UI — MainMenuScreen + LoadingScreen routing

### Task 7: Create MainMenuScreen

**Files:**
- Create: `lib/screens/main_menu_screen.dart`

No widget tests here — manual validation is sufficient for UI.

- [ ] **Step 1: Create the file**

```dart
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
                      // Save card
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
                      // Continue button
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
                      // New game button
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
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/main_menu_screen.dart
git commit -m "feat: add MainMenuScreen with continue/new-game flow"
```

---

### Task 8: Update LoadingScreen to route based on save state

**Files:**
- Modify: `lib/screens/loading_screen.dart`

`LoadingScreen` currently calls `widget.onFinished()` after 2 seconds. Change it to check for a save and navigate internally using `Navigator.pushReplacement`.

- [ ] **Step 1: Replace LoadingScreen**

Replace the full content of `lib/screens/loading_screen.dart`:

```dart
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
```

- [ ] **Step 2: Update main.dart to use LoadingScreen as home**

Replace `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'screens/loading_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AzLifeApp());
}

class AzLifeApp extends StatelessWidget {
  const AzLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AzLife',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const LoadingScreen(),
    );
  }
}
```

- [ ] **Step 3: Commit**

```bash
git add lib/screens/loading_screen.dart lib/main.dart
git commit -m "feat: route through LoadingScreen to MainMenu or CharacterCreation based on save"
```

---

## Chunk 4: GameScreen Integration

### Task 9: Add DramaManager.restoreTriggered()

`MainMenuScreen._continue()` calls `DramaManager().restoreTriggered(data.dramaTriggered)` — we need to add this method.

**Files:**
- Modify: `lib/screens/drama_manager.dart`

- [ ] **Step 1: Add restoreTriggered to DramaManager**

In `lib/screens/drama_manager.dart`, inside `class DramaManager`, add after `resetLife()`:

```dart
  void restoreTriggered(Set<String> ids) {
    _triggeredThisLife
      ..clear()
      ..addAll(ids);
  }
```

Also add a getter so `GameScreen` can read triggered IDs for saving:

```dart
  Set<String> get triggeredThisLife => Set.unmodifiable(_triggeredThisLife);
```

- [ ] **Step 2: Commit**

```bash
git add lib/screens/drama_manager.dart
git commit -m "feat: add DramaManager.restoreTriggered() and triggeredThisLife getter"
```

---

### Task 10: Update GameScreen constructor + auto-save + lifecycle + manual save

**Files:**
- Modify: `lib/screens/game_screen.dart`

This task has four parts woven into one edit. Read carefully.

**Part A — Update GameScreen constructor** to accept optional `initialLogs` and `initialEarlyDecisionCount` (needed for save restore):

- [ ] **Step 1: Update GameScreen widget**

Replace `class GameScreen`:

```dart
class GameScreen extends StatefulWidget {
  final Player player;
  final List<YearLog> initialLogs;
  final int initialEarlyDecisionCount;

  const GameScreen({
    super.key,
    required this.player,
    this.initialLogs = const [],
    this.initialEarlyDecisionCount = 0,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}
```

**Part B — Initialize from restored state** in `initState()`:

In `_GameScreenState.initState()`, change:
```dart
// OLD:
logs.add(YearLog(age: 0, events: [...]));
```
to:
```dart
// NEW:
if (widget.initialLogs.isNotEmpty) {
  logs = List.from(widget.initialLogs);
} else {
  logs.add(YearLog(age: 0, events: [
    "Sən ${player.birthCity} şəhərində anadan olmusan.",
    "Sən sağlam ${player.gender == Gender.male ? 'oğlan' : 'qız'} uşağısan.",
    "Valideynlərin çox xoşbəxtdir."
  ]));
}
_earlyDecisionCountTotal = widget.initialEarlyDecisionCount;
```

**Part C — Auto-save after ageUp()** — add `_autoSave()` call at the end of `ageUp()`, OUTSIDE the `setState`:

```dart
void ageUp() {
  SoundManager.playAgeUp();
  setState(() {
    // ... existing code unchanged ...
  });
  _autoSave(); // ← add this line after setState closes
}

Future<void> _autoSave() async {
  final data = SaveData(
    player: player,
    logs: logs,
    earlyDecisionCountTotal: _earlyDecisionCountTotal,
    dramaTriggered: DramaManager().triggeredThisLife,
  );
  await GameSaveManager.save(data);
}
```

Add the required imports at the top of `game_screen.dart`:
```dart
import '../services/save_manager.dart';
```

**Part D — AppLifecycle observer for exit-save** — make `_GameScreenState` implement `WidgetsBindingObserver`:

```dart
class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
```

In `initState()`, add:
```dart
WidgetsBinding.instance.addObserver(this);
```

In `dispose()`, add:
```dart
WidgetsBinding.instance.removeObserver(this);
```

Add the lifecycle callback:
```dart
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.paused) {
    _autoSave();
  }
}
```

**Part E — Manual save button** in the AppBar. Find the existing `AppBar` build in `GameScreen` and add an actions icon button. The exact location will be in the `build()` method where `AppBar` is constructed. Add to `AppBar.actions`:

```dart
actions: [
  IconButton(
    icon: const Icon(Icons.save_outlined),
    tooltip: 'Oyunu saxla',
    onPressed: () async {
      await _autoSave();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Oyun saxlandı'),
            duration: Duration(seconds: 1),
            backgroundColor: Color(0xFF2EC95C),
          ),
        );
      }
    },
  ),
  // ... any existing action buttons ...
],
```

- [ ] **Step 2: Hot-restart and verify manually**

```bash
flutter run
```

Test checklist:
- [ ] New game creates character → plays → age up → close app → reopen → MainMenuScreen appears with correct name/age
- [ ] Tap "Davam et" → drops into game at correct age
- [ ] Tap save icon → green "Oyun saxlandı" snackbar appears
- [ ] Tap "Yeni oyun" → confirmation dialog → clears to CharacterCreationScreen

- [ ] **Step 3: Run all tests**

```bash
flutter test
```
Expected: all tests PASS.

- [ ] **Step 4: Commit**

```bash
git add lib/screens/game_screen.dart lib/services/save_manager.dart
git commit -m "feat: auto-save, lifecycle exit-save, and manual save button in GameScreen"
```

---

## Final verification

- [ ] Run full test suite one more time:

```bash
flutter test
```

- [ ] Run app on device/emulator, trace the full scenario:
  1. Fresh install → `LoadingScreen` → `CharacterCreationScreen` (no save exists)
  2. Create character "Rüfət, Bakı, Kişi" → `GameScreen` loads
  3. Press "İrəli" (ageUp) twice → auto-save fires after each
  4. Press back/home to background app → exit-save fires
  5. Reopen app → `LoadingScreen` → `MainMenuScreen` shows "Rüfət Əliyev, 2 yaş · Bakı"
  6. Tap "Davam et" → `GameScreen` opens at age 2, logs intact, family intact
  7. Tap save icon → snackbar appears
  8. Tap "Yeni oyun" → dialog → confirm → `CharacterCreationScreen`

- [ ] Final commit:

```bash
git add .
git commit -m "feat: complete save/load system with MainMenuScreen"
```

---

## Files Summary

| File | Action | Purpose |
|---|---|---|
| `pubspec.yaml` | Modify | Add shared_preferences dependency |
| `lib/models/player.dart` | Modify | toJson/fromJson on FamilyMember, SchoolMate, Player |
| `lib/screens/game_screen.dart` | Modify | YearLog serialization, initialLogs param, auto-save, lifecycle, manual save |
| `lib/screens/drama_manager.dart` | Modify | restoreTriggered(), triggeredThisLife getter |
| `lib/services/save_manager.dart` | **Create** | GameSaveManager, SaveData, SaveMeta |
| `lib/screens/main_menu_screen.dart` | **Create** | Continue / New Game UI |
| `lib/screens/loading_screen.dart` | Modify | Route to MainMenuScreen or CharacterCreationScreen |
| `lib/main.dart` | Modify | Use LoadingScreen as home |
| `test/models/family_member_serialization_test.dart` | **Create** | Unit test |
| `test/models/school_mate_serialization_test.dart` | **Create** | Unit test |
| `test/models/player_serialization_test.dart` | **Create** | Unit test |
| `test/save/year_log_serialization_test.dart` | **Create** | Unit test |
| `test/save/save_manager_test.dart` | **Create** | Unit tests for all GameSaveManager methods |
