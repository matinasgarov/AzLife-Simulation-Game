# Save / Load System — Design Spec
**Date:** 2026-03-11
**Project:** AzLife Simulation Game (Flutter/Dart, Android/iOS)
**Status:** Approved

---

## 1. Goals

- Persist all game state across app restarts, so players never lose progress.
- Auto-save after every meaningful action; manual save button available in-game.
- Exit-save when app goes to background.
- Show a "Davam et / Yeni oyun" main menu when a save exists.
- Handle corrupted saves gracefully without crashing.
- Single save slot (multi-slot is a future extension).

---

## 2. Storage Layer

**Package:** `shared_preferences: ^2.3.2`
Maps to `SharedPreferences` (Android) and `NSUserDefaults` (iOS).
Store-safe, no special permissions, data included in OS backup systems.

**Keys:**
| Key | Contents |
|---|---|
| `azlife_save_v1` | Full serialized game state as JSON string |
| `azlife_save_meta` | Lightweight `{ name, surname, age, city, savedAt }` for Continue screen |

---

## 3. Save Schema

```json
{
  "save_version": 1,
  "player": { ... },
  "logs": [ { "age": 5, "events": ["..."] }, ... ],
  "earlyDecisionCountTotal": 3,
  "dramaTriggered": ["drama_001", "drama_004"]
}
```

**`player` object includes all 25+ fields:**
- Core stats: name, surname, gender, birthCity, title, age, health, happiness, smarts, looks, money
- Education: isEnrolledInSchool, isEnrolledInUniversity, universityYearsStudied, hasBachelorDegree, grades, schoolPopularity, schoolActivity, studiedHardThisYear, skippedSchoolThisYear
- Military: isInMilitary, militaryYearsServed, militaryServiceDuration
- Flags: hasPartner
- `family`: List of FamilyMember objects
- `friends`: List of SchoolMate objects

**`FamilyMember` fields:** name, surname, gender, relation, education, job, maritalStatus, diseases, interactionHistory, monthlyIncome, totalMoney, generosity, religiousness, looks, health, relationship, isAlive, age, askedMoneyThisYear

**`SchoolMate` fields:** name, surname, gender, money, health, smarts, looks, relationType, interactionHistory, askedMoneyThisYear, occupation, partnerStartAge, netWorth, partnerStatus, proposalCooldownYears, weddingVenue, weddingGuestTier, weddingScheduledAge, weddingPlanStatus, weddingTotalCost, weddingDepositPaid, relationship, isAlive, age

**Enums serialized as strings:** `Gender` → `"male"/"female"`, `FriendRelationType` → `"friend"/"bestFriend"/"partner"`, `PartnerStatus` → `"partner"/"fiance"/"married"`

**Not persisted** (loaded from assets on startup): JSON config files (decisions, school questions, university exams, drama events, love interactions, restaurants, wedding config).

---

## 4. GameSaveManager

**File:** `lib/services/save_manager.dart`

```dart
class SaveData {
  final Player player;
  final List<YearLog> logs;
  final int earlyDecisionCountTotal;
  final Set<String> dramaTriggered;
}

class SaveMeta {
  final String name, surname, city;
  final int age;
  final DateTime savedAt;
}

class GameSaveManager {
  static Future<void> save(SaveData data);
  static Future<SaveData?> load();   // null = no save or corrupted
  static Future<bool> exists();
  static Future<void> delete();
  static Future<SaveMeta?> getMetadata();

  // Internal
  static Map<String, dynamic> _migrate(Map<String, dynamic> data);
  // Currently a no-op at v1. Checks save_version for future forward migrations.
}
```

---

## 5. Serialization — toJson / fromJson

Added to models in `lib/models/player.dart`:

- `FamilyMember.toJson()` / `FamilyMember.fromJson(Map)`
- `SchoolMate.toJson()` / `SchoolMate.fromJson(Map)`
- `Player.toJson()` / `Player.fromJson(Map)` — calls family/friends fromJson internally

Added to `YearLog` in `lib/screens/game_screen.dart`:
- `YearLog.toJson()` / `YearLog.fromJson(Map)`

---

## 6. Save Triggers

| Trigger | When | Implementation |
|---|---|---|
| Auto-save | After every `ageUp()` | Called at end of `setState` in `ageUp()` |
| Manual save | User taps save icon | Icon button in GameScreen AppBar menu → snackbar confirmation |
| Exit-save | App backgrounded | `WidgetsBindingObserver.didChangeAppLifecycleState(AppLifecycleState.paused)` |

---

## 7. App Startup Flow

```
main.dart → LoadingScreen (splash)
                ↓
        GameSaveManager.exists()?
           /           \
         YES            NO
          ↓              ↓
   MainMenuScreen   CharacterCreationScreen
   [Davam et]            ↓
   [Yeni oyun]       GameScreen (new)
       ↓
   [Davam et] → load() → GameScreen (restored)
   [Yeni oyun] → confirm dialog → delete() → CharacterCreationScreen
```

---

## 8. MainMenuScreen

**File:** `lib/screens/main_menu_screen.dart`

Shows:
- Game title "AzLife"
- Save card: `{name} {surname}`, `{age} yaş · {city}`, `Son: {savedAt relative time}`
- Green "DAVAM ET" button
- Outline "YENİ OYUN" button (triggers confirm dialog before deleting save)

If `load()` fails (corrupted save): show error snackbar, delete save, navigate to CharacterCreationScreen.

---

## 9. Error Handling & Migration

- All `load()` calls wrapped in `try/catch`
- On JSON parse failure or version mismatch: delete save, start fresh, show Azerbaijani error message: `"Saxlama faylı zədələnib. Yeni oyun başladılır."`
- `_migrate(data)`: checks `save_version`, applies forward patches (no-op at v1)

---

## 10. Files Modified / Created

| File | Change |
|---|---|
| `pubspec.yaml` | Add `shared_preferences: ^2.3.2` |
| `lib/models/player.dart` | Add `toJson`/`fromJson` to `FamilyMember`, `SchoolMate`, `Player` |
| `lib/services/save_manager.dart` | **NEW** — `GameSaveManager`, `SaveData`, `SaveMeta` |
| `lib/screens/main_menu_screen.dart` | **NEW** — Continue / New Game UI |
| `lib/screens/game_screen.dart` | Add `YearLog` serialization, auto-save in `ageUp()`, lifecycle observer, manual save button |
| `lib/screens/loading_screen.dart` | Route to `MainMenuScreen` if save exists |

---

## 11. Test Scenario (manual trace)

1. New game → CharacterCreationScreen → create "Rüfət, Bakı, male"
2. GameScreen loads → `ageUp()` called → auto-save triggers → `azlife_save_v1` written
3. User taps save icon → snackbar: "Oyun saxlandı"
4. User closes app → `AppLifecycleState.paused` → exit-save triggers
5. User reopens app → LoadingScreen → `exists()` = true → MainMenuScreen shows "Rüfət Əliyev, 1 yaş · Bakı"
6. User taps "Davam et" → `load()` → Player reconstructed from JSON → GameScreen opens at age 1
7. State matches: all stats, family, friends, logs identical to before close

---

## 12. Intentional Exclusions

| Excluded | Reason |
|---|---|
| `_allDecisions`, `_schoolQuestions`, etc. | Loaded from JSON assets on every startup — no need to save |
| `_random` (Random instance) | Stateless — new instance each run is correct behavior |
| `DramaManager._allEvents` | Loaded from `drama_events.json` on startup |
| `_boyNames`, `_girlNames`, `_jobIncomes` | Constant lists, not game state |

---

## 13. Future Extensions (TODO)

- `// TODO: multi-slot` — support 3 named save slots (`azlife_save_v1_slot1/2/3`)
- `// TODO: cloud-save` — Google Play Games / Game Center integration for cross-device sync
