import 'package:flutter/material.dart';
import 'dart:math';
import '../models/player.dart';
import 'activities_screen.dart';
import 'relationships_screen.dart';
import 'occupation_screen.dart';

class YearLog {
  final int age;
  final List<String> events;

  YearLog({required this.age, required this.events});
}

class Decision {
  final String title;
  final String description;
  final Map<String, Function(Player)> options;

  Decision({required this.title, required this.description, required this.options});
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

  final List<String> _boyNames = ["Murad", "Elvin", "Nihad", "Tural", "Fuad", "Zaur", "Emil", "Oqtay", "Kənan", "Orxan"];
  final List<String> _girlNames = ["Aysel", "Leyla", "Fidan", "Günay", "Nigar", "Sevda", "Aytən", "Lamiyə", "Nərmin", "Arzu"];

  @override
  void initState() {
    super.initState();
    player = widget.player;
    _initializeFamily();
    logs.add(YearLog(age: 0, events: [
      "Sən ${player.birthCity} qəsəbəsində anadan olmusan.",
      "Sən sağlam ${player.gender == Gender.male ? 'oğlan' : 'qız'} uşağısan.",
      "Valideynlərin çox xoşbəxtdir."
    ]));
  }

  void _initializeFamily() {
    if (_random.nextDouble() > 0.1) {
      player.family.add(FamilyMember(name: _girlNames[_random.nextInt(_girlNames.length)], surname: player.surname, gender: Gender.female, relation: "Ana", age: 25 + _random.nextInt(10)));
      player.family.add(FamilyMember(name: _boyNames[_random.nextInt(_boyNames.length)], surname: player.surname, gender: Gender.male, relation: "Ata", age: 28 + _random.nextInt(10)));
    }
  }

  void _generateSchoolMates() {
    for (int i = 0; i < 10; i++) {
      bool isBoy = _random.nextBool();
      String name = isBoy ? _boyNames[_random.nextInt(_boyNames.length)] : _girlNames[_random.nextInt(_girlNames.length)];
      player.schoolMates.add(SchoolMate(name: name, surname: "Məmmədov", gender: isBoy ? Gender.male : Gender.female, age: 6));
    }
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
    setState(() {
      player.age++;
      player.health = (player.health + _random.nextInt(10) - 5).clamp(0, 100);
      player.happiness = (player.happiness + _random.nextInt(10) - 5).clamp(0, 100);
      player.smarts = (player.smarts + _random.nextInt(4) - 1).clamp(0, 100);
      player.looks = (player.looks + _random.nextInt(4) - 1).clamp(0, 100);

      List<String> yearEvents = [];
      if (player.isEnrolledInSchool) {
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

      if (player.age == 6) {
        player.startSchool();
        _generateSchoolMates();
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
      _handleDecisions();
    });
  }

  void _handleDecisions() {
    if (player.age < 6 && _earlyDecisionCountTotal < 2) {
      if (player.age == 2 || player.age == 4) {
        _earlyDecisionCountTotal++;
        Future.delayed(const Duration(milliseconds: 500), () => _triggerEarlyChildhoodDecision());
      }
    } else if (player.age >= 6 && _random.nextDouble() < 0.2) {
      Future.delayed(const Duration(milliseconds: 500), () => _triggerRandomDecision());
    }
  }

  void _triggerEarlyChildhoodDecision() {
    List<Decision> pool = [
      Decision(title: "Pişik", description: "Yolda tənha bir pişik gördün. Quyruğunu çəkmək istəyirsən?", options: {
        "Quyruğunu çək": (p) {
          if (_random.nextBool()) {
            p.health -= 20;
            logs.first.events.add("Pişiyin quyruğunu çəkdin. O isə qəfildən sənə hücum etdi və əlini cırmaqladı! Çox ağrıyır.");
          } else {
            p.happiness += 5;
            logs.first.events.add("Pişiyin quyruğunu çəkdin. O bərk qorxub qaçdı. Sən isə buna bərkdən güldün.");
          }
        },
        "Sığalla": (p) {
          p.happiness += 10;
          logs.first.events.add("Pişiyi sığalladın, o isə sənə mırıldayıb sevgi göstərdi.");
        }
      }),
      Decision(title: "Oyuncaq", description: "Dostun sevimli oyuncağını istəyir. Nə edirsən?", options: {
        "Paylaş": (p) {
          p.happiness += 10;
          logs.first.events.add("Oyuncağını dostunla paylaşdın. Birlikdə çox əyləncəli oyun qurdunuz.");
        }, 
        "Vermə": (p) {
          p.happiness -= 5;
          logs.first.events.add("Oyuncağı vermədin. Dostun incidi və ağlamağa başladı.");
        }
      }),
      Decision(title: "Yemək", description: "Anan sənə dadı xoş olmayan tərəvəz yedirtmək istəyir.", options: {
        "Ye": (p) {
          p.health += 15;
          logs.first.events.add("Tərəvəzləri yedin. Özünü daha sağlam və güclü hiss edirsən.");
        }, 
        "Ağla": (p) {
          p.happiness -= 10;
          logs.first.events.add("Bərkdən ağladın və yeməkdən imtina etdin. Anan səndən bir az incidi.");
        }
      }),
    ];
    _showDecision(pool[_random.nextInt(pool.length)]);
  }

  void _triggerRandomDecision() {
    List<Decision> pool = [
      Decision(title: "Novruz", description: "Həyətdə böyük tonqal qalanıb! Nə edəcəksən?", options: {
        "Üstündən tullan": (p) {
          if (_random.nextBool()) {
            p.happiness += 20;
            logs.first.events.add("Tonqalın üstündən tullananda hamı necə yüksək tullandığına heyran qaldı!");
          } else {
            p.health -= 15;
            p.money -= 5;
            logs.first.events.add("Tonqalın üstündən tullanarkən pul qabın oda düşüb yandı.");
          }
        }, 
        "Şəkərbura ye": (p) {
          p.happiness += 25;
          p.health -= 10;
          logs.first.events.add("Novruz şirniyyatlarından doyunca yedin. Çox dadlı idi, amma mədən bir az ağrıyır.");
        }
      }),
      Decision(title: "Qonaqlar", description: "Evə qonaq gəlib. Valideynlərin çay gətirməyi sənə tapşırır.", options: {
        "Mükəmməl gətir": (p) {
          p.happiness += 10;
          p.smarts += 5;
          logs.first.events.add("Çayı peşəkar kimi payladın. Qonaqlar sənin tərbiyənə heyran qaldılar.");
        }, 
        "Sındır": (p) {
          p.happiness -= 15;
          p.looks -= 5;
          logs.first.events.add("Stəkanı sındırdın! Qonaqların yanında pərt oldun və valideynlərin sənə acıqlı baxdı.");
        }
      }),
    ];
    _showDecision(pool[_random.nextInt(pool.length)]);
  }

  void _showDecision(Decision decision) {
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
            Text(decision.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
          ],
        ),
        content: Text(decision.description, style: const TextStyle(fontSize: 16, height: 1.4)),
        actions: decision.options.entries.map((entry) {
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
                setState(() {
                  entry.value(player);
                });
                Navigator.pop(context);
              },
              child: Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                onPressed: () => Navigator.pop(context),
                child: const Text("Həyatım Məhv Oldu... yəni, Başlayaq!", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openActivities() { Navigator.push(context, MaterialPageRoute(builder: (context) => ActivitiesScreen(player: player, onActivityPerformed: (msg) => setState(() => logs.first.events.add(msg))))); }
  void _openRelationships() { Navigator.push(context, MaterialPageRoute(builder: (context) => RelationshipsScreen(player: player))); }
  void _openOccupation() { 
    if (!player.isEnrolledInSchool) return;
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
      color: Colors.white, 
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly, 
        children: [
          _actionIconButton(Icons.work_rounded, "Peşə", player.isEnrolledInSchool ? 1.0 : 0.4, _openOccupation), 
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
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: const Color(0xFFF8F8F8), borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.black.withOpacity(0.05))), child: Icon(icon, size: 24, color: Colors.black87)), 
              const SizedBox(height: 4), 
              Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold))
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
