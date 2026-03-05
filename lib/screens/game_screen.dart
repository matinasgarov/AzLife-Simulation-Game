import 'package:flutter/material.dart';
import 'dart:math';
import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/player.dart';
import '../services/sound_manager.dart';
import 'activities_screen.dart';
import 'relationships_screen.dart';
import 'occupation_screen.dart';

class YearLog {
  final int age;
  final List<String> events;

  YearLog({required this.age, required this.events});
}

class GameScreen extends StatefulWidget {
  final Player player;
  const GameScreen({super.key, required this.player});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late Player player;
  List<YearLog> logs = [];
  final Random _random = Random();
  int _earlyDecisionCountTotal = 0;
  Map<String, dynamic>? _allDecisions;
  Map<String, dynamic>? _schoolQuestions;
  Map<String, dynamic>? _universityExams;

  final List<String> _boyNames = ["Murad", "Elvin", "Nihad", "Tural", "Fuad", "Zaur", "Emil", "Oqtay", "Kənan", "Orxan"];
  final List<String> _girlNames = ["Aysel", "Leyla", "Fidan", "Günay", "Nigar", "Sevda", "Aytən", "Lamiyə", "Nərmin", "Arzu"];
  
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
    player = widget.player;
    _loadData();
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

  Future<void> _loadData() async {
    try {
      final String decisionsResponse = await rootBundle.loadString('assets/decisions.json');
      final String schoolResponse = await rootBundle.loadString('assets/school_questions.json');
      final String uniResponse = await rootBundle.loadString('assets/university_exams.json');
      setState(() {
        _allDecisions = json.decode(decisionsResponse);
        _schoolQuestions = json.decode(schoolResponse);
        _universityExams = json.decode(uniResponse);
      });
    } catch (e) {
      debugPrint("Error loading data: $e");
    }
  }

  void _initializeFamily() {
    // Birthplace logic for family wealth
    double multiplier = 1.0;
    if (player.birthCity == "Bakı") multiplier = 1.5;
    else if (player.birthCity == "Gəncə" || player.birthCity == "Sumqayıt") multiplier = 1.2;
    else multiplier = 0.8;

    var fatherJob = _jobIncomes.keys.toList()[_random.nextInt(_jobIncomes.length)];
    var motherJob = _jobIncomes.keys.toList()[_random.nextInt(_jobIncomes.length)];

    var fatherRange = _jobIncomes[fatherJob]!;
    var motherRange = _jobIncomes[motherJob]!;

    player.family.add(FamilyMember(
        name: _girlNames[_random.nextInt(_girlNames.length)], 
        surname: player.surname, 
        gender: Gender.female, 
        relation: "Ana", 
        age: 25 + _random.nextInt(10),
        job: motherJob,
        monthlyIncome: ((motherRange[0] + _random.nextInt(motherRange[1] - motherRange[0])) * multiplier).toInt(),
        generosity: _random.nextInt(101),
        religiousness: _random.nextInt(101),
        totalMoney: ((_random.nextInt(5000) + 1000) * multiplier).toInt()
    ));
    player.family.add(FamilyMember(
        name: _boyNames[_random.nextInt(_boyNames.length)], 
        surname: player.surname, 
        gender: Gender.male, 
        relation: "Ata", 
        age: 28 + _random.nextInt(10),
        job: fatherJob,
        monthlyIncome: ((fatherRange[0] + _random.nextInt(fatherRange[1] - fatherRange[0])) * multiplier).toInt(),
        generosity: _random.nextInt(101),
        religiousness: _random.nextInt(101),
        totalMoney: ((_random.nextInt(10000) + 2000) * multiplier).toInt()
    ));
  }

  void _checkFriendRequest() {
    if (player.age >= 6 && player.age <= 18 && _random.nextDouble() < 0.15) {
      bool isBoy = _random.nextBool();
      String name = isBoy ? _boyNames[_random.nextInt(_boyNames.length)] : _girlNames[_random.nextInt(_girlNames.length)];
      
      SchoolMate potentialFriend = SchoolMate(
        name: name,
        surname: "Məmmədov",
        gender: isBoy ? Gender.male : Gender.female,
        age: player.age,
        money: _random.nextInt(500),
        health: 50 + _random.nextInt(51),
        smarts: 30 + _random.nextInt(71),
        looks: 30 + _random.nextInt(71),
      );

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showFriendRequestDialog(potentialFriend);
      });
    }
  }

  void _showFriendRequestDialog(SchoolMate friend) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: const Text("Yeni Dostluq Təklifi", style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${friend.name} səninlə dost olmaq istəyir. Onun statusu:", style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 15),
            _friendStatRow("Ağıl", friend.smarts),
            _friendStatRow("Görünüş", friend.looks),
            _friendStatRow("Sağlamlıq", friend.health),
            _friendStatRow("Maddi vəziyyət", friend.money, isMoney: true),
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
                logs.first.events.add("${friend.name} ilə dost oldun.");
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
      String name = isBoy ? _boyNames[_random.nextInt(_boyNames.length)] : _girlNames[_random.nextInt(_girlNames.length)];
      player.family.add(FamilyMember(name: name, surname: player.surname, gender: isBoy ? Gender.male : Gender.female, relation: isBoy ? "Qardaş" : "Bacı", age: 0));
      logs.first.events.add("Sənin yeni bir ${isBoy ? 'qardaşın' : 'bacın'} dünyaya gəldi! Adını $name qoydular.");
    }
  }

  void ageUp() {
    SoundManager.playAgeUp();
    setState(() {
      player.age++;
      player.health = (player.health + _random.nextInt(10) - 5).clamp(0, 100);
      player.happiness = (player.happiness + _random.nextInt(10) - 5).clamp(0, 100);
      player.smarts = (player.smarts + _random.nextInt(4) - 1).clamp(0, 100);
      player.looks = (player.looks + _random.nextInt(4) - 1).clamp(0, 100);

      for (var member in player.family) {
        member.askedMoneyThisYear = false;
        member.age++;
        member.totalMoney += member.monthlyIncome * 12;
      }
      for (var friend in player.friends) {
        friend.age++;
      }

      List<String> yearEvents = [];
      
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
      _handleDecisions();
    });
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
        content: const Text("Universiteti bitirdin. Növbəti addımın nə olacaq?"),
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
    if (passed) SoundManager.playSuccess(); else SoundManager.playFail();
    
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
                    player.smarts += 5;
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
      backgroundColor: const Color(0xFFF5F5F5),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            Expanded(child: ListView.builder(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10), itemCount: logs.length, itemBuilder: (context, index) => _buildYearSection(logs[index]))),
            _buildActionButtons(),
            _buildBottomStats(),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(padding: const EdgeInsets.all(20.0), decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))]), child: Row(children: [Text(player.getEmoji(), style: const TextStyle(fontSize: 40)), const SizedBox(width: 15), Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text("${player.name} ${player.surname}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), Text("${player.title} • ${player.age} yaş", style: TextStyle(fontSize: 13, color: Colors.grey[600]))])), Text("${player.money} AZN", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green))]));
  }

  Widget _buildYearSection(YearLog yearLog) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [const SizedBox(height: 15), Text("Yaş : ${yearLog.age}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), Container(width: 100, height: 1, color: Colors.grey[300], margin: const EdgeInsets.only(top: 4, bottom: 8)), ...yearLog.events.map((event) => Padding(padding: const EdgeInsets.only(bottom: 4.0), child: Text(event, style: const TextStyle(fontSize: 13, height: 1.4, color: Colors.black87))))]);
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 15.0), 
      color: Colors.blue.withOpacity(0.05), 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
        children: [
          _actionIconButton(Icons.work_rounded, "Peşə", (player.isEnrolledInSchool || player.isEnrolledInUniversity) ? 1.0 : 0.4, _openOccupation),
          const SizedBox(width: 1), 
          _actionIconButton(Icons.account_balance_wallet_rounded, "Əmlak", 0.4, () {}), 
          const SizedBox(width: 1), 
          GestureDetector(
            onTap: ageUp, 
            child: Container(width: 70, height: 70, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Colors.blueAccent, Colors.blue]), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8, offset: Offset(0, 4))]), child: const Icon(Icons.add, size: 35, color: Colors.white))
          ), 
          const SizedBox(width: 1), 
          _actionIconButton(Icons.favorite_rounded, "Münasibətlər", 1.0, _openRelationships), 
          const SizedBox(width: 1), 
          _actionIconButton(Icons.local_play_rounded, "Fəaliyyətlər", player.age >= 7 ? 1.0 : 0.4, _openActivities)
        ]
      )
    );
  }

  Widget _actionIconButton(IconData icon, String label, double opacity, VoidCallback onTap) {
    return Expanded(
      child: Opacity(
        opacity: opacity,
        child: GestureDetector(
          onTap: onTap, 
          child: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.blue.withOpacity(0.2))), child: Icon(icon, size: 24, color: Colors.blueAccent)), 
              const SizedBox(height: 4), 
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.blueAccent))
            ]
          )
        ),
      )
    );
  }

  Widget _buildBottomStats() {
    return Container(padding: const EdgeInsets.fromLTRB(24, 15, 24, 25), decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(25))), child: Column(children: [_statProgress("Xoşbəxtlik", player.happiness, const Color(0xFF4C84FF)), _statProgress("Sağlamlıq", player.health, const Color(0xFFA58AF5)), _statProgress("Görünüş", player.looks, const Color(0xFFF5B971)), _statProgress("Ağıl", player.smarts, const Color(0xFFFCDD61))]));
  }

  Widget _statProgress(String label, int value, Color color) {
    return Padding(padding: const EdgeInsets.symmetric(vertical: 5.0), child: Row(children: [SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))), Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(8), child: LinearProgressIndicator(value: value / 100, minHeight: 10, backgroundColor: const Color(0xFFEEEEEE), valueColor: AlwaysStoppedAnimation<Color>(color)))), const SizedBox(width: 8), Text("$value%", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]));
  }
}
