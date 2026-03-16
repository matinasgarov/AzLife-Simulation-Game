import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../services/sound_manager.dart';
import 'activities_screen.dart';
import 'relationships_screen.dart';
import 'occupation_screen.dart';
import 'drama_manager.dart';
import '../services/save_manager.dart';
import '../utils/avatar_utils.dart';

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

class GameScreen extends StatefulWidget {
  final Player player;
  final List<YearLog>? initialLogs;
  final int initialEarlyDecisionCount;
  const GameScreen({
    super.key,
    required this.player,
    this.initialLogs,
    this.initialEarlyDecisionCount = 0,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with WidgetsBindingObserver {
  late Player player;
  List<YearLog> logs = [];
  final Random _random = Random();
  int _earlyDecisionCountTotal = 0;
  Map<String, dynamic>? _allDecisions;
  Map<String, dynamic>? _schoolQuestions;
  Map<String, dynamic>? _universityExams;

  final List<String> _boyNames = ["Rüfət", "Məmməd", "Əli", "Vüqar", "Anar", "Elnur", "Tural", "Orxan", "Rəşad", "Nicat"];
  final List<String> _girlNames = ["Aysel", "Leyla", "Fidan", "Günay", "Nigar", "Sevda", "Aytən", "Lamiyə", "Nərmin", "Arzu"];
  static const _surnames = [
    "Məmmədov", "Əliyev", "Həsənov", "Hüseynov", "Quliyev",
    "Babayev", "Əhmədov", "Rəhimov", "İsmayılov", "Nəsirov",
    "Cəfərov", "Mustafayev", "Kərimov", "Səfərov", "Orucov",
    "Abbasov", "Vəliyev", "Rzayev", "Sultanov", "Novruzov",
  ];

  final Map<String, List<int>> _jobIncomes = {
    "Müəllim": [500, 1000],
    "Həkim": [1000, 3000],
    "Mühəndis": [1200, 2500],
    "Satıcı": [400, 800],
    "Sürücü": [600, 1200],
    "Ofis işçisi": [800, 1500],
    "Fəhlə": [400, 700],
    "Biznesmen": [2500, 5000],
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    player = widget.player;
    _loadData();

    if (widget.initialLogs != null) {
      // Restoring from save
      logs = widget.initialLogs!;
      _earlyDecisionCountTotal = widget.initialEarlyDecisionCount;
    } else {
      // New game
      _initializeFamily();
      logs.add(YearLog(age: 0, events: [
        "Sən ${player.birthCity} şəhərində anadan olmusan.",
        "Sən sağlam ${player.gender == Gender.male ? 'oğlan' : 'qız'} uşağısan.",
        "Valideynlərin çox xoşbəxtdir."
      ]));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        SoundManager.playBabyBorn();
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _autoSave();
    }
  }

  Future<void> _autoSave() async {
    await GameSaveManager.save(SaveData(
      player: player,
      logs: logs,
      earlyDecisionCountTotal: _earlyDecisionCountTotal,
      dramaTriggered: DramaManager().triggeredThisLife,
    ));
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        rootBundle.loadString('assets/json/decisions.json'),
        rootBundle.loadString('assets/json/school_questions.json'),
        rootBundle.loadString('assets/json/university_exams.json'),
        DramaManager().load().then((_) => ''),
      ]);

      setState(() {
        _allDecisions = json.decode(results[0]);
        _schoolQuestions = json.decode(results[1]);
        _universityExams = json.decode(results[2]);
      });
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  void _initializeFamily() {
    // Birthplace logic for family wealth
    double multiplier = 1.0;
    if (player.birthCity == "Bakı") {
      multiplier = 1.5;
    } else if (player.birthCity == "Gəncə" || player.birthCity == "Sumqayıt") {
      multiplier = 1.2;
    } else {
      multiplier = 0.8;
    }

    var fatherJob = _jobIncomes.keys.toList()[_random.nextInt(_jobIncomes.length)];
    var motherJob = _jobIncomes.keys.toList()[_random.nextInt(_jobIncomes.length)];

    var fatherRange = _jobIncomes[fatherJob]!;
    var motherRange = _jobIncomes[motherJob]!;

    String fatherName = _boyNames[_random.nextInt(_boyNames.length)];

    final motherHealth = 40 + _random.nextInt(61); // 40-100
    final fatherHealth = 40 + _random.nextInt(61);

    player.family.add(FamilyMember(
        name: _girlNames[_random.nextInt(_girlNames.length)],
        surname: player.surname,
        gender: Gender.female,
        relation: "Ana",
        age: 25 + _random.nextInt(10),
        job: motherJob,
        maritalStatus: "Evli",
        monthlyIncome: ((motherRange[0] + _random.nextInt(motherRange[1] - motherRange[0])) * multiplier).toInt(),
        generosity: _random.nextInt(101),
        religiousness: _random.nextInt(101),
        looks: 30 + _random.nextInt(61),   // 30-90
        health: motherHealth,
        totalMoney: ((_random.nextInt(5000) + 1000) * multiplier).toInt(),
        imageVariant: _random.nextInt(100),
    ));
    player.family.add(FamilyMember(
        name: fatherName,
        surname: player.surname,
        gender: Gender.male,
        relation: "Ata",
        age: 28 + _random.nextInt(10),
        job: fatherJob,
        maritalStatus: "Evli",
        monthlyIncome: ((fatherRange[0] + _random.nextInt(fatherRange[1] - fatherRange[0])) * multiplier).toInt(),
        generosity: _random.nextInt(101),
        religiousness: _random.nextInt(101),
        looks: 30 + _random.nextInt(61),   // 30-90
        health: fatherHealth,
        totalMoney: ((_random.nextInt(10000) + 2000) * multiplier).toInt(),
        imageVariant: _random.nextInt(100),
    ));

    // Task 8: Player starting health inherited from parents
    final inheritedHealth = ((motherHealth + fatherHealth) / 2 * (0.85 + _random.nextDouble() * 0.3)).round();
    player.health = inheritedHealth.clamp(10, 100);
  }

  void _checkFriendRequest() {
    // Determine life context and base chance
    String? context;
    double chance;

    if (player.isEnrolledInSchool && player.age >= 6) {
      context = 'school';
      chance = 0.15;
    } else if (player.isEnrolledInUniversity) {
      context = 'university';
      chance = 0.12;
    } else if (player.isInMilitary) {
      context = 'military';
      chance = 0.20;
    } else if (player.age >= 18 && player.age < 70) {
      context = 'adult';
      chance = 0.10;
    } else {
      return;
    }

    // Diminishing returns based on active friend count
    final activeFriends = player.friends.where((f) => f.isAlive).length;
    if (activeFriends >= 15) return;
    if (activeFriends >= 10) chance *= 0.5;

    if (_random.nextDouble() >= chance) return;

    final potentialFriend = _generatePerson(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFriendRequestDialog(potentialFriend);
    });
  }

  SchoolMate _generatePerson(String context) {
    bool isBoy = _random.nextBool();
    String name = isBoy
        ? _boyNames[_random.nextInt(_boyNames.length)]
        : _girlNames[_random.nextInt(_girlNames.length)];

    int age;
    int smarts;
    int looks;
    int health;
    int money;
    String occupation = "";
    int netWorth = 0;

    switch (context) {
      case 'school':
        age = player.age + _random.nextInt(3) - 1;
        smarts = 30 + _random.nextInt(71);
        looks = 30 + _random.nextInt(71);
        health = 50 + _random.nextInt(51);
        money = _random.nextInt(500);
        break;

      case 'university':
        age = player.age + _random.nextInt(5) - 2;
        smarts = 50 + _random.nextInt(51);
        looks = 30 + _random.nextInt(71);
        health = 50 + _random.nextInt(51);
        money = _random.nextInt(800);
        occupation = "Tələbə";
        break;

      case 'military':
        isBoy = true;
        name = _boyNames[_random.nextInt(_boyNames.length)];
        age = player.age + _random.nextInt(3) - 1;
        smarts = 30 + _random.nextInt(51);
        looks = 30 + _random.nextInt(71);
        health = 60 + _random.nextInt(41);
        money = _random.nextInt(200);
        occupation = "Əsgər";
        break;

      case 'adult':
      default:
        age = (player.age + _random.nextInt(11) - 5).clamp(18, 90);
        smarts = 20 + _random.nextInt(81);
        looks = 20 + _random.nextInt(71);
        health = 30 + _random.nextInt(61);
        final jobs = _jobIncomes.keys.toList();
        occupation = jobs[_random.nextInt(jobs.length)];
        final range = _jobIncomes[occupation]!;
        final monthlyIncome = range[0] + _random.nextInt(range[1] - range[0]);
        final workYears = (age - 18).clamp(0, 50);
        netWorth = monthlyIncome * 12 * workYears ~/ 3 + _random.nextInt(5000);
        money = monthlyIncome * _random.nextInt(6);
        break;
    }

    return SchoolMate(
      name: name,
      surname: _surnames[_random.nextInt(_surnames.length)],
      gender: isBoy ? Gender.male : Gender.female,
      age: age,
      money: money,
      health: health,
      smarts: smarts,
      looks: looks,
      imageVariant: _random.nextInt(100),
      occupation: occupation,
      netWorth: netWorth,
    );
  }

  void _showFriendRequestDialog(SchoolMate friend) {
    final title = switch (friend.occupation) {
      "Tələbə" => "Yeni Kursyoldaşı",
      "Əsgər"  => "Yeni Silah Yoldaşı",
      String o when o.isNotEmpty => "Yeni Tanışlıq",
      _ => "Yeni Dostluq Təklifi",
    };
    final intro = switch (friend.occupation) {
      "Tələbə" => "${friend.name} universitetdə səninlə tanış olmaq istəyir.",
      "Əsgər"  => "${friend.name} hərbi xidmətdə səninlə dost olmaq istəyir.",
      String o when o.isNotEmpty => "${friend.name} ($o) səninlə tanış olmaq istəyir.",
      _ => "${friend.name} səninlə dost olmaq istəyir. Onun statusu:",
    };

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(intro, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 15),
            _friendStatRow("Ağıl", friend.smarts),
            _friendStatRow("Görünüş", friend.looks),
            _friendStatRow("Sağlamlıq", friend.health),
            _friendStatRow("Maddi vəziyyət", friend.money, isMoney: true),
            if (friend.occupation.isNotEmpty && friend.occupation != "Tələbə" && friend.occupation != "Əsgər")
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Peşə", style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    Text(friend.occupation, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                  ],
                ),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Rədd et", style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            onPressed: () {
              setState(() {
                player.friends.add(friend);
                final logMsg = friend.occupation.isNotEmpty && friend.occupation != "Tələbə" && friend.occupation != "Əsgər"
                    ? "${friend.name} (${friend.occupation}) ilə tanış olub dost oldun."
                    : "${friend.name} ilə dost oldun.";
                logs.first.events.add(logMsg);
              });
              Navigator.pop(context);
            },
            child: const Text("Qəbul et"),
          ),
        ],
      ),
    );
  }

  Widget _friendStatRow(String label, int value, {bool isMoney = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
          Text(isMoney ? "$value AZN" : "$value%", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
        ],
      ),
    );
  }

  void _checkSiblingBirth() {
    if (player.age > 1 && player.age < 15 && _random.nextDouble() < 0.1) {
      bool isBoy = _random.nextBool();
      
      // Issue #4: Brothers name cannot be same as father's name
      String? fatherName = player.family.firstWhere((m) => m.relation == "Ata").name;
      String name;
      do {
        name = isBoy ? _boyNames[_random.nextInt(_boyNames.length)] : _girlNames[_random.nextInt(_girlNames.length)];
      } while (isBoy && name == fatherName);

      player.family.add(FamilyMember(name: name, surname: player.surname, gender: isBoy ? Gender.male : Gender.female, relation: isBoy ? "Qardaş" : "Bacı", age: 0, imageVariant: _random.nextInt(100)));
      logs.first.events.add("Sənin yeni bir ${isBoy ? 'qardaşın' : 'bacın'} dünyaya gəldi! Adını $name qoydular.");
    }
  }

  void ageUp() {
    SoundManager.playAgeUp();
    setState(() {
      player.age++;
      player.health = (player.health + _random.nextInt(10) - 5).clamp(0, 100);
      player.happiness = (player.happiness + _random.nextInt(10) - 5).clamp(0, 100);
      player.smarts = (player.smarts + _random.nextInt(2) - 1).clamp(0, 100); // nerfed: was nextInt(4)
      player.looks = (player.looks + _random.nextInt(4) - 1).clamp(0, 100);

      // Issue #2: Status change after age 10
      if (player.age == 10 && player.title == "Körpə") {
        player.title = "Yeniyetmə";
      }

      List<String> yearEvents = [];

      for (var member in player.family) {
        member.askedMoneyThisYear = false;
        member.age++;
        member.totalMoney += member.monthlyIncome * 12;
        // Natural aging: health decline after 60
        if (member.isAlive && member.age > 60) {
          member.health -= _random.nextInt(5) + 1;
        }
        if (member.isAlive && member.age > 75) {
          member.health -= _random.nextInt(5) + 2;
        }
        // Death check
        if (member.health <= 0 && member.isAlive) {
          member.isAlive = false;
          member.health = 0;
          yearEvents.add("💀 ${member.relation}ın ${member.name} vəfat etdi. Allah rəhmət eləsin.");
        }
      }
      for (var friend in player.friends) {
        friend.age++;
        if (friend.proposalCooldownYears > 0) {
          friend.proposalCooldownYears--;
        }
        // Elderly friends health decline
        if (friend.isAlive && friend.age > 70) {
          friend.health -= _random.nextInt(4) + 1;
        }
        if (friend.health <= 0 && friend.isAlive) {
          friend.isAlive = false;
          friend.health = 0;
          yearEvents.add("💀 Dostun ${friend.name} vəfat etdi.");
          if (friend.relationType == FriendRelationType.partner) {
            player.hasPartner = false;
          }
        }
        // Wedding trigger: execute wedding when scheduled age is reached
        if (friend.isAlive &&
            friend.relationType == FriendRelationType.partner &&
            friend.partnerStatus == PartnerStatus.fiance &&
            friend.weddingScheduledAge > 0 &&
            friend.weddingScheduledAge == player.age) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _triggerWedding(friend);
          });
        }
      }
      
      if (player.isInMilitary) {
        player.militaryYearsServed++;
        if (player.militaryYearsServed >= player.militaryServiceDuration) {
          player.isInMilitary = false;
          player.title = "Tərxis olunmuş";
          yearEvents.add("Sən hərbi xidməti uğurla başa vurdun və tərxis olundun.");
        } else {
          yearEvents.add("Hərbi xidmətini davam etdirirsən.");
        }
      }

      if (player.isEnrolledInUniversity) {
        player.universityYearsStudied++;
        yearEvents.add("Universitetdə ${player.universityYearsStudied}-cü kursda oxuyursan.");
        if (player.universityYearsStudied >= 4) {
          player.isEnrolledInUniversity = false;
          player.hasBachelorDegree = true;
          player.title = "Məzun";
          yearEvents.add("Təbriklər! Sən universiteti bitirdin və Bakalavr dərəcəsi aldın.");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPostUniversityChoice();
          });
        }
      }

      if (player.isEnrolledInSchool) {
        if (player.age == 18) {
          player.isEnrolledInSchool = false;
          yearEvents.add("Sən məktəbi bitirdin!");
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showPostSchoolChoice();
          });
        } else {
          if (player.skippedSchoolThisYear) {
            player.grades = (player.grades * 0.9).clamp(0, 100);
            yearEvents.add("Dərsdən qaçdığın üçün qiymətlərin düşdü.");
          } else if (player.studiedHardThisYear) {
            player.grades = (player.grades * 1.1).clamp(0, 100);
            yearEvents.add("Dərslərinə çox çalışdın.");
          }
          player.studiedHardThisYear = false;
          player.skippedSchoolThisYear = false;
        }
      }

      if (player.age == 6) {
        player.startSchool();
        int schoolNum = _random.nextInt(300) + 1;
        yearEvents.add("Sən $schoolNum nömrəli məktəbə getməyə başladın.");
        
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showGameNotification(
            "Təbriklər, Artıq Məktəblisən! 🎒",
            "Səni $schoolNum nömrəli məktəbə qəbul etdilər. \n\nBaşlanğıc Qiymətin: ${player.grades.toInt()}%\n(Ağıl səviyyənə görə təyin edildi)",
          );
        });
      }

      logs.insert(0, YearLog(age: player.age, events: yearEvents));
      _checkSiblingBirth();
      _checkFriendRequest();
      
      // Roll for drama
      final drama = DramaManager().rollDrama(
        playerAge: player.age,
        hasGirlfriend: player.hasPartner,
        currentTrigger: player.isEnrolledInSchool ? 'school' : 'random',
      );

      if (drama != null) {
        final choice = drama.choices[_random.nextInt(drama.choices.length)];
        DramaManager().applyChoice(choice: choice, player: player);
        logs.first.events.add("${drama.dramaEmoji} ${drama.title}: ${choice.outcome}");
      }

      _handleDecisions();
    });
    _autoSave();
  }

  void _showPostSchoolChoice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Gələcək Seçimi", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Məktəbi bitirdin. İndi nə etmək istəyirsən?"),
        actions: [
          _choiceButton("Universitetə müraciət et", () {
            Navigator.pop(context);
            _showUniversityList();
          }),
          if (player.gender == Gender.male)
            _choiceButton("Hərbi xidmətə get", () {
              Navigator.pop(context);
              _triggerArmy(isBachelor: false);
            }),
          _choiceButton("İş axtar", () {
            setState(() {
              player.title = "İşsiz";
              logs.first.events.add("İş axtarmağa başladın.");
            });
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  void _showPostUniversityChoice() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Məzuniyyət Seçimi", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("Universiteti bitirdin. Növbəti addımın nə olacak?"),
        actions: [
          _choiceButton("Magistraturaya müraciət et", () {
            setState(() {
              player.title = "Magistrant";
              logs.first.events.add("Magistraturaya qəbul oldun!");
            });
            Navigator.pop(context);
          }),
          if (player.gender == Gender.male)
            _choiceButton("Hərbi xidmətə get (1 il)", () {
              Navigator.pop(context);
              _triggerArmy(isBachelor: true);
            }),
          _choiceButton("İş axtar", () {
            setState(() {
              player.title = "Mütəxəssis";
              logs.first.events.add("İxtisasın üzrə iş axtarmağa başladın.");
            });
            Navigator.pop(context);
          }),
        ],
      ),
    );
  }

  void _showUniversityList() {
    if (_universityExams == null) return;
    List<dynamic> unis = _universityExams!['universityExams'];
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Universitet Seç", style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: unis.length,
            itemBuilder: (context, index) {
              var uni = unis[index];
              return ListTile(
                title: Text(uni['universityName']),
                subtitle: Text("Çətinlik: ${uni['difficulty']}/5"),
                onTap: () {
                  Navigator.pop(context);
                  _startUniversityExam(uni);
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _startUniversityExam(Map<String, dynamic> uni) {
    List<dynamic> questions = List.from(uni['questions']);
    questions.shuffle();
    var q = questions.first;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("${uni['shortName']} Qəbul İmtahanı"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(uni['examIntro'], style: const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
            const SizedBox(height: 15),
            Text(q['question'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        actions: (q['options'] as List<dynamic>).asMap().entries.map((entry) {
          return _choiceButton(entry.value, () {
            Navigator.pop(context);
            bool passed = entry.key == q['correctIndex'];
            _finishUniversityExam(uni, passed);
          });
        }).toList(),
      ),
    );
  }

  void _finishUniversityExam(Map<String, dynamic> uni, bool passed) {
    if (passed) {
      SoundManager.playSuccess();
    } else {
      SoundManager.playFail();
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(passed ? "Təbriklər!" : "Təəssüf..."),
        content: Text(passed 
          ? "${uni['universityName']} universitetinə qəbul oldun!"
          : "Sualı səhv cavablandırdın və imtahandan kəsildin."),
        actions: [
          _choiceButton("Davam et", () {
            setState(() {
              if (passed) {
                player.isEnrolledInUniversity = true;
                player.universityYearsStudied = 0;
                player.title = "Tələbə";
                logs.first.events.add("${uni['shortName']} tələbəsi oldun.");
              } else {
                logs.first.events.add("${uni['universityName']} imtahanından kəsildin.");
                if (player.gender == Gender.male) _triggerArmy(isBachelor: false);
              }
            });
            Navigator.pop(context);
          })
        ],
      ),
    );
  }

  void _triggerArmy({required bool isBachelor}) {
    double duration = isBachelor ? 1.0 : 1.5;
    setState(() {
      player.isInMilitary = true;
      player.militaryYearsServed = 0;
      player.militaryServiceDuration = duration;
      player.title = "Əsgər";
      logs.first.events.add("Hərbi xidmətə çağırıldın. Xidmət müddəti: $duration il.");
    });
  }

  Widget _choiceButton(String label, VoidCallback onPressed) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blueAccent,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 50),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        ),
        onPressed: onPressed,
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _handleDecisions() {
    if (_allDecisions == null) return;

    if (player.isEnrolledInSchool && _random.nextDouble() < 0.3) {
      Future.delayed(const Duration(milliseconds: 500), () => _triggerSchoolExam());
      return;
    }

    if (player.age < 6 && _earlyDecisionCountTotal < 2) {
      if (player.age == 2 || player.age == 4) {
        _earlyDecisionCountTotal++;
        Future.delayed(const Duration(milliseconds: 500), () => _triggerDecisionFromCategory("earlyChildhood"));
      }
    } else if (player.age >= 6 && _random.nextDouble() < 0.25) {
      String category = _getCategoryByAge(player.age);
      Future.delayed(const Duration(milliseconds: 500), () => _triggerDecisionFromCategory(category));
    }
  }

  void _triggerSchoolExam() {
    if (_schoolQuestions == null || _schoolQuestions!['questions'] == null) return;
    List<dynamic> questions = _schoolQuestions!['questions'];
    if (questions.isEmpty) return;

    var question = questions[_random.nextInt(questions.length)];
    _showExamDialog(question);
  }

  void _showExamDialog(Map<String, dynamic> q) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Row(
          children: [
            const Icon(Icons.edit_note, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Text("${q['subject'] == 'math' ? 'Riyaziyyat' : q['subject'] == 'geography' ? 'Coğrafiya' : 'Biologiya'} İmtahanı", 
                 style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        content: Text(q['question'], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
        actions: (q['options'] as List<dynamic>).asMap().entries.map((entry) {
          int idx = entry.key;
          String optionText = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.blueAccent,
                side: const BorderSide(color: Colors.blueAccent),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              onPressed: () {
                setState(() {
                  if (idx == q['correctIndex']) {
                    SoundManager.playSuccess();
                    player.smarts = (player.smarts + 2).clamp(0, 100); // nerfed: was +5
                    player.grades = (player.grades + 5).clamp(0, 100);
                    logs.first.events.add(q['successLog']);
                  } else {
                    SoundManager.playFail();
                    player.smarts -= 2;
                    player.grades = (player.grades - 5).clamp(0, 100);
                    logs.first.events.add(q['failLog']);
                  }
                });
                Navigator.pop(context);
              },
              child: Text(optionText, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getCategoryByAge(int age) {
    if (age < 6) return "earlyChildhood";
    if (age < 13) return "childhood";
    if (age < 20) return "teenager";
    if (age < 36) return "youngAdult";
    if (age < 60) return "middleAge";
    return "senior";
  }

  void _triggerDecisionFromCategory(String category) {
    if (_allDecisions == null || _allDecisions![category] == null) return;
    List<dynamic> categoryDecisions = _allDecisions![category];
    if (categoryDecisions.isEmpty) return;

    var decisionJson = categoryDecisions[_random.nextInt(categoryDecisions.length)];
    _showDecision(decisionJson);
  }

  void _applyEffects(Player p, Map<String, dynamic> effects) {
    effects.forEach((key, value) {
      int val = (value is int) ? value : 0;
      switch (key) {
        case 'health': p.health = (p.health + val).clamp(0, 100); break;
        case 'happiness': p.happiness = (p.happiness + val).clamp(0, 100); break;
        case 'smarts': p.smarts = (p.smarts + val).clamp(0, 100); break;
        case 'looks': p.looks = (p.looks + val).clamp(0, 100); break;
        case 'money': p.money += val; break;
      }
    });
  }

  void _showDecision(Map<String, dynamic> decision) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const Icon(Icons.help_outline, color: Colors.blueAccent),
            const SizedBox(width: 10),
            Expanded(child: Text(decision['title'] ?? "Qərar", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20))),
          ],
        ),
        content: Text(decision['description'] ?? "", style: const TextStyle(fontSize: 16, height: 1.4)),
        actions: (decision['options'] as List<dynamic>).map((option) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                elevation: 0,
              ),
              onPressed: () {
                SoundManager.playClick();
                setState(() {
                  bool isRandom = option['random'] ?? false;
                  if (isRandom) {
                    if (_random.nextBool()) {
                      // Success
                      SoundManager.playSuccess();
                      _applyEffects(player, option['successEffects'] ?? {});
                      logs.first.events.add(option['successLog'] ?? "Uğurlu qərar!");
                    } else {
                      // Failure
                      SoundManager.playFail();
                      _applyEffects(player, option['effects'] ?? {});
                      logs.first.events.add(option['failLog'] ?? "Uğursuz qərar.");
                    }
                  } else {
                    _applyEffects(player, option['effects'] ?? {});
                    if (option['log'] != null) {
                      logs.first.events.add(option['log']);
                    }
                  }
                });
                Navigator.pop(context);
              },
              child: Text(option['label'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _triggerWedding(SchoolMate partner) {
    if (!mounted) return;
    final remaining = partner.weddingTotalCost - (partner.weddingTotalCost * 0.3).round();
    if (player.money < remaining) {
      setState(() {
        final msg = "${partner.name} ilə toy keçirilə bilmədi — yetəri qədər pul yox idi. Toy ləğv edildi.";
        logs.first.events.add(msg);
        partner.weddingPlanStatus = "none";
        partner.weddingScheduledAge = 0;
        partner.weddingDepositPaid = false;
      });
      _showGameNotification("Toy ləğv edildi", "${partner.name} ilə toyunuz pul çatışmazlığı səbəbilə ləğv edildi.");
      return;
    }
    setState(() {
      player.money -= remaining;
      partner.partnerStatus = PartnerStatus.married;
      partner.weddingPlanStatus = "done";
      final msg = "${partner.name} ilə toy etdiniz! Artıq evlisiniz. (${partner.weddingVenue})";
      logs.first.events.add(msg);
      player.happiness = (player.happiness + 25).clamp(0, 100);
    });
    SoundManager.playSuccess();
    _showGameNotification(
      "Toy Mübarək!",
      "${partner.name} ilə ${partner.weddingVenue}-da möhtəşəm toy keçirdiniz!\n\nXərc: $remaining AZN\nArtıq evlisiniz.",
    );
  }

  void _showGameNotification(String title, String content) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(25),
            gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.blue], begin: Alignment.topLeft, end: Alignment.bottomRight),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.school, size: 60, color: Colors.white),
              const SizedBox(height: 20),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Text(content, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 16)),
              const SizedBox(height: 25),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blueAccent, minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                onPressed: () {
                  SoundManager.playClick();
                  Navigator.pop(context);
                },
                child: const Text("Həyatım Məhv Oldu... yəni, Başlayaq!", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openActivities() { 
    SoundManager.playClick();
    Navigator.push(context, MaterialPageRoute(builder: (context) => ActivitiesScreen(player: player, onActivityPerformed: (msg) => setState(() => logs.first.events.add(msg))))); 
  }
  void _openRelationships() { 
    SoundManager.playClick();
    Navigator.push(context, MaterialPageRoute(builder: (context) => RelationshipsScreen(player: player, onAction: (msg) => setState(() => logs.first.events.add(msg))))); 
  }
  void _openOccupation() { 
    if (!player.isEnrolledInSchool && !player.isEnrolledInUniversity) return;
    SoundManager.playClick();
    Navigator.push(context, MaterialPageRoute(builder: (context) => OccupationScreen(player: player, onAction: (msg) => setState(() => logs.first.events.add(msg))))); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 8),
                itemCount: logs.length,
                itemBuilder: (context, index) => _buildYearSection(logs[index]),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _buildBottomStats(),
            const Divider(height: 1, color: Color(0xFFEEEEEE)),
            _buildNavBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          PersonAvatar(gender: player.gender, age: player.age, variant: player.imageVariant, radius: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${player.name} ${player.surname}",
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1565C0)),
                ),
                Text(
                  player.title,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF888888)),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "${player.money} AZN",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A)),
              ),
              const Text("Bank Balansı", style: TextStyle(fontSize: 10, color: Color(0xFF888888))),
            ],
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () async {
              await _autoSave();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Oyun saxlandı'),
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
            child: const Icon(Icons.save_outlined, size: 24, color: Color(0xFF1565C0)),
          ),
        ],
      ),
    );
  }

  Widget _buildYearSection(YearLog yearLog) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Yaş: ${yearLog.age}",
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1565C0)),
          ),
          const SizedBox(height: 6),
          ...yearLog.events.map((event) => Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Text(event, style: const TextStyle(fontSize: 14, height: 1.45, color: Color(0xFF333333))),
          )),
        ],
      ),
    );
  }

  Widget _buildNavBar() {
    final canWork = player.isEnrolledInSchool || player.isEnrolledInUniversity;
    final canPlay  = player.age >= 7;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(0, 6, 0, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _navItem(Icons.work_outline_rounded,             "Peşə",       canWork ? _openOccupation : null),
          _navItem(Icons.account_balance_wallet_outlined,  "Əmlak",      null),
          // ── Central Age button ──
          GestureDetector(
            onTap: ageUp,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 62,
                  height: 62,
                  decoration: const BoxDecoration(
                    color: Color(0xFF2EC95C),
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Color(0x552EC95C), blurRadius: 14, offset: Offset(0, 5))],
                  ),
                  child: const Icon(Icons.add, size: 30, color: Colors.white),
                ),
                const SizedBox(height: 4),
                const Text("Yaş", style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF2EC95C))),
              ],
            ),
          ),
          _navItem(Icons.favorite_border_rounded,          "Münasibət",  _openRelationships),
          _navItem(Icons.sports_esports_outlined,          "Fəaliyyət",  canPlay ? _openActivities : null),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, VoidCallback? onTap) {
    final active = onTap != null;
    const color = Color(0xFF1565C0);
    return Opacity(
      opacity: active ? 1.0 : 0.35,
      child: GestureDetector(
        onTap: active ? () { SoundManager.playClick(); onTap(); } : null,
        child: SizedBox(
          width: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 3),
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomStats() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Column(
        children: [
          _statRow(Icons.sentiment_satisfied_alt, "Xoşbəxtlik", player.happiness, const Color(0xFF4BBDFF)),
          _statRow(Icons.favorite,              "Sağlamlıq",  player.health,    const Color(0xFFFF6B6B)),
          _statRow(Icons.auto_awesome,          "Görünüş",    player.looks,     const Color(0xFFFFB347)),
          _statRow(Icons.psychology,            "Ağıl",       player.smarts,    const Color(0xFF7B68EE)),
        ],
      ),
    );
  }

  Widget _statRow(IconData icon, String label, int value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 6),
          SizedBox(width: 76, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF333333)))),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value / 100,
                minHeight: 11,
                backgroundColor: const Color(0xFFEEEEEE),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 32,
            child: Text("$value%", textAlign: TextAlign.right, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF555555))),
          ),
        ],
      ),
    );
  }
}
